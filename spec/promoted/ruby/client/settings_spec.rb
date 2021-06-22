require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Settings do
  let!(:input) { Promoted::Ruby::Client::Util.translate_args(SAMPLE_INPUT) }

  context "without errors" do
    it "should not raise any errors" do
      expect { subject.class.check_that_log_ids_not_set!(input) }.not_to raise_error
    end
  end

  context "with request errors" do
    it "should raise error for request_id" do
      dup_input = Marshal.load(Marshal.dump(input))
      dup_input[:request][:request_id] = SecureRandom.uuid
      expect { subject.class.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::RequestError)
    end
  end

  context "insertion request_id errors" do
    it "should raise error for request_id set in full_insertion" do
      dup_input = Marshal.load(Marshal.dump(input))
      dup_input[:full_insertion].first[:request_id] = SecureRandom.uuid
      expect { subject.class.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::InsertionRequestIdError)
    end
  end

  context "insertion insertion_id error" do
    it "should raise insertion_id error for insertion" do
      dup_input = Marshal.load(Marshal.dump(input))
      dup_input[:insertion] = []
      expect { subject.class.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::RequestInsertionError)
    end
  end
end

require "promoted/ruby/client/util"