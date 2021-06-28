module Promoted
  module Ruby
    module Client
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
