require 'spec_helper'

RSpec.describe Promoted::Ruby::Client::Pager do
  before(:each) do
    @insertions = [
      {
        :insertion_id => "uuid0-0",
        :request_id => "uuid0-1",
        :view_id => "uuid0-2"
      },
      {
        :insertion_id => "uuid1-0",
        :request_id => "uuid1-1",
        :view_id => "uuid1-2"
      },
      {
        :insertion_id => "uuid2-0",
        :request_id => "uuid2-1",
        :view_id => "uuid2-2"
      }
    ]
  end

  context "validate paging" do
    it "takes a valid set of paging" do
      paging = {
        :size => 2,
        :offset => 1
      }

      pager = subject.class.new
      expect { pager.validate_paging(@insertions, 0, paging) }.not_to raise_error
    end

    it "raises on out of range offset" do
      paging = {
        :size => 2,
        :offset => 999
      }

      found_err = nil
      pager = subject.class.new
      begin
        pager.validate_paging(@insertions, 0, paging)
      rescue StandardError => err
        found_err = err
      end

      expect(found_err).not_to be nil
      expect(found_err).to be_a Promoted::Ruby::Client::InvalidPagingError
      expect(found_err.default_insertions_page).not_to be nil
      expect(found_err.default_insertions_page.length).to eq 0
      expect(found_err.message).to match(/Invalid page offset/)
      expect(found_err.message).to match(/999/)
    end

    it "raises on retrieval_insertion_offset" do
      paging = {
        :size => 2,
        :offset => 0
      }

      found_err = nil
      pager = subject.class.new
      begin
        pager.validate_paging(@insertions, 2, paging)
      rescue StandardError => err
        found_err = err
      end

      expect(found_err).not_to be nil
      expect(found_err).to be_a Promoted::Ruby::Client::InvalidPagingError
      expect(found_err.default_insertions_page).not_to be nil
      expect(found_err.default_insertions_page.length).to eq 0
      expect(found_err.message).to match(/Invalid page offset/)
      expect(found_err.message).to match(/2/)
    end
  end

  context "apply paging" do
    it "pages a window" do
      paging = {
        :size => 2,
        :offset => 1
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length - 1

      # We take a page size of 2 starting at offset 1
      expect(res[0][:insertion_id]).to eq @insertions[1][:insertion_id]
      expect(res[1][:insertion_id]).to eq @insertions[2][:insertion_id]

      # Positions start at offset when retrieval_request_offset = 0.
      expect(res[0][:position]).to eq 1
      expect(res[1][:position]).to eq 2
    end

    it "creates a short page if necessary at the end" do
      paging = {
        :size => 3,
        :offset => 1
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length - 1

      # We take a page size of 2 since the 3rd would be off the end, starting at offset 1
      expect(res[0][:insertion_id]).to eq @insertions[1][:insertion_id]
      expect(res[1][:insertion_id]).to eq @insertions[2][:insertion_id]

      # Positions start at offset when retrieval_request_offset = 0.
      expect(res[0][:position]).to eq 1
      expect(res[1][:position]).to eq 2
    end

    it "does not create a short page at the end - retrieval_insertion_offset > 0" do
      paging = {
        :size => 4,
        :offset => 1
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 1, paging)
      expect(res.length).to eq @insertions.length

      # Expect 3 insertions back since the retrieved insertions start at 1 and the response insertion offset starts at 1.
      expect(res[0][:insertion_id]).to eq @insertions[0][:insertion_id]
      expect(res[1][:insertion_id]).to eq @insertions[1][:insertion_id]
      expect(res[2][:insertion_id]).to eq @insertions[2][:insertion_id]

      # Positions start at offset.
      expect(res[0][:position]).to eq 1
      expect(res[1][:position]).to eq 2
      expect(res[2][:position]).to eq 3
    end

    it "pages a window when retrieval_insertion_offset > 0" do
      paging = {
        :size => 2,
        :offset => 1
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 1, paging)
      expect(res.length).to eq @insertions.length - 1

      # Expect 2 since size = 2.  Since retrieval_insertion_offset is 1 and offset is 1, the first insertion is the first insertion in the request list.
      expect(res[0][:insertion_id]).to eq @insertions[0][:insertion_id]
      expect(res[1][:insertion_id]).to eq @insertions[1][:insertion_id]

      # Positions start at offset.
      expect(res[0][:position]).to eq 1
      expect(res[1][:position]).to eq 2
    end

    it "returns everything when no paging provided" do
      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0)
      expect(res.length).to eq @insertions.length

      # Should assign positions since they weren't already set.
      expect(res[0][:position]).to eq 0
      expect(res[1][:position]).to eq 1
      expect(res[2][:position]).to eq 2
    end

    it "handles empty input" do
      pager = subject.class.new
      res = pager.apply_paging([], 0)
      expect(res.length).to eq 0
    end

    it "handles empty input when paging provided" do
      paging = {
        :size => 1,
        :offset => 1
      }

      pager = subject.class.new
      res = pager.apply_paging([], 0, paging)
      expect(res.length).to eq 0
    end

    it "returns everything with huge page size" do
      paging = {
        :size => 100,
        :offset => 0
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length
    end

    it "returns everything with invalid page size" do
      paging = {
        :size => -1,
        :offset => 0
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length
    end

    it "returns everything with invalid page size" do
      paging = {
        :size => -1,
        :offset => 0
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length
    end

    it "handles invalid offset by starting at 0" do
      paging = {
        :size => 100,
        :offset => -1
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq @insertions.length
      expect(res[0][:position]).to eq 0
      expect(res[1][:position]).to eq 1
      expect(res[2][:position]).to eq 2
    end

    it "handles out of range offset" do
      paging = {
        :size => 1,
        :offset => 10
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 0, paging)
      expect(res.length).to eq 0
    end

    it "handles invalid offset < retrieval_insertion_offset by starting at 0" do
      paging = {
        :size => 100,
        :offset => 0
      }

      pager = subject.class.new
      res = pager.apply_paging(@insertions, 1, paging)
      expect(res.length).to eq 0
    end
  end
end