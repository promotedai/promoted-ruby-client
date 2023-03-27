module Promoted
  module Ruby
    module Client
      class LogRequestBuilder
        attr_reader :request, :response_insertions, :experiment
        attr_accessor :request, :response_insertions, :experiment

        def initialize args = {}
          if args[:id_generator]
            @id_generator = args[:id_generator]
          else
            @id_generator = IdGenerator.new
          end
        end

        def log_request(include_delivery_log:, exec_server:)
          log_req = {
            platform_id: @request[:platform_id],
            user_info: @request[:user_info],
            # For now, we'll just use the request timestamp.
            timing: @request[:timing],
            client_info: @request[:client_info],
            device: @request[:device],
          }

          if @experiment
            log_req[:cohort_membership] = [@experiment]
          end

          # Log request allows for multiple requests but here we only send one.
          if include_delivery_log
            request[:request_id] = request[:request_id] || @id_generator.newID
            # Remove redundant fields from `request` since they're already on the LogRequest.
            stripped_request = @request.clone
            stripped_request.delete(:platform_id)
            stripped_request.delete(:user_info)
            stripped_request.delete(:timing)
            stripped_request.delete(:device)
            stripped_request.delete(:client_info)

            log_req[:delivery_log] = [{
              execution: {
                execution_server: exec_server,
                server_version: Promoted::Ruby::Client::SERVER_VERSION
              },
              request: stripped_request,
              response: {
                insertion: @response_insertions
              }
            }]
          end
          log_req.clean!
        end
      end
    end
  end
end

require "promoted/ruby/client/constants"
require "promoted/ruby/client/extensions"
require "promoted/ruby/client/id_generator"
