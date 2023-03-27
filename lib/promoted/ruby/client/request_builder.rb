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

        def ensure_client_timestamp
          if timing[:client_log_timestamp].nil?
            timing[:client_log_timestamp] = (Time.now.to_f * 1000).to_i
          end
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
      end
    end
  end
end

require "promoted/ruby/client/constants"
require "promoted/ruby/client/extensions"
require "promoted/ruby/client/id_generator"
