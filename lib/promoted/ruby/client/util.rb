module Promoted
    module Ruby
      module Client
        module Util
            def self.translate_array(arr)
              sym_arr = Array.new(arr.length)
              arr.each_with_index do |v, i|
                new_v = v
                case v
                when Hash
                  new_v = translate_hash(v)
                when Array
                  new_v = translate_array(v)
                end
                sym_arr[i] = new_v
              end
              sym_arr
            end

            def self.translate_hash(args)
              sym_hash = {}
              args.each do |k, v|
                new_key = k.to_s.to_underscore.to_sym
                case v
                when Hash
                  sym_hash[new_key] = translate_hash(v)
                when Array
                  sym_hash[new_key] = translate_array(v)
                else
                  sym_hash[new_key] = v
                end
              end
              sym_hash
              rescue => e
                raise 'Unable to parse args. Please pass correct arguments. Must be JSON'
              end      
            end
      end
  end
end