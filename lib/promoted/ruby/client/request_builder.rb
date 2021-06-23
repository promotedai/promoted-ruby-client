module Promoted
  module Ruby
    module Client
      class RequestBuilder
        attr_reader   :session_id, :user_info,
                      :view_id, :insertion, :to_compact_delivery_insertion_func,
                      :request_id, :full_insertion, :use_case, :request, :to_compact_metrics_insertion_func

        def initialize params={}
          @only_log                = params[:only_log] || false
        end

        # Populates request parameters from the given arguments, presumed to be a hash of symbols.
        def set_request_params args = {}
          @request                 = args[:request] || {}
          @session_id              = request[:session_id]
          @platform_id             = request[:platform_id]
          @cohort_membership       = request[:cohort_membership]
          @view_id                 = request[:view_id]
          @use_case                = Promoted::Ruby::Client::USE_CASES[request[:use_case]] || 'UNKNOWN_USE_CASE'
          @full_insertion          = args[:full_insertion]
          @request_id              = SecureRandom.uuid
          
          if request[:user_info] == nil
            @user_info ={
              user_id: nil,
              log_user_id: nil
            }
          else
            @user_info = request[:user_info]
          end

          if request[:timing] != nil
            @timing = request[:timing]
          else
            client_log_timestamp    = args[:client_log_timestamp] || Time.now.to_i
            @timing = {
              :client_log_timestamp => client_log_timestamp
            }
          end

          @to_compact_metrics_insertion_func       = args[:to_compact_metrics_insertion_func]
          @to_compact_delivery_insertion_func      = args[:to_compact_delivery_insertion_func]
        end

        # Only used in delivery
        def new_cohort_membership_to_log
          return nil unless request[:experiment]
          cohort_membership = Hash[request[:experiment]]
          if !cohort_membership[:platform_id] && request[:platform_id]
            cohort_membership[:platform_id] = request[:platform_id];
          end
          if !cohort_membership[:user_info] && request[:user_info]
            cohort_membership[:user_info] = request[:user_info]
          end
          if !cohort_membership[:timing] && request[:timing]
            cohort_membership[:timing] = request[:timing]
          end
          return cohort_membership
        end

        # Only used in delivery
        def delivery_request_params
          {
            request: Hash[request].merge!(insertion: compact_insertions)
          }
        end

        # Only used in delivery
        # Maps the response insertions to the full insertions and re-insert the properties bag
        # to the responses.
        def fill_details_from_response response_insertions
          props = @full_insertion.each_with_object({}) do |insertion, hash|
            hash[insertion[:content_id]] = insertion[:properties]
          end

          filled_in_copy = []
          response_insertions.each do |resp_insertion|
            copied_insertion = resp_insertion.clone
            if copied_insertion.has_key?(:content_id) && props.has_key?(copied_insertion[:content_id])
              copied_insertion[:properties] = props[resp_insertion[:content_id]]
            end
            filled_in_copy << copied_insertion
          end

          filled_in_copy
        end

        def validate_request_params
          # TODO
        end

        def request
          @request
        end

        def to_compact_metrics_insertion_func
          @to_compact_metrics_insertion_func
        end

        def to_compact_delivery_insertion_func
          @to_compact_delivery_insertion_func
        end

        def client_log_timestamp
          @client_log_timestamp
        end

        def view_id
          @view_id
        end

        def platform_id
          @platform_id
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

        # A way to turn off logging.  Defaults to true.
        def enabled?
          @enabled
        end

        # Default values to use on DeliveryRequests.
        def default_request_values
          @default_request_values
        end

        def only_log
          @only_log
        end

        def full_insertion
          @full_insertion
        end

        def user_info
          @user_info
        end

        def timing
          @timing
        end

        def client_log_timestamp
          @timing[:client_log_timestamp]
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
            # TODO: Toogle with the delivery func
            insertion_obj                = @to_compact_metrics_insertion_func.call(insertion_obj) if @to_compact_metrics_insertion_func
            @insertion << insertion_obj.clean!
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
