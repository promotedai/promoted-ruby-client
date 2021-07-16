module Promoted
    module Ruby
      module Client
        class IdGenerator
            def initialize;end

            def newID
                SecureRandom.uuid
            end
        end
    end
  end
end

require 'securerandom'
