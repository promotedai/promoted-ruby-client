module Promoted
    module Ruby
      module Client
        class Validator
            def validate_user_info!(ui)
                validate_fields!(
                    ui,
                    "user info",
                    [
                        {
                            :name => :user_id,
                            :type => String
                        },
                        {
                            :name => :log_user_id,
                            :type => String
                        },
                        {
                            :name => :is_internal_user,
                            :type => [TrueClass, FalseClass]
                        }
                    ]
                )
            end

            def validate_insertion!(ins)
                validate_fields!(
                    ins,
                    "insertion",
                    [
                        {
                            :name => :platform_id,
                            :type => Integer
                        },
                        {
                            :name => :insertion_id,
                            :type => String
                        },
                        {
                            :name => :request_id,
                            :type => String
                        },
                        {
                            :name => :view_id,
                            :type => String
                        },
                        {
                            :name => :session_id,
                            :type => String
                        },
                        {
                            :name => :content_id,
                            :type => String
                        },
                        {
                            :name => :position,
                            :type => Integer
                        },
                        {
                            :name => :delivery_score,
                            :type => Integer
                        },
                        {
                            :name => :retrieval_rank,
                            :type => Integer
                        },
                        {
                            :name => :retrieval_score,
                            :type => Float
                        }
                    ]
                )

                if ins[:user_info] then
                    self.validate_user_info! ins[:user_info]
                end
            end

            def validate_request!(req)
                validate_fields!(
                    req,
                    "request",
                    [
                        {
                            :name => :platform_id,
                            :type => Integer
                        },
                        {
                            :name => :request_id,
                            :type => String
                        },
                        {
                            :name => :view_id,
                            :type => String
                        },
                        {
                            :name => :session_id,
                            :type => String
                        },
                        {
                            :name => :insertion,
                            :type => Array
                        }
                    ]
                )

                if req[:insertion] then
                    req[:insertion].each {|ins|
                        validate_insertion! ins
                    }
                end

                if req[:user_info] then
                    validate_user_info! req[:user_info]
                end
            end

            def validate_metrics_request!(metrics_req)
                validate_fields!(
                    metrics_req,
                    "metrics request",
                    [
                        {
                            :name => :request,
                            :required => true
                        },
                        {
                            :name => :full_insertion,
                            :required => true,
                            :type => Array
                        }
                    ]
                )

                validate_request!(metrics_req[:request])
                metrics_req[:full_insertion].each {|ins|
                    validate_insertion! ins
                }
            end

            def check_that_log_ids_not_set! req
                raise ValidationError.new("Request.requestId should not be set") if req.dig(:request, :request_id)
                raise ValidationError.new("Do not set Request.insertion.  Set full_insertion.") if req[:insertion]
      
                req[:full_insertion].each do |insertion_hash|
                  raise ValidationError.new("Insertion.requestId should not be set") if insertion_hash[:request_id]
                  raise ValidationError.new("'Insertion.insertionId should not be set") if insertion_hash[:insertion_id]
                end
            end
            
            def check_that_content_ids_are_set! req
              req[:full_insertion].each do |insertion_hash|
                raise ValidationError.new("Insertion.contentId should be set") if !insertion_hash[:content_id] || insertion_hash[:content_id].empty?
              end
            end

            private

            def validate_fields!(obj, obj_name, fields)
                fields.each {|field|
                    if field[:required] then
                        raise ValidationError.new(field[:name].to_s + " is required on " + obj_name) if !obj.has_key?(field[:name])
                    end

                    # If a field is provided as non-nil, it should be of the correct type.
                    if field[:type] && obj.has_key?(field[:name]) && obj[field[:name]] != nil then
                        if field[:type].is_a?(Array) then
                            raise ValidationError.new(field[:name].to_s + " should be one of " + field[:type].to_s) if !field[:type].include?(obj[field[:name]].class)
                        else
                            raise ValidationError.new(field[:name].to_s + " should be a " + field[:type].to_s) if !obj[field[:name]].is_a?(field[:type])
                        end
                    end
                }
            end
        end
      end
   end
 end
  
require "promoted/ruby/client/errors"