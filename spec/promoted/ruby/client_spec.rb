require 'spec_helper'

RSpec.describe Promoted::Ruby::Client do
  let!(:input) { SAMPLE_INPUT }
  let!(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input) }

  it "has a version number" do
    expect(Promoted::Ruby::Client::VERSION).not_to be nil
  end

  context "prepare_for_logging when no limit is set" do
    it "has user_info set" do
      expect(logging_json[:user_info]).not_to be nil
      expect(logging_json[:user_info][:user_id]).to eq(input.dig('request', 'user_info', 'user_id'))
      expect(logging_json[:user_info][:log_user_id]).to eq(input.dig('request', 'user_info', 'log_user_id'))
    end

    it "should not have full_insertion" do
      expect(logging_json[:full_insertion]).to be nil
    end

    it "should have insertion set" do
      expect(logging_json[:insertion].length).to eq(input["full_insertion"].length)
      expect(logging_json[:insertion]).not_to be nil
    end

    it "should have request_id set" do
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end

    it "should have insertion_id set" do
      logging_json[:insertion].each do |insertion|
        expect(insertion[:insertion_id]).not_to be nil
      end
    end
  end

  context "prepare_for_logging when no limit is set" do
    let!(:input_with_limit) do
      dup_input = input.dup
      dup_input["limit"] = 2
      dup_input
    end
    let(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input_with_limit) }

    it "should have insertion set" do
      expect(logging_json[:insertion]).not_to be nil
      expect(logging_json[:insertion].length).to eq(input_with_limit["limit"])
    end
  end
end
