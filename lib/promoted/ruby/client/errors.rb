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
          'Do not set Request.insertion.  Set full_insertion.'
        end
      end

      class InsertionRequestIdError < StandardError
        def message
          'Insertion.requestId should not be set'
        end
      end

      class DeliveryScoreError < StandardError
        def message
          'Insertion.deliveryScore should not be set'
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

      class ShadowTrafficInsertionPageType < StandardError
        def message
          'Insertions must be unpaged when shadow traffic is on'
        end
      end

      class EndpointError < StandardError
        attr_reader :cause
        def initialize(cause)
          @cause = cause
          super('Error calling Promoted.ai endpoint')
        end
      end

      class ValidationError < StandardError
      end
    end
  end
end
