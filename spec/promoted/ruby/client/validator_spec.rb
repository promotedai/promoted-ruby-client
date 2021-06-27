require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Validator do
    let!(:input) { Promoted::Ruby::Client::Util.translate_args(SAMPLE_INPUT_WITH_PROP) }
    let!(:v) { Promoted::Ruby::Client::Validator }
    
    context("metrics request") do
        it "requires request" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input.delete :request
            expect { v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request/)
        end

        it "requires request" do
            dup_input = Marshal.load(Marshal.dump(input))
            dup_input.delete :full_insertion
            expect { v.validate_metrics_request!(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /full_insertion/)
        end

    end
end

require "promoted/ruby/client/util"
