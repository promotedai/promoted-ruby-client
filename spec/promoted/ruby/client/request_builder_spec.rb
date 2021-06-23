require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::RequestBuilder do
  let!(:input) { Promoted::Ruby::Client::Util.translate_args(SAMPLE_INPUT) }
  let!(:input_with_props) { Promoted::Ruby::Client::Util.translate_args(SAMPLE_INPUT_WITH_PROP)}

  context "attributes" do
    it "should set attributes" do
      request_builder = subject.class.new
      request_builder.set_request_params(input)
      expect(request_builder.request).to eq(input[:request])
      expect(request_builder.full_insertion).to eq(input[:full_insertion])
    end
  end

  context "repopulates response insertions" do
    it "fills in response insertions in the normal case" do
      request_builder = subject.class.new
      request_builder.set_request_params(input_with_props)

      insertions = [
        { :content_id=>"5b4a6512326bd9777abfabc34" },
        { :content_id=>"5b4a6512326bd9777abfabea" },
        { :content_id=>"5b4a6512326bd9777abfabcf" }
      ]

      response_insertions = request_builder.fill_details_from_response(insertions)

      expect(response_insertions[0].key?(:properties)).to be true
      expect(response_insertions[1].key?(:properties)).to be false
      expect(response_insertions[2].key?(:properties)).to be true
    end
  end

  context "log_request_params" do
    it "should return expected logging object" do
      request_builder = subject.class.new
      request_builder.set_request_params(input)
      prepare_for_logging_obj = request_builder.log_request_params
      output = {
                  user_info:
                  {
                    user_id: "912", log_user_id: "91232"
                  },
                  timing:
                  {
                    client_log_timestamp: request_builder.timing[:client_log_timestamp]
                  },
                  request:
                  [{
                    :user_info=> {:user_id=>"912", :log_user_id=>"91232"},
                    :use_case=>"FEED",
                    :properties=>
                    {
                      :struct=>
                      {
                        :query=>{}
                      }
                    }
                  }],
                  insertion:
                  [{
                    content_id: "5b4a6512326bd9777abfabc34",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                    insertion_id: prepare_for_logging_obj[:insertion][0][:insertion_id],
                    request_id: request_builder.request_id,
                    position: 0
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabea",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                    insertion_id: prepare_for_logging_obj[:insertion][1][:insertion_id],
                    request_id: request_builder.request_id,
                    position: 1
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                    insertion_id: prepare_for_logging_obj[:insertion][2][:insertion_id],
                    request_id: request_builder.request_id,
                    position: 2
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                    insertion_id: prepare_for_logging_obj[:insertion][3][:insertion_id],
                    request_id: request_builder.request_id,
                    position: 3
                  },
                  {
                    content_id: "5b4a6512326bd9777abfabcf",
                    user_info: {user_id: "912", log_user_id: "91232"},
                    timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                    insertion_id: prepare_for_logging_obj[:insertion][4][:insertion_id],
                    request_id: request_builder.request_id,
                    position: 4
                  }]
                }
      expect( prepare_for_logging_obj == output ).to be_truthy
    end
  end
end

require "promoted/ruby/client/util"
