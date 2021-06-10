module Promoted
  module Ruby
    module Client
      class Settings

        def self.check_that_log_ids_not_set! options_hash
          raise RequestError if options_hash.dig("request", "request_id")
          raise RequestInsertionError if options_hash["insertion"]

          options_hash["full_insertion"].each do |insertion_hash|
            raise InsertionRequestIdError if insertion_hash["request_id"]
            raise InsertionIdError if insertion_hash["insertion_id"]
          end
          true
        end
      end
    end
  end
end

require "promoted/ruby/client/errors"