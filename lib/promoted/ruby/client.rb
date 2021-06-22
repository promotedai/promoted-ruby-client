require "promoted/ruby/client/version"
require 'faraday'
require 'json'

module Promoted
  module Ruby
    module Client

      DEFAULT_DELIVERY_TIMEOUT_MILLIS = 3000
      DEFAULT_METRICS_TIMEOUT_MILLIS = 250

      class PromotedClient
  
        class Error < StandardError; end

        attr_reader :perform_checks, :only_log, :delivery_timeout_millis, :metrics_timeout_millis, :should_apply_treatment,
                    :metrics_endpoint, :delivery_endpoint
        
        def initialize (params={})
          @perform_checks = true
          if params[:perform_checks] != nil
            @perform_checks = params[:perform_checks]
          end

          @only_log                = params[:only_log] || false
          @delivery_timeout_millis = params[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
          @metrics_timeout_millis  = params[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
          @should_apply_treatment  = params[:should_apply_treatment] || false
          
          @shadow_traffic_delivery_percent = params[:shadow_traffic_delivery_percent] || 0.0
          raise ArgumentError.new("Invalid shadow_traffic_delivery_percent, must be between 0 and 1") if @shadow_traffic_delivery_percent < 0 || @shadow_traffic_delivery_percent > 1.0

          @delivery_endpoint = params[:delivery_endpoint].to_s
          raise ArgumentError.new("delivery_endpoint is required") if @delivery_endpoint.empty?

          @metrics_endpoint = params[:metrics_endpoint].to_s
          raise ArgumentError.new("metrics_endpoint is required") if @metrics_endpoint.empty?

          @sampler = Sampler.new
        end
        
        def send_request payload, endpoint=nil
          endpoint ||= BASE_URL
          response = Faraday.post(endpoint) do |req|
            req.headers['Content-Type'] = 'application/json'
            req.body                    = payload.to_json
          end
          response
        end

        def deliver payload={}
          # TODO
        end

        def perform_checks?
          @perform_checks
        end

        def log_request args={}, options={}
          endpoint = options[:endpoint]
          payload  = prepare_for_logging(args)
          send_request(payload, endpoint)
        end

        def should_send_as_shadow_traffic?
          @sampler.sample_random?(@shadow_traffic_delivery_percent)
        end

        def prepare_for_logging args
          args = Promoted::Ruby::Client::Util.translate_args(args)

          log_request_builder = LogRequestBuilder.new({
            only_log: @only_log,
            delivery_timeout_millis: @delivery_timeout_millis,
            metrics_timeout_millis: @metrics_timeout_millis,
            should_apply_treatment: @should_apply_treatment
          })

          # Note: This method expects as JSON (string keys) but internally, LogRequestBuilder
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

        # TODO: This probably just goes better in the LogRequestBuilder class.
        def pre_delivery_fillin_fields(log_request_builder)
          if log_request_builder.timing[:client_log_timestamp].nil?
            log_request_builder.client_log_timestamp = Time.now.to_i
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
require "promoted/ruby/client/log_request_builder"
require "promoted/ruby/client/sampler"
require "promoted/ruby/client/settings"
require "promoted/ruby/client/util"
require 'byebug'
require 'securerandom'