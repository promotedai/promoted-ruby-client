require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::RequestBuilder do
  let!(:input) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT) }
  let!(:input_with_props) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT_WITH_PROP)}

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

  context "add_missing_insertion_ids" do
    it "adds missing insertion ids" do
      insertions = [
        { :content_id=>"5b4a6512326bd9777abfabc34" },
        { :content_id=>"5b4a6512326bd9777abfabea" },
      ]
      request_builder = subject.class.new({:id_generator => FakeIdGenerator.new })
      request_builder.add_missing_insertion_ids! insertions
      expect(insertions[0][:insertion_id]).to eq "10"
      expect(insertions[1][:insertion_id]).to eq "10"
    end

    it "respects existing insertion ids" do
      insertions = [
        { :content_id=>"5b4a6512326bd9777abfabc34", :insertion_id => "1" },
        { :content_id=>"5b4a6512326bd9777abfabea", :insertion_id => "2" },
      ]
      request_builder = subject.class.new({:id_generator => FakeIdGenerator.new })
      request_builder.add_missing_insertion_ids! insertions
      expect(insertions[0][:insertion_id]).to eq "1"
      expect(insertions[1][:insertion_id]).to eq "2"
    end
  end

  context "delivery_request_params" do
    it "should return expected delivery request" do
      request_builder = subject.class.new({:id_generator => FakeIdGenerator.new })
      request_builder.set_request_params(input)
      output = request_builder.delivery_request_params

      expect(output.key?(:user_info)).to be true
      expect(output[:insertion].length).to be > 0
      expect(output[:insertion].length).to eq input[:full_insertion].length
      expect(output[:client_request_id]).to eq "10"

      # Delivery request should not fill in insertion ids.
      output[:insertion].each {|insertion|
        expect(insertion.key?(:request_id)).to be false
        expect(insertion.key?(:insertion_id)).to be false
      }

      # Should have a timestamp
      expect(output.key?(:timing)).to be true
      expect(output[:timing].key?(:client_log_timestamp)).to be true
      expect(output[:timing][:client_log_timestamp]).to be_instance_of(Integer)

      # Delivery requests don't include the original request field.
      expect(output.key?(:request)).to be false
    end
  end

  context "log_request_params" do
    it "should return expected logging object" do
      request_builder = subject.class.new({:id_generator => FakeIdGenerator.new })
      request_builder.set_request_params(input)
      prepare_for_logging_obj = request_builder.log_request_params(
        include_delivery_log: true, 
        exec_server: Promoted::Ruby::Client::EXECUTION_SERVER['SDK'])
      output = {
                  user_info:
                  {
                    user_id: "912", log_user_id: "91232"
                  },
                  client_info:
                  {
                    traffic_type: "PRODUCTION",
                    client_type: "PLATFORM_SERVER"
                  },
                  timing:
                  {
                    client_log_timestamp: request_builder.timing[:client_log_timestamp]
                  },
                  device: {
                    device_type: "DESKTOP",
                    ip_address: "127.0.0.1",
                    browser: {
                        user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
                    }
                  },
                  delivery_log: [{
                    request: {
                      :user_info=> {:user_id=>"912", :log_user_id=>"91232"},
                      :use_case=>"FEED",
                      device: {
                        device_type: "DESKTOP",
                        ip_address: "127.0.0.1",
                        browser: {
                            user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
                        }
                      },  
                      :properties=>
                      {
                        :struct=>
                        {
                          :query => {}
                        }
                      },
                      request_id: "10",
                      client_request_id: "10"
                    },
                    execution: {
                      execution_server: "SDK"
                    },
                    response: {
                      insertion:
                      [{
                        content_id: "5b4a6512326bd9777abfabc34",
                        user_info: {user_id: "912", log_user_id: "91232"},
                        timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                        insertion_id: "10",
                        position: 0,
                        request_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabea",
                        user_info: {user_id: "912", log_user_id: "91232"},
                        timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                        insertion_id: "10",
                        position: 1,
                        request_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        user_info: {user_id: "912", log_user_id: "91232"},
                        timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                        insertion_id: "10",
                        position: 2,
                        request_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        user_info: {user_id: "912", log_user_id: "91232"},
                        timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                        insertion_id: "10",
                        position: 3,
                        request_id: "10"
                      },
                      {
                        content_id: "5b4a6512326bd9777abfabcf",
                        user_info: {user_id: "912", log_user_id: "91232"},
                        timing: {client_log_timestamp: request_builder.timing[:client_log_timestamp]},
                        insertion_id: "10",
                        position: 4,
                        request_id: "10"
                      }]
                    }
                  }],
                }
      # Useful for debugging
      #puts(prepare_for_logging_obj.to_json)
      #puts(output.to_json)
      expect( prepare_for_logging_obj == output ).to be_truthy
    end
  end
end

require "promoted/ruby/client/util"
