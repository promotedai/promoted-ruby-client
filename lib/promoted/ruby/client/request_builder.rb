module Promoted
  module Ruby
    module Client
      class RequestBuilder
        attr_reader   :session_id, :only_log, :experiment, :client_info,
                      :view_id, :insertion, :to_compact_delivery_insertion_func,
                      :request_id, :full_insertion, :use_case, :request, :to_compact_metrics_insertion_func

        attr_accessor :timing, :user_info, :platform_id

        def initialize args = {}
          if args[:id_generator]
            @id_generator = args[:id_generator]
          else
            @id_generator = IdGenerator.new
          end
        end

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
          @user_info               = request[:user_info] || { :user_id => nil, :log_user_id => nil}
          @timing                  = request[:timing] || { :client_log_timestamp => Time.now.to_i }
          @to_compact_metrics_insertion_func       = args[:to_compact_metrics_insertion_func]
          @to_compact_delivery_insertion_func      = args[:to_compact_delivery_insertion_func]

          # If the user didn't create a client request id, we do it for them.
          request[:client_request_id] = request[:client_request_id] || @id_generator.newID
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
            client_info: @client_info.merge({ :client_type => Promoted::Ruby::Client::CLIENT_TYPE['PLATFORM_SERVER'] }),
            platform_id: @platform_id,
            view_id: @view_id,
            session_id: @session_id,
            use_case: @use_case,
            search_query: request[:search_query],
            properties: request[:properties],
            paging: request[:paging],
            client_request_id: request[:client_request_id]
          }
          params[:insertion] = should_compact ? compact_delivery_insertions : full_insertion

          params.clean!
        end

        # Only used in delivery
        # Maps the response insertions to the full insertions and re-insert the properties bag
        # to the responses.
        def fill_details_from_response response_insertions
          if !response_insertions then
            response_insertions = full_insertion
          end

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

        def log_request_params(include_insertions: true, include_request: true)
          params = {
            user_info: user_info,
            timing: timing,
            client_info: @client_info
          }

          if @experiment
            params[:cohort_membership] = [@experiment]
          end

          # Log request allows for multiple requests but here we only send one.
          if include_request
            request[:request_id] = request[:request_id] || @id_generator.newID
            params[:request] = [request]
          end

          if include_insertions
            params[:insertion] = compact_metrics_insertions if include_insertions
            add_missing_ids_on_insertions! request, params[:insertion]
          end
          
          params.clean!
        end

        def compact_delivery_insertions
          if !@to_compact_delivery_insertion_func
            full_insertion
          else
            full_insertion.map {|insertion| @to_compact_delivery_insertion_func.call(insertion) }
          end
        end

        def ensure_client_timestamp
          if timing[:client_log_timestamp].nil?
            timing[:client_log_timestamp] = Time.now.to_i
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
            insertion_obj[:insertion_id] = @id_generator.newID
            insertion_obj[:request_id]   = request_id
            insertion_obj[:position]     = offset + index
            insertion_obj                = @to_compact_metrics_insertion_func.call(insertion_obj) if @to_compact_metrics_insertion_func
            @insertion << insertion_obj.clean!
          end
          @insertion
        end

        private

        def add_missing_ids_on_insertions! request, insertions
          insertions.each do |insertion|
            insertion[:insertion_id] = @id_generator.newID if not insertion[:insertion_id]
            insertion[:session_id] = request[:session_id] if request[:session_id]
            insertion[:request_id] = request[:request_id] if request[:request_id]
          end
        end

        # A list of the response Insertions.  This client expects lists to be truncated
        # already to request.paging.size.  If not truncated, this client will truncate
        # the list.
        def insertion
          @insertion
        end
      end
    end
  end
end

require "promoted/ruby/client/constants"
require "promoted/ruby/client/extensions"
require "promoted/ruby/client/id_generator"
