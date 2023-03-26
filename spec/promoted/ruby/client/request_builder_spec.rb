require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::RequestBuilder do
  let!(:input) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT) }
  let!(:input_with_props) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT_WITH_PROP)}

  context "attributes" do
    it "should set attributes" do
      request_builder = subject.class.new
      request_builder.set_request_params(input)
      expect(request_builder.request).to eq(input[:request])
      expect(request_builder.insertion).to eq(input[:request][:insertion])
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
      expect(output[:insertion].length).to eq input[:request][:insertion].length
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
end

require "promoted/ruby/client/util"
