module Promoted
    module Ruby
      module Client
        module Util
            def self.translate_args(args)
              args.transform_keys(&:to_sym)
              rescue => e
                raise 'Unable to parse args. Please pass correct arguments. Must be JSON'
              end      
        end
      end
  end
end