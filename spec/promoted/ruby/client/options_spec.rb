require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Options do
  let!(:input) { Hash[SAMPLE_INPUT] }

  context "attributes" do
    it "should set attributes" do
      options_obj = subject.class.new
      options_obj.set_request_params(input)
      expect(options_obj.request).to eq(input["request"])
      expect(options_obj.full_insertion).to eq(input["full_insertion"])
    end
  end

  context "log_request_params" do
    it "should return expected logging object" do
      options = subject.class.new
      options.set_request_params(input)
      prepare_for_logging_obj = options.log_request_params
      output = {
                  user_info:
                  {
                    user_id: "912", log_user_id: "91232"
                  },
                  timing:
                  {
                    client_log_timestamp: options.client_log_timestamp
                  },
                  request:
                  [{
                    "user_info"=> {"user_id"=>"912", "log_user_id"=>"91232"},
                    "use_case"=>"FEED",
                    "properties"=>
                    {
                      "struct"=>
                      {
                        "query"=>{}
                      }
                    }
                  }],
                  insertion:
                  [{
                    content_id: "5b4a6512326bd9777abfabc34",
                    properties: [],
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: options.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][0][:insertion_id],
                    request_id: options.request_id,
                    position: 0
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabea",
                    properties: [],
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: options.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][1][:insertion_id],
                    request_id: options.request_id,
                    position: 1
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    properties: [],
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: options.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][2][:insertion_id],
                    request_id: options.request_id,
                    position: 2
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    properties: [],
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: options.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][3][:insertion_id],
                    request_id: options.request_id,
                    position: 3
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    properties: [],
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: options.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][4][:insertion_id],
                    request_id: options.request_id,
                    position: 4
                  }]
                }
      expect( prepare_for_logging_obj == output ).to be_truthy
    end
  end
end
