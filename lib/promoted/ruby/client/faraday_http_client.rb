require 'faraday'
require 'faraday_middleware'

module Promoted
    module Ruby
      module Client
        class FaradayHTTPClient
 
            def initialize(logger = nil)
                @conn = Faraday.new do |f|
                    f.request :json
                    f.request :retry, max: 3
                    if logger
                      f.response :logger, logger, { headers: false, bodies: true, log_level: :debug }
                    end
                    f.use Faraday::Response::RaiseError # raises on 4xx and 5xx responses
                    f.adapter :net_http_persistent
                end
            end

            def send(endpoint, timeout_millis, request, additional_headers={})
                response = @conn.post(endpoint) do |req|
                    req.headers                 = req.headers.merge(additional_headers) if additional_headers
                    req.headers['Content-Type'] = req.headers['Content-Type'] || 'application/json'
                    req.options.timeout         = timeout_millis.to_f / 1000
                    req.body                    = request.to_json
                  end
        
                  norm_headers = response.headers.transform_keys(&:downcase)
                  if norm_headers["content-type"] != nil && norm_headers["content-type"].start_with?("application/json")
                    JSON.parse(response.body, :symbolize_names => true)
                  else
                    response.body
                  end
            end

            def get(endpoint)
              @conn.get(endpoint).body
            end
        end
      end
    end
end
