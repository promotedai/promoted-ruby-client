require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::LogRequestBuilder do
  let!(:input) { Promoted::Ruby::Client::Util.translate_args(SAMPLE_INPUT) }

  context "attributes" do
    it "should set attributes" do
      lrb = subject.class.new
      lrb.set_request_params(input)
      expect(lrb.request).to eq(input[:request])
      expect(lrb.full_insertion).to eq(input[:full_insertion])
    end
  end

  context "log_request_params" do
    it "should return expected logging object" do
      lrb = subject.class.new
      lrb.set_request_params(input)
      prepare_for_logging_obj = lrb.log_request_params
      output = {
                  user_info:
                  {
                    user_id: "912", log_user_id: "91232"
                  },
                  timing:
                  {
                    client_log_timestamp: lrb.client_log_timestamp
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
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: lrb.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][0][:insertion_id],
                    request_id: lrb.request_id,
                    position: 0
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabea",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: lrb.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][1][:insertion_id],
                    request_id: lrb.request_id,
                    position: 1
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: lrb.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][2][:insertion_id],
                    request_id: lrb.request_id,
                    position: 2
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: lrb.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][3][:insertion_id],
                    request_id: lrb.request_id,
                    position: 3
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: lrb.client_log_timestamp},
                    insertion_id: prepare_for_logging_obj[:insertion][4][:insertion_id],
                    request_id: lrb.request_id,
                    position: 4
                  }]
                }
      expect( prepare_for_logging_obj == output ).to be_truthy
    end
  end
end

require "promoted/ruby/client/util"
