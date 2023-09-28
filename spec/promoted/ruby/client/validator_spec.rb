require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Validator do
    let!(:input) { Promoted::Ruby::Client::Util.translate_hash(SAMPLE_INPUT_WITH_PROP) }
    before(:all) { @v = described_class.new }

    context("delivery args") do
        it "validates valid args" do
            dup_input = Marshal.load(Marshal.dump(input))
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates valid args w/ retrieval_insertion_offset" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:retrieval_insertion_offset] = 2
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "requires request" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input.delete :request
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request/)
        end

        it "requires insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request].delete :insertion
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /insertion/)
        end

        it "validates correct insertion type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion] = {}
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /insertion/)
        end
    end

    context("request") do
        it "validates correct platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:platform_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:platform_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /platform_id/)
        end

        it "validates correct request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:request_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:request_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request_id/)
        end

        it "validates correct view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /view_id/)
        end

        it "validates correct session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:view_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:session_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /session_id/)
        end
    end

    context("response") do
        it "validates requires request_id" do
            response = {}.freeze
            expect { @v.validate_response!(response) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request_id/)
        end

        it "validates adds missing insertion field" do
            response = {
                :request_id => "reqid"
            }
            expect { @v.validate_response!(response) }.not_to raise_error
            expected = []
            expect(response[:insertion]).to eq expected
        end
    end

    context "user info" do
        it "validates correct user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /user_id/)
        end
    
        it "validates correct anon_user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:anon_user_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect anon_user_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:anon_user_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /anon_user_id/)
        end

        it "validates correct is_internal_user type for false" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:is_internal_user] = false
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates correct is_internal_user type for true" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:is_internal_user] = true
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect is_internal_user type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:is_internal_user] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /is_internal_user/)
        end

        it "allows nil as a value on optional types" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:user_info][:user_id] = nil
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end
    
    end

    context "insertion" do
        it "validates correct platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:platform_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect platform_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:platform_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /platform_id/)
        end
       
        it "validates correct insertion_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:insertion_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect insertion_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:insertion_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /insertion_id/)
        end
       
        it "validates correct request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:request_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect request_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:request_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request_id/)
        end
       
        it "validates correct view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:view_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect view_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:view_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /view_id/)
        end
       
        it "validates correct session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:session_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect session_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:session_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /session_id/)
        end
       
        it "validates correct content_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:content_id] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect content_id type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:content_id] = 5
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /content_id/)
        end
       
        it "validates correct position type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:position] = 5
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect position type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:position] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /position/)
        end
       
        it "validates correct delivery_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:delivery_score] = 5
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect delivery_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:delivery_score] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /delivery_score/)
        end       
       
        it "validates correct retrieval_rank type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:retrieval_rank] = 5
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect retrieval_rank type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:retrieval_rank] = "5"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /retrieval_rank/)
        end       
       
        it "validates correct retrieval_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:retrieval_score] = 5.2
            expect { @v.validate_delivery_args!(dup_input) }.not_to raise_error
        end

        it "validates incorrect retrieval_score type" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion][0][:retrieval_score] = "5.2"
            expect { @v.validate_delivery_args!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /retrieval_score/)
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
    
        it "should raise error for request_id set in insertion" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input[:request][:insertion].first[:request_id] = SecureRandom.uuid
            expect { @v.check_that_log_ids_not_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /Insertion.requestId should not be set/)
        end
    end

    context "check content ids are set" do
      it "should not raise any errors" do
          expect { @v.check_that_content_ids_are_set!(input) }.not_to raise_error
      end
  
      it "should raise error for a blank insertion content id" do
          dup_input = Marshal.load(Marshal.dump(input))
          dup_input[:request][:insertion].first[:content_id] = ""
          expect { @v.check_that_content_ids_are_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /Insertion.contentId should be set/)
      end
  
      it "should raise error for a missing insertion content id" do
          dup_input = Marshal.load(Marshal.dump(input))
          dup_input[:request][:insertion].first.delete(:content_id)
          expect { @v.check_that_content_ids_are_set!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /Insertion.contentId should be set/)
      end
  end
end

require "promoted/ruby/client/util"
