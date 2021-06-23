module Promoted
    module Ruby
      module Client
        module Util
            def self.translate_args(args)
              sym_hash = {}
              args.each do |k, v|
                sym_hash[k.to_s.to_underscore.to_sym] = v.is_a?(Hash) ? translate_args(v) : v
              end
              sym_hash
              rescue => e
                raise 'Unable to parse args. Please pass correct arguments. Must be JSON'
              end      
        end
      end
  end
end