require 'spec_helper'

RSpec.describe Promoted::Ruby::Client do
  let!(:input) { Hash[SAMPLE_INPUT] }
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
      dup_input                      = Hash[input]
      request                        = dup_input["request"]
      request[:paging]               = { size: 2, from: 0 }
      dup_input
    end
    let(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input_with_limit) }
    it "should have insertion set" do
      expect(logging_json[:insertion]).not_to be nil
      expect(logging_json[:insertion].length).to eq(input_with_limit["request"].dig(:paging, :size).to_i)
    end
  end

  context "prepare_for_logging when user defined method is passed" do
    let!(:compact_func) do
      Proc.new do |insertion|
        insertion[:properties].delete("invitesRequired")
        insertion[:properties].delete("shouldDiscountAddons")
        insertion[:properties].delete("tabletShowsPromotionDiscount")
        insertion[:properties].delete("totalUses")
        insertion[:properties].delete("isArchived")
        insertion[:properties].delete("showActiveTimePeriodCountdown")
        insertion
      end
    end
    let!(:input_with_proc) do
      input_with_proc = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_proc[:compact_func] = compact_func
      input_with_proc
    end
    let(:logging_json) { Promoted::Ruby::Client.prepare_for_logging(input_with_proc) }


    it "should take proc from input and delete the property values accordingly" do
      logging_json[:insertion].each do |insertion|
        expect(insertion[:properties].key?("invitesRequired")).to be false
        expect(insertion[:properties].key?("shouldDiscountAddons")).to be false
        expect(insertion[:properties].key?("tabletShowsPromotionDiscount")).to be false
        expect(insertion[:properties].key?("totalUses")).to be false
        expect(insertion[:properties].key?("isArchived")).to be false
        expect(insertion[:properties].key?("showActiveTimePeriodCountdown")).to be false
      end
    end

    it "should take proc from input but should not delete the property values that are not included in proc" do
      logging_json[:insertion].each do |insertion|
        expect(insertion[:properties].key?("isKioskEligible")).to be true
        expect(insertion[:properties].key?("nonCombinable")).to be true
        expect(insertion[:properties].key?("lastUsedAt")).to be true
        expect(insertion[:properties].key?("lastPurchaseAt")).to be true
      end
    end
  end
end