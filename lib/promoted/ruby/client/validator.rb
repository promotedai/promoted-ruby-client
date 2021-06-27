module Promoted
    module Ruby
      module Client
        class Validator
            def self.validate_fields!(obj, obj_name, fields)
                fields.each {|field|
                    msg = field[:name] + " is required on " + obj_name
                    raise ValidationError.new(msg) if !obj.has_key?(field[:name].to_sym)
                }
            end

            def self.validate_metrics_request!(metrics_req)
                self.validate_fields!(
                    metrics_req,
                    "metrics request",
                    [
                        {
                            :name => "request"
                        },
                        {
                            :name => "full_insertion",
                        }
                    ]
                )
            end
        end
      end
   end
 end
  
require "promoted/ruby/client/errors"