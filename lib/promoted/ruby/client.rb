require "promoted/ruby/client/version"

require 'faraday'
require 'json'
module Promoted
  module Ruby
    module Client
      class Error < StandardError; end
      attr_accessor :options
      BASE_URL          = "http://wh12.lvh.me:3000"
      DELIVERY_ENDPOINT = "#{BASE_URL}/deliver"
      LOGGING_ENDPOINT  =  "#{BASE_URL}/log_request"

      def self.send_request payload, endpoint=nil
        endpoint ||= BASE_URL
        response = Faraday.post(endpoint) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body                    = payload.to_json
        end
        response
      end

      def deliver payload={}
      end

      def self.log_request args={}, options={}
        base_url = options[:base_url]
        payload = prepare_for_logging(args)
        send_request(payload, base_url)
      end

      def self.prepare_for_logging args
        options.set_request_params(args)
        if options.perform_checks
          Settings.check_that_log_ids_not_set(options)
          pre_delivery_fillin_fields
        end
        options.log_request_params
      end

      def self.pre_delivery_fillin_fields
        if !options.timing[:client_log_timestamp].present?
          options.client_log_timestamp = Time.now.to_i
        end
      end

      def self.options
        @options ||= Options.new
      end

      def self.promoted_client_impl  params={}
        #dummy implementation
        #TODO will implement it in details
        perform_checks          = params[:perform_checks] || true
        only_Log                = params[:only_Log] || false
        uuid                    = params[:uuid]
        now_millis              = params[:now_millis] || Time.now.to_i
        delivery_timeout_millis = params[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
        metrics_timeout_millis  = params[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
        should_apply_treatment  = params[:should_apply_treatment] || false
      end
    end
  end
end

#dependent /libs
require "promoted/ruby/client/options"
require 'byebug'
require 'securerandom'