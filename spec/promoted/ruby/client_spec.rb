require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::PromotedClient do
  let!(:input) { Hash[SAMPLE_INPUT] }

  it "has a version number" do
    expect(Promoted::Ruby::Client::VERSION).not_to be nil
  end

  context "prepare_for_logging when no limit is set" do
    it "has user_info set" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:user_info]).not_to be nil
      expect(logging_json[:user_info][:user_id]).to eq(input.dig('request', 'user_info', 'user_id'))
      expect(logging_json[:user_info][:log_user_id]).to eq(input.dig('request', 'user_info', 'log_user_id'))
    end

    it "should not have full_insertion" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:full_insertion]).to be nil
    end

    it "should have insertion set" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:insertion].length).to eq(input["full_insertion"].length)
      expect(logging_json[:insertion]).not_to be nil
    end

    it "should have request_id set" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end

    it "should have insertion_id set" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:insertion_id]).not_to be nil
      end
    end
  end

  context "prepare_for_logging when no limit is set" do
    let!(:input_with_limit) do
      dup_input                      = Hash[input]
      request                        = dup_input["request"]
      request[:paging]               = { size: 2, offset: 0 }
      dup_input
    end
    it "should have insertion set" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:insertion]).not_to be nil
      expect(logging_json[:insertion].length).to eq(input_with_limit["request"].dig(:paging, :size).to_i)
    end
  end

  context "extra fields at the top level on insertions" do
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop
    end

    it "passes along extra fields on the insertions" do
      dup_input                       = Hash[input_with_prop]
      dup_input["full_insertion"].each_with_index do |insertion, idx|
        insertion["session_id"] = "uuid" + idx.to_s
        insertion["view_id"] = "uuid" + idx.to_s
      end

      client = subject.class.new
      logging_json = client.prepare_for_logging(dup_input)
      expect(logging_json[:insertion][0].key?(:session_id)).to be true
      expect(logging_json[:insertion][0][:session_id]).to eq "uuid0"
      expect(logging_json[:insertion][0].key?(:view_id)).to be true
      expect(logging_json[:insertion][0][:view_id]).to eq "uuid0"
    end
  end

  context "shadow traffic" do
    it "throws if shadow traffic is on and request is prepaged" do
      dup_input                       = Hash[input]
      dup_input["insertion_page_type"] = Promoted::Ruby::Client::INSERTION_PAGING_TYPE['PRE_PAGED']

      client = subject.class.new({ :shadow_traffic_delivery_percent => 0.5 })
      expect { client.prepare_for_logging(dup_input) }.to raise_error(Promoted::Ruby::Client::ShadowTrafficInsertionPageType)
    end

    it "throws if shadow traffic is on and request paging type is undefined" do
      client = subject.class.new({ :shadow_traffic_delivery_percent => 0.5 })
      expect { client.prepare_for_logging(input) }.to raise_error(Promoted::Ruby::Client::ShadowTrafficInsertionPageType)
    end

    it "paging type is not checked when perform checks is off" do
      client = subject.class.new({ :shadow_traffic_delivery_percent => 0.5, :perform_checks => false })
      expect { client.prepare_for_logging(input) }.not_to raise_error
    end

    it "does not throw for unpaged insertions" do
      dup_input                       = Hash[input]
      dup_input[:insertion_page_type] = Promoted::Ruby::Client::INSERTION_PAGING_TYPE['UNPAGED']

      client = subject.class.new({ :shadow_traffic_delivery_percent => 0.5 })
      expect { client.prepare_for_logging(dup_input) }.not_to raise_error
    end
  end

  context "copy and remove properties compact func" do
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop[:compact_func] = subject.class.copy_and_remove_properties
      input_with_prop
    end

    it "should take proc from input and delete the property values accordingly" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        expect(insertion.key?(:properties)).to be false
      end
    end
  end

  context "prepare_for_logging when user defined method is passed" do
    let!(:compact_func) do
      Proc.new do |insertion|
        insertion[:properties].delete("invites_required")
        insertion[:properties].delete("should_discount_addons")
        insertion[:properties].delete("total_uses")
        insertion[:properties].delete("is_archived")
        insertion
      end
    end
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop[:compact_func] = compact_func
      input_with_prop
    end

    it "should take proc from input and delete the property values accordingly" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:properties].key?("invites_required")).to be false
        expect(insertion[:properties].key?("should_discount_addons")).to be false
        expect(insertion[:properties].key?("total_uses")).to be false
        expect(insertion[:properties].key?("is_archived")).to be false
      end
    end

    it "should take proc from input but should not delete the property values that are not included in proc" do
      client = subject.class.new
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:properties].key?("some_property_1")).to be true
        expect(insertion[:properties].key?("some_property_2")).to be true
        expect(insertion[:properties].key?("last_used_at")).to be true
        expect(insertion[:properties].key?("last_purchase_at")).to be true
      end
    end
  end
end

require 'pp'