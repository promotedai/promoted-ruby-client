module Promoted
  module Ruby
    module Client
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
