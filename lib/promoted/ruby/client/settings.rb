module Promoted
  module Ruby
    module Client
      class Settings

        def self.check_that_log_ids_not_set! options_obj
          raise RequestError if options_obj.request_id

          options_obj.compact_insertions.each do |insertion_hash|
            raise InsertionRequestIdError if insertion_hash[:request_id]
            raise InsertionIdError if insertion_hash[:insertion_id]
            raise InsertionContentId if insertion_hash[:content_id]
          end

          true
        end
      end
    end
  end
end

require "promoted/ruby/client/errors"