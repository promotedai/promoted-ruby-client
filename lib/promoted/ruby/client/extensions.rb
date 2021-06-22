class String
   # Ruby mutation methods have the expectation to return self if a mutation occurred, nil otherwise. (see http://www.ruby-doc.org/core-1.9.3/String.html#method-i-gsub-21)
   def to_underscore!
     gsub!(/(.)([A-Z])/,'\1_\2')
     downcase!
   end

   def to_underscore
     dup.tap { |s| s.to_underscore! }
   end
end

class Hash
  def clean!
    self.delete_if do |key, val|
      if block_given?
          yield(key,val)
      else
        # checks for empty/blank values
        nil_value       = val.nil?
        falsy           = val === false
        is_empty        = val.empty? if val.respond_to?('empty?')
        is_empty_string = val.strip.empty? if val.is_a?(String) && val.respond_to?('empty?')

        # Were any of the checks true
        nil_value || falsy || is_empty || is_empty_string
      end
    end

    self.each do |key, val|
      if self[key].is_a?(Hash) && self[key].respond_to?('clean!')
        if block_given?
          self[key] = self[key].clean!(&Proc.new)
        else
          self[key] = self[key].clean!
        end
      end
    end
    return self
  end
end 