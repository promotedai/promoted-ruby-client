require "promoted/ruby/client/version"
require 'faraday'
require 'json'

module Promoted
  module Ruby
    module Client

      DEFAULT_DELIVERY_TIMEOUT_MILLIS = 3000
      DEFAULT_METRICS_TIMEOUT_MILLIS = 250
      DEFAULT_DELIVERY_ENDPOINT = "http://delivery.example.com"
      DEFAULT_METRICS_ENDPOINT = "http://metrics.example.com"

      class PromotedClient
  
        class Error < StandardError; end

        attr_reader :perform_checks, :default_only_log, :delivery_timeout_millis, :metrics_timeout_millis, :should_apply_treatment_func,
                    :metrics_endpoint, :delivery_endpoint
        
        def initialize (params={})
          @perform_checks = true
          if params[:perform_checks] != nil
            @perform_checks = params[:perform_checks]
          end

          @default_only_log        = params[:default_only_log] || false
          @delivery_timeout_millis = params[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
          @metrics_timeout_millis  = params[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
          @should_apply_treatment_func  = params[:should_apply_treatment_func]
          
          @shadow_traffic_delivery_percent = params[:shadow_traffic_delivery_percent] || 0.0
          raise ArgumentError.new("Invalid shadow_traffic_delivery_percent, must be between 0 and 1") if @shadow_traffic_delivery_percent < 0 || @shadow_traffic_delivery_percent > 1.0

          @delivery_endpoint = params[:delivery_endpoint] || DEFAULT_DELIVERY_ENDPOINT
          raise ArgumentError.new("delivery_endpoint is required") if @delivery_endpoint.strip.empty?

          @metrics_endpoint = params[:metrics_endpoint] || DEFAULT_METRICS_ENDPOINT
          raise ArgumentError.new("metrics_endpoint is required") if @metrics_endpoint.strip.empty?

          @sampler = Sampler.new
        end
        
        def send_request payload, endpoint, timeout_millis, headers={}
          response = Faraday.post(endpoint) do |req|
            req.headers                 = req.headers.merge!(headers) if headers
            req.headers['Content-Type'] = req.headers['Content-Type'] || 'application/json'
            req.options.timeout         = timeout_millis / 1000
            req.body                    = payload.to_json
          end
  
          # TODO: Check response code, rescue on ParserError, etc.
          JSON.parse(response.body, :symbolize_names => true)
        end

        def deliver args, headers={}
          args = Promoted::Ruby::Client::Util.translate_args(args)

          delivery_request_builder = RequestBuilder.new
          delivery_request_builder.set_request_params(args)

          if perform_checks?
            Promoted::Ruby::Client::Settings.check_that_log_ids_not_set!(args)
          end

          pre_delivery_fillin_fields delivery_request_builder
  
          response_insertions = []
          cohort_membership_to_log = nil
          insertions_from_promoted = false

          only_log = delivery_request_builder.only_log != nil ? delivery_request_builder.only_log : @default_only_log
          if !only_log
            cohort_membership_to_log = delivery_request_builder.new_cohort_membership_to_log
          end
  
          if should_apply_treatment(cohort_membership_to_log)
            delivery_request_params = delivery_request_builder.delivery_request_params
            response = send_request(delivery_request_params, @delivery_endpoint, @delivery_timeout_millis, headers)
            insertions_from_promoted = true;
            response_insertions = delivery_request_builder.fill_details_from_response(response[:insertion])
          end
  
          request_to_log = nil
          if !insertions_from_promoted
            request_to_log = delivery_request_builder.request
            size = delivery_request_builder.request.dig(:paging, :size)
            response_insertions = size != nil ? delivery_request_builder.full_insertion[0..size] : delivery_request_builder.full_insertion
          end

          if request_to_log
            request_to_log[:request_id] = SecureRandom.uuid if not request_to_log[:request_id]
            add_missing_ids_on_insertions! request_to_log, response_insertions
          end

          log_req = nil
          # We only return a log request if there's a request or cohort to log.
          if request_to_log || cohort_membership_to_log
            log_request_builder = RequestBuilder.new
            log_request = {
              :full_insertion => response_insertions,
              :experiment => cohort_membership_to_log,
              :request => request_to_log
            }
            log_request_builder.set_request_params(log_request)

            # We can't count on these being set already since request_to_log may be nil.
            log_request_builder.platform_id = delivery_request_builder.platform_id
            log_request_builder.timing      = delivery_request_builder.timing
            log_request_builder.user_info   = delivery_request_builder.user_info
            pre_delivery_fillin_fields log_request_builder


            # On a successful delivery request, we don't log the insertions
            # or the request since they are logged on the server-side.
            log_req = log_request_builder.log_request_params(
              include_insertions: !insertions_from_promoted, 
              include_request: !insertions_from_promoted)
          end

          client_response = {
            insertion: response_insertions,
            log_request: log_req
          }
          return client_response
        end

        def add_missing_ids_on_insertions! request, insertions
          insertions.each do |insertion|
            insertion[:insertion_id] = SecureRandom.uuid if not insertion[:insertion_id]
            insertion[:session_id] = request[:session_id] if request[:session_id]
            insertion[:request_id] = request[:request_id] if request[:request_id]
          end
        end

        def perform_checks?
          @perform_checks
        end

        # Sends a log request (previously created by a call to prepare_for_logging) to the metrics endpoint.
        def send_log_request log_request_params, headers={}
          send_request(log_request_params, @metrics_endpoint, @metrics_timeout_millis, headers)
        end

        def should_send_as_shadow_traffic?
          @sampler.sample_random?(@shadow_traffic_delivery_percent)
        end

        def prepare_for_logging args
          args = Promoted::Ruby::Client::Util.translate_args(args)

          log_request_builder = RequestBuilder.new

          # Note: This method expects as JSON (string keys) but internally, RequestBuilder
          # transforms and works with symbol keys.
          log_request_builder.set_request_params(args)
          if perform_checks?
            Promoted::Ruby::Client::Settings.check_that_log_ids_not_set!(args)

            if @shadow_traffic_delivery_percent > 0 && args[:insertion_page_type] != Promoted::Ruby::Client::INSERTION_PAGING_TYPE['UNPAGED'] then
              raise ShadowTrafficInsertionPageType
            end
          end
          
          pre_delivery_fillin_fields log_request_builder

          if should_send_as_shadow_traffic?
            # TODO: Call deliver in the background to deliver shadow traffic
          end

          log_request_builder.log_request_params
        end

        def should_apply_treatment(cohort_membership)
          if @should_apply_treatment_func != nil
            @should_apply_treatment_func
          else
            return true if !cohort_membership
            return true if !cohort_membership[:arm]
            return cohort_membership[:arm] != Promoted::Ruby::Client::COHORT_ARM['CONTROL']
          end
        end
        
        # TODO: This probably just goes better in the RequestBuilder class.
        def pre_delivery_fillin_fields(log_request_builder)
          if log_request_builder.timing[:client_log_timestamp].nil?
            log_request_builder.timing[:client_log_timestamp] = Time.now.to_i
          end
        end

        # A common compact method implementation.
        def self.copy_and_remove_properties
          Proc.new do |insertion|
            insertion = Hash[insertion]
            insertion.delete(:properties)
            insertion
          end
        end
      end
    end
  end
end

# dependent /libs
require "promoted/ruby/client/request_builder"
require "promoted/ruby/client/sampler"
require "promoted/ruby/client/settings"
require "promoted/ruby/client/util"
require 'byebug'
require 'securerandom'