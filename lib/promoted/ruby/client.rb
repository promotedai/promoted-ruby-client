require "concurrent-ruby"
require "promoted/ruby/client/faraday_http_client"
require "promoted/ruby/client/version"

module Promoted
  module Ruby
    module Client

      DEFAULT_DELIVERY_TIMEOUT_MILLIS = 250
      DEFAULT_METRICS_TIMEOUT_MILLIS = 3000
      DEFAULT_MAX_REQUEST_INSERTIONS = 1000
      DEFAULT_DELIVERY_ENDPOINT = "http://delivery.example.com"
      DEFAULT_METRICS_ENDPOINT = "http://metrics.example.com"

      ##
      # Client for working with Promoted's Metrics and Delivery APIs.
      # See {Github}[https://github.com/promotedai/promoted-ruby-client] for more info.
      class PromotedClient
  
        class Error < StandardError; end

        attr_reader :perform_checks, :default_only_log, :delivery_timeout_millis, :metrics_timeout_millis, :should_apply_treatment_func,
                    :default_request_headers, :http_client, :logger, :shadow_traffic_delivery_percent, :async_shadow_traffic,
                    :send_shadow_traffic_for_control, :max_request_insertions
                    
        attr_accessor :request_logging_on, :enabled
        
        ##
        # Whether or not the client is currently enabled for execution.
        def enabled?
          @enabled
        end

        ##
        # Create and configure a new Promoted client.
        def initialize(params={})
          @perform_checks = true
          if params[:perform_checks] != nil
            @perform_checks = params[:perform_checks]
          end

          @logger               = params[:logger] # Example:  Logger.new(STDERR, :progname => "promotedai")
          @request_logging_on   = params[:request_logging_on] || false

          @default_request_headers = params[:default_request_headers] || {}
          @metrics_api_key = params[:metrics_api_key] || ''
          @delivery_api_key = params[:delivery_api_key] || ''

          @default_only_log        = params[:default_only_log] || false
          @should_apply_treatment_func  = params[:should_apply_treatment_func]
          
          @shadow_traffic_delivery_percent = params[:shadow_traffic_delivery_percent] || 0.0
          raise ArgumentError.new("Invalid shadow_traffic_delivery_percent, must be between 0 and 1") if @shadow_traffic_delivery_percent < 0 || @shadow_traffic_delivery_percent > 1.0

          @sampler = Sampler.new
          @pager   = Pager.new
          @retrieval_insertion_offset = params[:retrieval_insertion_offset] || 0

          # HTTP Client creation
          @delivery_endpoint = params[:delivery_endpoint] || DEFAULT_DELIVERY_ENDPOINT
          raise ArgumentError.new("delivery_endpoint is required") if @delivery_endpoint.strip.empty?

          @metrics_endpoint = params[:metrics_endpoint] || DEFAULT_METRICS_ENDPOINT
          raise ArgumentError.new("metrics_endpoint is required") if @metrics_endpoint.strip.empty?

          @delivery_timeout_millis = params[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
          @metrics_timeout_millis  = params[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS

          @http_client = FaradayHTTPClient.new(@logger)
          @validator = Promoted::Ruby::Client::Validator.new

          @async_shadow_traffic = true
          if params[:async_shadow_traffic] != nil
            @async_shadow_traffic = params[:async_shadow_traffic] || false
          end

          @send_shadow_traffic_for_control = true
          if params[:send_shadow_traffic_for_control] != nil
            @send_shadow_traffic_for_control = params[:send_shadow_traffic_for_control] || false
          end

          @max_request_insertions = params[:max_request_insertions] || DEFAULT_MAX_REQUEST_INSERTIONS

          @pool = nil
          if @async_shadow_traffic
            # Thread pool to process delivery of shadow traffic. Will silently drop excess requests beyond the queue
            # size, and silently eat errors on the background threads.
            @pool = Concurrent::ThreadPoolExecutor.new(
              min_threads: 0,
              max_threads: 10,
              max_queue: 100,
              fallback_policy: :discard
            )
          end

          @enabled = true
          if params[:enabled] != nil
            @enabled = params[:enabled] || false
          end

          if params[:warmup]
            do_warmup
          end
        end
        
        ##
        # Politely shut down a Promoted client.
        def close
          if @pool
            @pool.shutdown
            @pool.wait_for_termination
          end
        end

        ##
        # Make a delivery request. If @perform_checks is set, input validation will occur and possibly raise errors.
        def deliver args, headers={}
          args = Promoted::Ruby::Client::Util.translate_hash(args)

          # Respect the enabled state
          if !@enabled
            return {
              insertion: @pager.apply_paging(args[:request][:insertion], @retrieval_insertion_offset, args[:request][:paging])
              # No log request returned when disabled
            }
          end
          
          delivery_request_builder = RequestBuilder.new
          delivery_request_builder.set_request_params(args)

          only_log = delivery_request_builder.only_log != nil ? delivery_request_builder.only_log : @default_only_log

          # Gets modified depending on the call.
          should_send_shadow_traffic = @shadow_traffic_delivery_percent > 0
          # perform_checks raises errors.
          if @perform_checks
            perform_common_checks!(args)
          end

          delivery_request_builder.ensure_client_timestamp
  
          response_insertions = []
          cohort_membership_to_log = nil
          insertions_from_delivery = false

          deliver_err = false

          # Trim any request insertions over the maximum allowed.
          if delivery_request_builder.insertion.length > @max_request_insertions then
            @logger.warn("Exceeded max request insertions, trimming") if @logger
            delivery_request_builder.insertion = delivery_request_builder.insertion[0, @max_request_insertions]
          end

          begin
            @pager.validate_paging(delivery_request_builder.insertion, @retrieval_insertion_offset, delivery_request_builder.request[:paging])
          rescue InvalidPagingError => err
            # Invalid input, log and do SDK-side delivery.
            @logger.warn(err) if @logger
            return {
              insertion: err.default_insertions_page
              # No log request returned when no response insertions due to invalid paging
            }
          end

          if !only_log
            cohort_membership_to_log = delivery_request_builder.new_cohort_membership_to_log

            if should_apply_treatment(cohort_membership_to_log)
              # Call Delivery API to get insertions to use
              delivery_request_params = delivery_request_builder.delivery_request_params  
              # Don't send shadow traffic if we've already tried normal traffic.
              should_send_shadow_traffic = false
              begin
                response = send_request(delivery_request_params, @delivery_endpoint, @delivery_timeout_millis, @delivery_api_key, headers)
                @validator.validate_response!(response)
                raise ValidationError.new("Response shoul be a Hash") if !response.is_a?(Hash)
                response_insertions = response && response[:insertion] || []
                insertions_from_delivery = (response != nil && !deliver_err);
              rescue  StandardError => err
                # Currently we don't propagate errors to the SDK caller, but rather default to returning
                # the request insertions.
                deliver_err = true
                @logger.error("Error calling delivery: " + err.message) if @logger
              end
            else
              should_send_shadow_traffic &&= @send_shadow_traffic_for_control
            end
          end

          should_send_shadow_traffic &&= should_send_as_shadow_traffic?
          if should_send_shadow_traffic then
              # Call Delivery API to send shadow traffic. This will create the request params with traffic type set.
              deliver_shadow_traffic args, headers
          end

          if !insertions_from_delivery then
            response_insertions = build_sdk_response_insertions(delivery_request_builder)
          end

          log_req = nil
          exec_server = (insertions_from_delivery ? Promoted::Ruby::Client::EXECUTION_SERVER['API'] : Promoted::Ruby::Client::EXECUTION_SERVER['SDK'])

          # We only return a log request if there's a request or cohort to log.
          if !insertions_from_delivery || cohort_membership_to_log
            log_request_builder = LogRequestBuilder.new
            # TODO - make this more efficient.
            log_request_builder.request = delivery_request_builder.delivery_request_params
            log_request_builder.response_insertions = response_insertions
            log_request_builder.experiment = cohort_membership_to_log

            # On a successful delivery request, we don't log the insertions
            # or the request since they are logged on the server-side.
            log_req = log_request_builder.log_request(
              include_delivery_log: !insertions_from_delivery, 
              exec_server: exec_server)
          end

          client_response = {
            insertion: response_insertions,
            log_request: log_req,
            execution_server: exec_server,
            client_request_id: delivery_request_builder.client_request_id
          }
          return client_response
        end

        ##
        # Sends a log request to the metrics endpoint.
        def send_log_request log_request_params, headers={}
          begin
            send_request(log_request_params, @metrics_endpoint, @metrics_timeout_millis, @metrics_api_key, headers)
          rescue  StandardError => err
            # Currently we don't propagate errors to the SDK caller.
            @logger.error("Error from metrics: " + err.message) if @logger
          end
        end

        private

        ##
        # Creates response insertions for SDK-side delivery, when we don't get response insertions from Delivery API.
        def build_sdk_response_insertions delivery_request_builder
          # TODO - remove INSERTION_PAGING_TYPE
          response_insertions = @pager.apply_paging(delivery_request_builder.insertion, @retrieval_insertion_offset, delivery_request_builder.request[:paging])
          delivery_request_builder.add_missing_insertion_ids! response_insertions
          return response_insertions
        end
        
        def do_warmup
          if !@delivery_endpoint
            # Warmup only supported when delivery is enabled.
            return
          end

          warmup_url = @delivery_endpoint.reverse.sub("/deliver".reverse, "/healthz".reverse).reverse
          @logger.info("Warming up at #{warmup_url}") if @logger
          1.upto(20) do
            resp = @http_client.get(warmup_url)
            if resp != "ok"
              @logger.warn("Got a failure warming up") if @logger
            end
          end
        end

        def send_request payload, endpoint, timeout_millis, api_key, headers={}, send_async=false
          resp = nil

          headers["x-api-key"] = api_key
          use_headers = @default_request_headers.merge headers
          
          if @request_logging_on && @logger
            @logger.info("promotedai") {
              "Sending #{payload.to_json} to #{endpoint}"
            }
          end

          if send_async && @pool
            @pool.post do
              start_time = Time.now
              begin
                resp = @http_client.send(endpoint, timeout_millis, payload, use_headers)
              rescue Faraday::Error => err
                @logger.warn("Async send_request failed with #{err}") if @logger
                return
              end

              ellapsed_time = Time.now - start_time
              @logger.debug("Async send_request completed in #{ellapsed_time.to_f * 1000} ms") if @logger
            end
          else
            start_time = Time.now
            begin
              resp = @http_client.send(endpoint, timeout_millis, payload, use_headers)
            rescue Faraday::Error => err
              @logger.warn("Sync send_request failed with #{err}") if @logger
              raise EndpointError.new(err)
            end

            ellapsed_time = Time.now - start_time
            @logger.debug("Sync send_request completed in #{ellapsed_time.to_f * 1000} ms") if @logger
          end

          return resp
        end

        def should_send_as_shadow_traffic?
          @sampler.sample_random?(@shadow_traffic_delivery_percent)
        end

        # Delivers shadow traffic from the given metrics args.
        # Assumes that the args have already been normalized since this
        # method should only be called from inside deliver.
        def deliver_shadow_traffic args, headers
          delivery_request_builder = RequestBuilder.new
          delivery_request_builder.set_request_params args

          delivery_request_params = delivery_request_builder.delivery_request_params
          delivery_request_params[:client_info][:traffic_type] = Promoted::Ruby::Client::TRAFFIC_TYPE['SHADOW']

          begin
            # TODO - maybe add here too?
            @pager.validate_paging(delivery_request_builder.insertion, @retrieval_insertion_offset, delivery_request_builder.request[:paging])
          rescue InvalidPagingError => err
            # Invalid input, log and skip.
            @logger.warn("Shadow traffic call failed with invalid paging #{err}") if @logger
            return
          end

          # Call Delivery API and log/ignore errors.
          start_time = Time.now
          response = nil
          begin
            response = send_request(delivery_request_params, @delivery_endpoint, @delivery_timeout_millis, @delivery_api_key, headers, @async_shadow_traffic)
            if response != nil
              @validator.validate_response!(response)
            end
          rescue StandardError => err
            @logger.warn("Shadow traffic call failed with #{err}") if @logger
            return
          end
          
          if !@async_shadow_traffic
            ellapsed_time = Time.now - start_time
            insertions = response && response[:insertion] || []
            @logger.info("Shadow traffic call completed in #{ellapsed_time.to_f * 1000} ms with #{insertions.length} insertions") if @logger
          end
        end

        def perform_common_checks!(req)
          begin
            @validator.check_that_log_ids_not_set!(req)
            @validator.validate_metrics_request!(req)
            @validator.check_that_content_ids_are_set!(req)
          rescue StandardError => err
            @logger.error(err) if @logger
            raise
          end
        end

        def should_apply_treatment(cohort_membership)
          if @should_apply_treatment_func != nil
            @should_apply_treatment_func.call(cohort_membership)
          else
            return true if !cohort_membership
            return true if !cohort_membership[:arm]
            return cohort_membership[:arm] != Promoted::Ruby::Client::COHORT_ARM['CONTROL']
          end
        end        
      end
    end
  end
end

# dependent /libs
require "promoted/ruby/client/log_request_builder"
require "promoted/ruby/client/request_builder"
require "promoted/ruby/client/pager"
require "promoted/ruby/client/sampler"
require "promoted/ruby/client/util"
require "promoted/ruby/client/validator"
require 'securerandom'
require 'time'
