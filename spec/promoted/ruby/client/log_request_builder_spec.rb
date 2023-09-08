require 'spec_helper'
require "promoted/ruby/client/log_request_builder"
require "promoted/ruby/client/request_builder"
require "promoted/ruby/client/util"

RSpec.describe Promoted::Ruby::Client::LogRequestBuilder do
  let!(:input) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT) }

  context "log_request" do
    it "should return expected logging object" do
      log_request_builder = subject.class.new({:id_generator => FakeIdGenerator.new })

      delivery_request_builder = Promoted::Ruby::Client::RequestBuilder.new({:id_generator => FakeIdGenerator.new })
      delivery_request_builder.set_request_params(input)

      log_request_builder.request = delivery_request_builder.delivery_request_params
      response_insertions = []
      delivery_request_builder.request[:insertion].each_with_index do |req_insertion, index|
        response_insertion = Hash[]
        response_insertion[:content_id]   = req_insertion[:content_id]
        response_insertion[:position]     = index
        response_insertion[:insertion_id] = "10"
        response_insertions << response_insertion.clean!
      end
      log_request_builder.response_insertions = response_insertions
      log_request_builder.experiment = nil
      log_req = log_request_builder.log_request(
        include_delivery_log: true, 
        exec_server: Promoted::Ruby::Client::EXECUTION_SERVER['SDK'])

      expected = {
                  user_info:
                  {
                    user_id: "912", anon_user_id: "91232"
                  },
                  timing:
                  {
                    client_log_timestamp: log_req[:timing][:client_log_timestamp]
                  },
                  client_info:
                  {
                    client_type: "PLATFORM_SERVER",
                    traffic_type: "PRODUCTION"
                  },
                  device: {
                    device_type: "DESKTOP",
                    ip_address: "127.0.0.1",
                    browser: {
                        user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
                    }
                  },
                  delivery_log: [{
                    execution: {
                      execution_server: "SDK",
                      server_version: "rb." + Promoted::Ruby::Client::VERSION
                    },
                    request: {
                      :use_case=>"FEED",
                      :properties=>
                      {
                        :struct=>
                        {
                        }
                      },
                      client_request_id: "10",
                      insertion:
                      [{
                        content_id: "5b4a6512326bd9777abfabc34",
                        properties: {}
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabea",
                        properties: {}
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        properties: {}
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        properties: {}
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        properties: {}
                      }],
                      request_id: "10",
                    },
                    response: {
                      insertion:
                      [{
                        content_id: "5b4a6512326bd9777abfabc34",
                        position: 0,
                        insertion_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabea",
                        position: 1,
                        insertion_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        position: 2,
                        insertion_id: "10",
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        position: 3,
                        insertion_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        position: 4,
                        insertion_id: "10"
                      }]
                    }
                  }],
                }
      # Useful for debugging
      # puts(expected.to_json)
      # puts(log_req.to_json)
      expect( expected == log_req ).to be_truthy
    end
  end
end
