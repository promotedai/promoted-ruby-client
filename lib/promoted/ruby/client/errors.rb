module Promoted
  module Ruby
    module Client
      class RequestError < StandardError
        def message
          'Request.requestId should not be set'
        end
      end

      class RequestInsertionError < StandardError
        def message
          'Do not set Request.insertion.  Set fullInsertion.'
        end
      end

      class InsertionRequestIdError < StandardError
        def message
          'Insertion.requestId should not be set'
        end
      end

      class InsertionIdError < StandardError
        def message
          'Insertion.insertionId should not be set'
        end
      end

      class InsertionContentId < StandardError
        def message
          'Insertion.contentId should be set'
        end
      end

      class DeliverEndpointMissing < StandardError
        def message
          'delivery_endpoint should be set before sending data to API.'
        end
      end
    end
  end
end
