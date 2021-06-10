module Promoted
  module Ruby
    module Client
      DELIVERY_TIMEOUT_MILLIS = 30000
      DEFAULT_METRICS_TIMEOUT_MILLIS = 250

      class Options
        attr_accessor :delivery_timeout_millis, :session_id, :perform_checks,
                      :uuid, :metrics_timeout_millis, :now_millis, :should_apply_treatment,
                      :view_id, :user_id, :insertion, :client_log_timestamp,
                      :request_id, :full_insertion, :use_case, :request
                      :limit

        def initialize()
          # TODO
        end

        def set_request_params args = {}
          args = translate_args(args)
          @request                 = args[:request]
          @delivery_timeout_millis = args[:delivery_timeout_millis] || DELIVERY_TIMEOUT_MILLIS
          @session_id              = args[:session_id]
          @user_id                 = args[:user_id]
          @log_user_id             = args[:log_user_id]
          @view_id                 = args[:view_id]
          @limit                   = args[:limit].to_i
          @perform_checks          = args[:perform_checks] || false
          @only_Log                = args[:only_Log] || false
          @uuid                    = args[:uuid]
          @use_case                = args[:use_case] || 'FEED'
          @now_millis              = args[:now_millis] || Time.now.to_i
          @metrics_timeout_millis  = args[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
          @should_apply_treatment  = args[:should_apply_treatment] || false
          @full_insertion          = args[:full_insertion]
          @insertion               = args[:insertion] || []
          @client_log_timestamp    = args[:client_log_timestamp] || Time.now.to_i
          @request_id              = SecureRandom.uuid
        end

        def translate_args(args)
          args.transform_keys(&:to_s).transform_keys(&:to_underscore).transform_keys(&:to_sym)
        rescue => e
          raise 'Unable to parse args. Please pass correct arguments. Must be JSON'
        end

        def validate_request_params
          # TODO
        end

        def request
          @request
        end

        def client_log_timestamp
          @client_log_timestamp
        end

        def limit
          @limit
        end

        def view_id
          @view_id
        end

        def user_id
          return @user_id if @user_id
          @user_id = request.dig(:user_info, :user_id)
          @user_id ||= request.dig('user_info', 'user_id')
          @user_id
        end

        def session_id
          @session_id
        end

        # A list of the response Insertions.  This list should be truncated
        # based on limit.
        def insertion
          @insertion
        end

        def log_user_id
          return @log_user_id if @log_user_id
          @log_user_id   = request.dig(:user_info, :log_user_id)
          @log_user_id ||= request.dig('user_info', 'log_user_id')
          @log_user_id
        end

        # A way to turn off logging.  Defaults to true.
        def enabled?
          @enabled
        end

        # Performs extra dev checks.  Safer but slower.  Defaults to true.
        def perform_checks?
          @perform_checks
        end

        # Default values to use on DeliveryRequests.
        def default_request_values
          @default_request_values
        end

        # Required as a dependency so clients can load reduce dependency on multiple
        # uuid libraries.
        def uuid
          @uuid
        end

        # Defaults to 250ms
        def delivery_timeout_millis
          @delivery_timeout_millis
        end

        # Defaults to 3000ms
        def metrics_timeout_millis
          @metrics_timeout_millis
        end

        # For testing.  Allows for easy mocking of the clock.
        def now_millis
          @now_millis
        end

        def only_Log
          @only_Log
        end

        def full_insertion
          @full_insertion
        end

        def user_info
          {
            user_id: user_id,
            log_user_id: log_user_id
          }
        end

        def timing
          @timing = {
            client_log_timestamp: client_log_timestamp
          }
        end

        def request_id
          @request_id
        end

        def log_request_params
          {
            user_info: user_info,
            timing: timing,
            request: [request],
            insertion: compact_insertions
          }
        end

        def request_params include_insertion: true
          @request_params = {
            user_info: user_info,
            timing: timing,
            request_id: request_id,
            view_id: view_id,
            session_id: session_id,
            insertion: compact_insertions
          }
          @request_params.merge!({insertion: compact_insertions}) if include_insertion
          @request_params
        end


        def compact_insertions
          @compact_insertions = []
          insertions_to_compact = full_insertion
          if limit
            insertions_to_compact = insertions_to_compact[0..limit-1]
          end
          insertions_to_compact.each_with_index do |insertion_obj, index|
            # TODO - this does not look performant.
            insertion_obj = insertion_obj.transform_keys{ |key| key.to_s.to_underscore.to_sym }
            insertion_obj[:user_info]    = user_info
            insertion_obj[:timing]       = timing
            insertion_obj[:insertion_id] = SecureRandom.uuid # generate random UUID
            insertion_obj[:request_id]   = request_id
            insertion_obj[:position]     = index
            @compact_insertions << insertion_obj
          end
          @compact_insertions
        end

      end
    end
  end
end

class String
   # Ruby mutation methods have the expectation to return self if a mutation occurred, nil otherwise. (see http://www.ruby-doc.org/core-1.9.3/String.html#method-i-gsub-21)
   def to_underscore!
     gsub!(/(.)([A-Z])/,'\1_\2')
     downcase!
   end

   def to_underscore
     dup.tap { |s| s.to_underscore! }
   end
end
require 'securerandom'