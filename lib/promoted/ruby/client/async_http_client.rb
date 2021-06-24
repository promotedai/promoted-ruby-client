
require "json"
require "async"
require "async/http/internet"
require "async/http/internet/instance"

module Promoted
    module Ruby
      module Client
        class AsyncHTTPClient
 
            def build_headers(additional_headers)
                headers = [['accept', 'application/json']]
                additional_headers.each do |header_pair| 
                    headers << header_pair
                end
            end

            def send(endpoint, timeout_millis, request, additional_headers=[])
                Async do |task|
                    internet = Async::HTTP::Internet.instance
                
                    headers = build_headers(additional_headers)
                    body = [JSON.dump(request)]
                
                    task.with_timeout(timeout_millis / 1000) do
                        response = internet.post(endpoint, headers, body)
                        response_obj = JSON.parse(response.read, :symbolize_names => true)
                        response_obj
                    end
                rescue Async::TimeoutError
                  # TODO: Handle timeout
                end 
            end

            def send_and_forget(endpoint, timeout_millis, request, additional_headers=[])
                Async do |task|
                    internet = Async::HTTP::Internet.instance
                
                    headers = build_headers(additional_headers)
                    body = [JSON.dump(request)]
                
                    task.with_timeout(timeout_millis / 1000) do
                        response = internet.post(endpoint, headers, body)
                        puts "HERE2"
                    end
                rescue Async::TimeoutError
                  # TODO: Handle timeout
                end 
            end
        end
      end
    end
end
