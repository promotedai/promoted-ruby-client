module Promoted
    module Ruby
      module Client
        class Sampler
            def sample_random? (threshold)
                true if threshold >= 1.0
                false if threshold <= 0.0
                threshold >= rand()
            end
        end
      end
   end
end