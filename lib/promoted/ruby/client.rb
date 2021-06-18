require "promoted/ruby/client/version"
require 'faraday'
require 'json'

module Promoted
  module Ruby
    module Client
      class Error < StandardError; end
      attr_accessor :options

      def self.send_request payload, endpoint='', headers={}
        raise DeliverEndpointMissing if endpoint.blank?

        response = Faraday.post(endpoint) do |req|
          req.headers                 = req.headers.merge!(headers) if headers
          req.headers['Content-Type'] = 'application/json' if req.headers['Content-Type'].blank?
          req.body                    = payload.to_json
        end

        response.body
      end

      def self.deliver args={}, delivery_endpoint='', delivery_headers={}
        options.set_request_params(args)
        if options.perform_checks
          Promoted::Ruby::Client::Settings.check_that_log_ids_not_set(args)
        end
        pre_delivery_fillin_fields

        insertions_from_promoted = false
        if !options.onlyLog
          cohort_membership_to_log = options.new_cohort_membership_to_log
        end

        response_insertions = []
        if options.should_apply_treatment
          single_request = options.single_request
          response = send_request(single_request, delivery_endpoint, delivery_headers)
          insertions_from_promoted = true;
          response_insertions  = options.fill_details_from_response(response.insertion)
        end

        if !insertions_from_promoted
          size = options.request.dig(:paging, :size)
          response_insertions = size.present? ? options.full_insertion[0..size] : options.full_insertion
        end
        # TODO still have to implement log_request from response.
        # returning response insertions for now.
        return response_insertions
      end

      def self.log_request args={}, options={}
        endpoint = options[:endpoint]
        payload  = prepare_for_logging(args)
        send_request(payload, endpoint)
      end

      def self.prepare_for_logging args
        options.set_request_params(args)
        if options.perform_checks
          Promoted::Ruby::Client::Settings.check_that_log_ids_not_set(args)
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

    end
  end
end

# dependent /libs
require "promoted/ruby/client/options"
require "promoted/ruby/client/settings"
require 'byebug'
require 'securerandom'