module Promoted
  module Ruby
    module Client
      class LogRequestBuilder
        attr_reader :delivery_timeout_millis, :session_id,
                      :metrics_timeout_millis, :should_apply_treatment,
                      :view_id, :user_id, :insertion, :client_log_timestamp,
                      :request_id, :full_insertion, :use_case, :request, :to_compact_metrics_insertion

        def initialize params={}
          @only_log                = params[:only_log] || false
          @delivery_timeout_millis = params[:delivery_timeout_millis] || DEFAULT_DELIVERY_TIMEOUT_MILLIS
          @metrics_timeout_millis  = params[:metrics_timeout_millis] || DEFAULT_METRICS_TIMEOUT_MILLIS
          @should_apply_treatment  = params[:should_apply_treatment] || false        
        end

        # Populates request parameters from the given arguments, presumed to be a hash of symbols.
        def set_request_params args = {}
          @request                 = args[:request] || {}
          @session_id              = request[:session_id]
          @user_id                 = request[:user_id]
          @log_user_id             = request[:log_user_id]
          @view_id                 = request[:view_id]
          @use_case                = Promoted::Ruby::Client::USE_CASES[request[:use_case]] || 'UNKNOWN_USE_CASE'
          @full_insertion          = args[:full_insertion]
          @client_log_timestamp    = args[:client_log_timestamp] || Time.now.to_i
          @request_id              = SecureRandom.uuid
          @to_compact_metrics_insertion            = args[:to_compact_metrics_insertion]
        end

        def validate_request_params
          # TODO
        end

        def request
          @request
        end

        def to_compact_metrics_insertion
          @to_compact_metrics_insertion
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

        # Default values to use on DeliveryRequests.
        def default_request_values
          @default_request_values
        end

        # Defaults to 250ms
        def delivery_timeout_millis
          @delivery_timeout_millis
        end

        # Defaults to 3000ms
        def metrics_timeout_millis
          @metrics_timeout_millis
        end

        def only_log
          @only_log
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
          @insertion            = [] # insertion should be set according to the compact insertion
          paging                = request[:paging] || {}
          size                  = paging[:size] ? paging[:size].to_i : 0
          if size <= 0
            size = full_insertion.length()
          end
          offset                = paging[:offset] ? paging[:offset].to_i : 0

          full_insertion.each_with_index do |insertion_obj, index|
            # TODO - this does not look performant.
            break if @insertion.length() >= size

            insertion_obj                = insertion_obj.transform_keys{ |key| key.to_s.to_underscore.to_sym }
            insertion_obj                = Hash[insertion_obj]
            insertion_obj[:user_info]    = user_info
            insertion_obj[:timing]       = timing
            insertion_obj[:insertion_id] = SecureRandom.uuid # generate random UUID
            insertion_obj[:request_id]   = request_id
            insertion_obj[:position]     = offset + index
            insertion_obj                = @to_compact_metrics_insertion.call(insertion_obj) if @to_compact_metrics_insertion
            @insertion << insertion_obj
          end
          @insertion
        end

      end
    end
  end
end

require 'securerandom'
require "promoted/ruby/client/constants"
require "promoted/ruby/client/extensions"
