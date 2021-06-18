module Promoted
  module Ruby
    module Client
      DEFAULT_DELIVERY_TIMEOUT_MILLIS = 30000
      DEFAULT_METRICS_TIMEOUT_MILLIS = 250

      class Options
        attr_accessor :delivery_timeout_millis, :session_id, :perform_checks,
                      :uuid, :metrics_timeout_millis, :now_millis, :should_apply_treatment,
                      :view_id, :user_id, :insertion, :client_log_timestamp,
                      :request_id, :full_insertion, :use_case, :request, :compact_func,
                      :to_compact_delivery_insertion

        def initialize;end

        def set_request_params args = {}
          args                     = translate_args(args)
          @request                 = args[:request] || {}
          @session_id              = request[:session_id]
          @user_id                 = request[:user_id]
          @log_user_id             = request[:log_user_id]
          @view_id                 = request[:view_id]
          @only_log                = request[:only_log] || false
          @use_case                = Promoted::Ruby::Client::USE_CASES[request[:use_case]] || 'FEED'
          @perform_checks          = args[:perform_checks] || false
          @uuid                    = args[:uuid]
          @now_millis              = args[:now_millis] || Time.now.to_i
          @delivery_timeout_millis = args[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
          @metrics_timeout_millis  = args[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
          @should_apply_treatment  = args[:should_apply_treatment] || false
          @full_insertion          = args[:full_insertion]
          @client_log_timestamp    = args[:client_log_timestamp] || Time.now.to_i
          @request_id              = SecureRandom.uuid
          @compact_func            = args[:compact_func] # A user defined function to shrink the Insertions.
        end

        def translate_args(args)
          args.transform_keys(&:to_sym)
        rescue => e
          raise 'Unable to parse args. Please pass correct arguments. Must be JSON'
        end

        def validate_request_params
          # TODO
        end

        def request
          @request
        end

        def compact_func
          @compact_func
        end

        def client_log_timestamp
          @client_log_timestamp
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

        # A list of the response Insertions.  This client expects lists to be truncated
        # already to request.paging.size.  If not truncated, this client will truncate
        # the list.
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

        def single_request
          {
            request: Hash[request].merge!(insertion: compact_insertions)
          }
        end

        def compact_insertions
          @insertion            = [] # insertion should be set according to the compact insertion
          paging                = request[:paging] || {}
          size                  = paging[:size] ? paging[:size].to_i : 0
          offset                = paging[:offset] ? paging[:offset].to_i : 0
          insertions_to_compact = full_insertion[offset..size-1]

          insertions_to_compact.each_with_index do |insertion_obj, index|
            insertion_obj                = Hash[insertion_obj]
            insertion_obj[:user_info]    = user_info
            insertion_obj[:timing]       = timing
            insertion_obj[:insertion_id] = SecureRandom.uuid # generate random UUID
            insertion_obj[:request_id]   = request_id
            insertion_obj[:position]     = offset + index
            insertion_obj                = @compact_func.call(insertion_obj) if @compact_func
            @insertion << insertion_obj.clean!
          end
          @insertion
        end

        def new_cohort_membership_to_log
          return nil unless request[:experiment]
          cohort_membership = Hash[request[:experiment]]
          if !cohort_membership[:platform_Id] && request[:platform_Id]
            cohort_membership[:platformId] = request[:platformId];
          end
          if !cohort_membership[:user_info] && request[:user_info]
            cohort_membership[:user_info] = request[:user_info]
          end
          if !cohort_membership[:timing] && request[:timing]
            cohort_membership[:timing] = request[:timing]
          end
          return cohort_membership
        end

        # Fills in response_insertion details using full_insertion.  It un-compacts the response.
        def fill_details_from_response response_insertion
          response_insertion
        end

        def add_missing_request_id request
          request[:request_id] = uuid unless request[:request_id]
          request
        end

        def add_missing_ids_on_insertions request, insertions=[]
          insertions.each do |insertion|
            insertion[:insertion_id] = SecureRandom.uuid if !insertion[:insertion_id]
            insertion[:session_id]   = request[:session_id] if request[:session_id]
            insertion[:view_id]      = request[:view_id] if request[:view_id]
            insertion[:request_id]   = request[:request_id]
          end
          insertions
        end

      end
    end
  end
end

require 'securerandom'
require "promoted/ruby/client/defaults"
require "promoted/ruby/client/extensions"
