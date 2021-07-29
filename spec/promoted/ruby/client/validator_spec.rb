require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Validator do
    let!(:input) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT_WITH_PROP) }
    before(:all) { @v = described_class.new }

    context("metrics request") do
        it "requires request" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input.delete :request
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request/)
        end

        it "requires full_insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input.delete :full_insertion
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /full_insertion/)
        end

        it "validates correct full_insertion type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion] = {}
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /full_insertion/)
        end
    end

    context("request") do
        it "validates correct platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:platform_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:platform_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /platform_id/)
        end

        it "validates correct request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:request_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:request_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request_id/)
        end

        it "validates correct view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /view_id/)
        end

        it "validates correct session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:session_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /session_id/)
        end
    end

    context "user info" do
        it "validates correct user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /user_id/)
        end
    
        it "validates correct log_user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:log_user_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect log_user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:log_user_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /log_user_id/)
        end

        it "allows nil as a value on optional types" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = nil
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end
    
    end

    context "insertion" do
        it "validates correct platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:platform_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:platform_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /platform_id/)
        end
       
        it "validates correct insertion_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:insertion_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect insertion_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:insertion_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /insertion_id/)
        end
       
        it "validates correct request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:request_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:request_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request_id/)
        end
       
        it "validates correct view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:view_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:view_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /view_id/)
        end
       
        it "validates correct session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:session_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:session_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /session_id/)
        end
       
        it "validates correct content_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:content_id] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect content_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:content_id] = 5
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /content_id/)
        end
       
        it "validates correct position type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:position] = 5
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect position type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:position] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /position/)
        end
       
        it "validates correct delivery_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:delivery_score] = 5
            expect { @v.validate_metrics_request!(dup_input) }.not_to raise_error
        end

        it "validates incorrect delivery_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion][0][:delivery_score] = "5"
            expect { @v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /delivery_score/)
        end       
    end

    context "check log ids not set" do
        it "should not raise any errors" do
            expect { @v.check_that_log_ids_not_set!(input) }.not_to raise_error
        end
    
        it "should raise error for request_id" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:request_id] = SecureRandom.uuid
            expect { @v.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /requestId should not be set/)
        end
    
        it "should raise error for request_id set in full_insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion].first[:request_id] = SecureRandom.uuid
            expect { @v.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /Insertion.requestId should not be set/)
        end
    
        it "should raise insertion_id error for insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:insertion] = []
            expect { @v.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /Set full_insertion/)
        end
    
        it "should raise delivery_score error for insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:full_insertion].first[:delivery_score] = 5
            expect { @v.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /deliveryScore should not be set/)
        end
    end
end

require "promoted/ruby/client/util"
