require 'spec_helper'

RSpec.describe Promoted::Ruby::Client do
  let!(:input) { SAMPLE_INPUT }
  let!(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input) }

  it "has a version number" do
    expect(Promoted::Ruby::Client::VERSION).not_to be nil
  end

  context "prepare_for_logging when no paging.size is set" do
    let!(:input_with_limit) do
      dup_input = input.dup
      dup_request = dup_input["request"].dup
      dup_input[:request] = dup_request
      dup_request[:paging] = {size: 2}
      dup_input
    end
    let(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input_with_limit) }

    it "should have insertion set" do
      expect(logging_json[:insertion]).not_to be nil
      expect(logging_json[:insertion].length).to eq(input_with_limit[:request][:paging][:size])
    end
  end
end
