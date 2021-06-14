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
end