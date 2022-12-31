module Promoted
  module Ruby
    module Client
      class RequestBuilder
        attr_reader   :session_id, :only_log, :experiment, :client_info, :device,
                      :view_id, :insertion, :request_id, :use_case, :request

        attr_accessor :timing, :user_info, :platform_id, :insertion

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
          @device                  = request[:device] || {}
          @view_id                 = request[:view_id]
          @use_case                = Promoted::Ruby::Client::USE_CASES[request[:use_case]] || Promoted::Ruby::Client::USE_CASES['UNKNOWN_USE_CASE']
          @insertion               = request[:insertion] || []
          @user_info               = request[:user_info] || { :user_id => nil, :log_user_id => nil}
          @timing                  = request[:timing] || { :client_log_timestamp => (Time.now.to_f * 1000).to_i }

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
        def delivery_request_params
          params = {
            user_info: user_info,
            timing: timing,
            client_info: merge_client_info_defaults,
            device: @device,
            platform_id: @platform_id,
            view_id: @view_id,
            session_id: @session_id,
            use_case: @use_case,
            search_query: request[:search_query],
            properties: request[:properties],
            paging: request[:paging],
            client_request_id: client_request_id
          }
          params[:insertion] = insertion

          params.clean!
        end

        # Only used in delivery
        # Maps the response insertions to the full insertions and re-insert the properties bag
        # to the responses.
        def fill_details_from_response response_insertions
          if !response_insertions then
            response_insertions = []
          end

          props = @insertion.each_with_object({}) do |insertion, hash|
            if insertion.has_key?(:properties)
              # Don't add nil properties to response insertions.
              hash[insertion[:content_id]] = insertion[:properties]
            end
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

        def log_request_params(include_delivery_log:, exec_server:)
          params = {
            user_info: user_info,
            timing: timing,
            client_info: merge_client_info_defaults,
            device: @device,
          }

          if @experiment
            params[:cohort_membership] = [@experiment]
          end

          # Log request allows for multiple requests but here we only send one.
          if include_delivery_log
            request[:request_id] = request[:request_id] || @id_generator.newID

            params[:delivery_log] = [{
              execution: {
                execution_server: exec_server,
                server_version: Promoted::Ruby::Client::SERVER_VERSION
              },
              request: request,
              response: {
                insertion: response_insertion
              }
            }]

            add_missing_ids_on_insertions! request, params[:delivery_log][0][:response][:insertion]
          end
          
          params.clean!
        end

        def ensure_client_timestamp
          if timing[:client_log_timestamp].nil?
            timing[:client_log_timestamp] = (Time.now.to_f * 1000).to_i
          end
        end

        def response_insertion
          @response_insertions  = []
          paging                = request[:paging] || {}
          size                  = paging[:size] ? paging[:size].to_i : 0
          if size <= 0
            size = insertion.length()
          end
          offset                = paging[:offset] ? paging[:offset].to_i : 0

          insertion.each_with_index do |insertion_obj, index|
            # TODO - this does not look performant.
            break if @response_insertions.length() >= size
            response_insertion = Hash[]
            response_insertion[:content_id]   = insertion_obj[:content_id]
            response_insertion[:position]     = offset + index
            response_insertion[:insertion_id] = insertion_obj[:insertion_id]
            @response_insertions << response_insertion.clean!
          end
          @response_insertions
        end

        def add_missing_insertion_ids! insertions
          insertions.each do |insertion|
            insertion[:insertion_id] = @id_generator.newID if not insertion[:insertion_id]
          end
        end

        def client_request_id
          request[:client_request_id]
        end

        private

        def merge_client_info_defaults
          return @client_info.merge({
            :client_type => Promoted::Ruby::Client::CLIENT_TYPE['PLATFORM_SERVER'],
            :traffic_type => Promoted::Ruby::Client::TRAFFIC_TYPE['PRODUCTION']
          })
        end
        
        def add_missing_ids_on_insertions! request, insertions
          add_missing_insertion_ids! insertions
        end

        #def insertion
        #  @insertion
        #end
      end
    end
  end
end

require "promoted/ruby/client/constants"
require "promoted/ruby/client/extensions"
require "promoted/ruby/client/id_generator"
