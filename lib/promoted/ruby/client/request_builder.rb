module Promoted
  module Ruby
    module Client
      class RequestBuilder
        attr_reader   :session_id, :only_log, :experiment, :client_info,
                      :view_id, :insertion, :to_compact_delivery_insertion_func,
                      :request_id, :full_insertion, :use_case, :request, :to_compact_metrics_insertion_func

        attr_accessor :timing, :user_info, :platform_id

        def initialize;end

        # Populates request parameters from the given arguments, presumed to be a hash of symbols.
        def set_request_params args = {}
          @request                 = args[:request] || {}
          @experiment              = args[:experiment]
          @only_log                = args[:only_log]
          @session_id              = request[:session_id]
          @platform_id             = request[:platform_id]
          @client_info             = request[:client_info] || {}
          @view_id                 = request[:view_id]
          @use_case                = Promoted::Ruby::Client::USE_CASES[request[:use_case]] || Promoted::Ruby::Client::USE_CASES['UNKNOWN_USE_CASE']
          @full_insertion          = args[:full_insertion]
          @request_id              = SecureRandom.uuid
          @user_info               = request[:user_info] || { :user_id => nil, :log_user_id => nil}
          @timing                  = request[:timing] || { :client_log_timestamp => Time.now.to_i }
          @to_compact_metrics_insertion_func       = args[:to_compact_metrics_insertion_func]
          @to_compact_delivery_insertion_func      = args[:to_compact_delivery_insertion_func]
        end

        # Only used in delivery
        def new_cohort_membership_to_log
          return nil unless @experiment
          if !@experiment[:platform_id] && @platform_id
            @experiment[:platform_id] = @platform_id
          end
          if !@experiment[:user_info] && @user_info
            @experiment[:user_info] = @user_info
          end
          if !@experiment[:timing] && @timing
            @experiment[:timing] = @timing
          end
          return @experiment
        end

        # Only used in delivery
        def delivery_request_params(should_compact: true)
          params = {
            user_info: user_info,
            timing: timing,
            cohort_membership: @experiment,
            client_info: @client_info.merge({ :client_type => Promoted::Ruby::Client::CLIENT_TYPE['PLATFORM_SERVER'] })
          }
          params[:request] = request
          params[:insertion] = should_compact ? compact_delivery_insertions : full_insertion

          params.clean!
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

        def to_compact_metrics_insertion_func
          @to_compact_metrics_insertion_func
        end

        def to_compact_delivery_insertion_func
          @to_compact_delivery_insertion_func
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

        def log_request_params(include_insertions: true, include_request: true)
          params = {
            user_info: user_info,
            timing: timing,
            cohort_membership: @experiment,
            client_info: @client_info
          }
          params[:request] = [request] if include_request
          params[:insertion] = compact_metrics_insertions if include_insertions
          
          params.clean!
        end

        def compact_delivery_insertions
          if !@to_compact_delivery_insertion_func
            full_insertion
          else
            full_insertion.map {|insertion| @to_compact_delivery_insertion_func.call(insertion) }
          end
        end

        # TODO: This looks overly complicated.
        def compact_metrics_insertions
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
