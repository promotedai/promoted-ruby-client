require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Sampler do

  context "fully random" do
    it "selects out" do
        srand(0) # First number is 0.54
        sampler = subject.class.new
        expect(sampler.sample_random?(0.5)).to be_falsy
    end

    it "selects in" do
        srand(0)
        sampler = subject.class.new
        expect(sampler.sample_random?(0.6)).to be_truthy
    end

    it "selects big" do
        srand(0)
        sampler = subject.class.new
        expect(sampler.sample_random?(1.1)).to be_truthy
    end

    it "unselects small" do
        srand(0)
        sampler = subject.class.new
        expect(sampler.sample_random?(-0.1)).to be_falsy
    end
  end
end