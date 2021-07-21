require 'spec_helper'

ENDPOINTS = { :delivery_endpoint => "http://delivery.example.com", :metrics_endpoint => "http://metrics.example.com" } 

RSpec.describe Promoted::Ruby::Client::PromotedClient do
  let!(:input) { Hash[SAMPLE_INPUT] }
  let!(:input_with_prop) do
    input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
    input_with_prop
  end

  it "has a version number" do
    expect(Promoted::Ruby::Client::VERSION).not_to be nil
  end

  context "initialization" do
    it "requires delivery endpoint" do
      expect { described_class.new( { :metrics_endpoint => "foo", :delivery_endpoint => "   " } ) }.to raise_error(ArgumentError, /delivery_endpoint/)
    end

    it "requires metrics endpoint" do
      expect { described_class.new( { :delivery_endpoint => "foo", :metrics_endpoint => "   " } ) }.to raise_error(ArgumentError, /metrics_endpoint/)
    end

    it "disallows too small shadow traffic percent" do
      expect { described_class.new(ENDPOINTS.merge( { :shadow_traffic_delivery_percent => -1 } )) }.
        to raise_error(ArgumentError, /shadow_traffic_delivery_percent/)
    end

    it "disallows too large shadow traffic percent" do
      expect { described_class.new(ENDPOINTS.merge( { :shadow_traffic_delivery_percent => 1.1 } )) }.
        to raise_error(ArgumentError, /shadow_traffic_delivery_percent/)
    end
  end

  context "validation on prepare" do
    it "passes the request through the validator when perform checks" do
      dup_input = Marshal.load(Marshal.dump(input))
      dup_input.delete :request
      client = described_class.new(ENDPOINTS.merge( { :logger => nil }))
      expect { client.prepare_for_logging(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request/)
    end

    it "does not pass the request through the validator when no perform checks" do
      dup_input = Marshal.load(Marshal.dump(input))
      dup_input.delete :request
      client = described_class.new(ENDPOINTS.merge( { :perform_checks => false, :logger => nil }))
      expect { client.prepare_for_logging(dup_input) }.not_to raise_error
    end
  end

  context "prepare_for_logging when no limit is set" do
    it "has user_info set" do
      client = described_class.new(ENDPOINTS)
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:user_info]).not_to be nil
      expect(logging_json[:user_info][:user_id]).to eq(input.dig(:request, :user_info, :user_id))
      expect(logging_json[:user_info][:log_user_id]).to eq(input.dig(:request, :user_info, :log_user_id))
    end

    it "should not have full_insertion" do
      client = described_class.new(ENDPOINTS)
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:full_insertion]).to be nil
    end

    it "can deal with empty insertions" do
      dup_input = Hash[input]
      dup_input[:full_insertion] = []

      client = described_class.new(ENDPOINTS)
      logging_json = client.prepare_for_logging(dup_input)

      # No need to log empty assertions so we nil it out.
      expect(logging_json[:full_insertion]).to be nil
    end

    it "should have insertion set" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:insertion].length).to eq(input[:full_insertion].length)
      expect(logging_json[:insertion]).not_to be nil
    end

    it "should have request_id set since insertions aren't coming from delivery" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:request].length).to eq 1
      expect(logging_json[:request][0][:request_id]).not_to be nil
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end

    it "should have insertion_id set" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:insertion_id]).not_to be nil
      end
    end

    # Exists for trying out Async HTTP in debugging
    # it "will send a 'real' request" do
    #   client = described_class.new({:delivery_endpoint => "https://httpbin.org/anything", :metrics_endpoint => "https://httpbin.org/anything" })
    #   logging_json = client.prepare_for_logging(input)
    #   resp = client.send_log_request logging_json
    #   expect(resp).not_to be nil
    #   client.close
    # end
  end

  context "prepare_for_logging when no limit is set" do
    let!(:input_with_limit) do
      dup_input                      = Hash[input]
      request                        = dup_input[:request]
      request[:paging]               = { size: 2, offset: 0 }
      dup_input
    end
    it "should have insertion set" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input)
      expect(logging_json[:insertion]).not_to be nil
      expect(logging_json[:insertion].length).to eq(input_with_limit[:request].dig(:paging, :size).to_i)
    end
  end

  context "extra fields at the top level on insertions" do
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop
    end

    it "passes along extra fields on the insertions" do
      dup_input                       = Hash[input_with_prop]
      dup_input[:full_insertion].each_with_index do |insertion, idx|
        insertion[:session_id] = "uuid" + idx.to_s
        insertion[:view_id] = "uuid" + idx.to_s
      end

      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(dup_input)
      expect(logging_json[:insertion][0].key?(:session_id)).to be true
      expect(logging_json[:insertion][0][:session_id]).to eq "uuid0"
      expect(logging_json[:insertion][0].key?(:view_id)).to be true
      expect(logging_json[:insertion][0][:view_id]).to eq "uuid0"
    end
  end

  context "shadow traffic" do
    let!(:input_with_unpaged) do
      input_with_unpaged = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_unpaged[:insertion_page_type] = Promoted::Ruby::Client::INSERTION_PAGING_TYPE['UNPAGED']
      input_with_unpaged
    end

    it "does not throw if shadow traffic is on and request is prepaged" do
      dup_input                       = Hash[input]
      dup_input["insertion_page_type"] = Promoted::Ruby::Client::INSERTION_PAGING_TYPE['PRE_PAGED']

      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0 }))
      expect(client).not_to receive(:send_request)
      expect { client.prepare_for_logging(dup_input) }.not_to raise_error
    end

    it "does not throw if shadow traffic is on and request paging type is undefined" do
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0 }))
      expect(client).not_to receive(:send_request)
      expect { client.prepare_for_logging(input) }.not_to raise_error
    end

    it "paging type is not checked when perform checks is off" do
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0, :perform_checks => false }))
      expect(client).to receive(:send_request)
      expect { client.prepare_for_logging(input) }.not_to raise_error
      client.close
    end

    it "samples in" do
      srand(0)
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 0.6 }))
      expect(client).to receive(:send_request)
      expect { client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
      client.close
    end

    it "samples out" do
      srand(0)
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 0.5 }))
      expect(client).not_to receive(:send_request)
      expect { client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
    end

    it "works in a normal case" do
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0 }))
      expect(client.async_shadow_traffic).to be true

      delivery_req = nil
      expect(client).to receive(:send_request) {|value|
        delivery_req = value
      }

      expect { client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
      client.close

      expect(delivery_req.key?(:insertion)).to be true
      expect(delivery_req[:insertion].length()).to be 5
      expect(delivery_req.key?(:timing)).to be true
      expect(delivery_req.key?(:client_info)).to be true
      expect(delivery_req[:client_info][:traffic_type]).to be Promoted::Ruby::Client::TRAFFIC_TYPE['SHADOW']
      expect(delivery_req[:client_info][:client_type]).to be Promoted::Ruby::Client::CLIENT_TYPE['PLATFORM_SERVER']
      expect(delivery_req.key?(:user_info)).to be true
      expect(delivery_req.key?(:use_case)).to be true
      expect(delivery_req.key?(:properties)).to be true

      # Requests sent to delivery do not have request ids set.
      expect(delivery_req.key?(:request_id)).to be false
    end
        
    it "sends synchronous shadow traffic" do
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0, :async_shadow_traffic => false }))
      expect(client.async_shadow_traffic).to be false

      delivery_req = nil
      expect(client).to receive(:send_request) {|value|
        delivery_req = value
      }
      # no client.close call, which would wait on the thread pool -- the thread pool should not be created in this test case.

      logging_json = nil
      expect { logging_json = client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
      expect(logging_json).not_to be nil

      expect(delivery_req[:client_info][:traffic_type]).to be Promoted::Ruby::Client::TRAFFIC_TYPE['SHADOW']
    end
        
    it "does not raise on error in synchronous shadow traffic" do
      client = described_class.new(ENDPOINTS.merge({ :shadow_traffic_delivery_percent => 1.0, :async_shadow_traffic => false }))
      expect(client.async_shadow_traffic).to be false

      expect(client).to receive(:send_request).and_raise(StandardError)

      # no client.close call, which would wait on the thread pool -- the thread pool should not be created in this test case.

      logging_json = nil
      expect { logging_json = client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
      expect(logging_json).not_to be nil
    end
        
    it "passes the endpoint, timeout, and api key" do
      client = described_class.new(ENDPOINTS.merge( { :shadow_traffic_delivery_percent => 1.0, :delivery_api_key => "my api key", :delivery_timeout_millis => 777 } ))
      recv_headers = nil
      recv_endpoint = nil
      recv_timeout = nil
      allow(client.http_client).to receive(:send) { |endpoint, timeout, request, headers|
        recv_endpoint = endpoint
        recv_headers = headers
        recv_timeout = timeout
      }
      expect { client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
      client.close

      expect(recv_endpoint).to eq(ENDPOINTS[:delivery_endpoint])
      expect(recv_headers.key?("x-api-key")).to be true
      expect(recv_headers["x-api-key"]).to eq("my api key")
      expect(recv_timeout).to eq(777)
    end  
    
    # Exists for trying out Async HTTP in debugging
    # it "will send a 'real' request" do
    #   client = described_class.new({:shadow_traffic_delivery_percent => 1.0, :delivery_endpoint => "https://httpbin.org/anything", :metrics_endpoint => "https://httpbin.org/anything" })
    #   expect { client.prepare_for_logging(input_with_unpaged) }.not_to raise_error
    #   client.close
    # end
  end

  context "copy and remove properties compact func" do
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop[:to_compact_metrics_insertion_func] = described_class.copy_and_remove_properties
      input_with_prop
    end

    it "should take proc from input and delete the property values accordingly" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        expect(insertion.key?(:properties)).to be false
      end
    end
  end

  context "log request" do
    it "works in a good case" do
      client = described_class.new
      expect(client).to receive(:send_request)
      logging_json = client.prepare_for_logging(input)
      expect { client.send_log_request(logging_json) }.not_to raise_error

      # prepare_for_logging should set request and insertion ids
      expect(logging_json[:request].length).to eq 1
      expect(logging_json[:request][0][:request_id]).not_to be nil
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end  

    it "swallows errors" do
      client = described_class.new
      expect(client).to receive(:send_request).and_raise(StandardError)
      logging_json = client.prepare_for_logging(input)
      expect { client.send_log_request(logging_json) }.not_to raise_error
    end  

    it "passes the endpoint, timeout, and api key" do
      client = described_class.new(ENDPOINTS.merge( { :metrics_api_key => "my api key", :metrics_timeout_millis => 777 } ))
      recv_headers = nil
      recv_endpoint = nil
      recv_timeout = nil
      allow(client.http_client).to receive(:send) { |endpoint, timeout, request, headers|
        recv_endpoint = endpoint
        recv_headers = headers
        recv_timeout = timeout
      }
      logging_json = client.prepare_for_logging(input)
      expect { client.send_log_request(logging_json) }.not_to raise_error
      expect(recv_endpoint).to eq(ENDPOINTS[:metrics_endpoint])
      expect(recv_headers.key?("x-api-key")).to be true
      expect(recv_headers["x-api-key"]).to eq("my api key")
      expect(recv_timeout).to eq(777)
    end  
  end

  context "deliver" do
    before(:example) do
      @input = Marshal.load(Marshal.dump(SAMPLE_INPUT_CAMEL))
    end

    context "validation on prepare" do
      it "passes the request through the validator when perform checks" do
        dup_input = Marshal.load(Marshal.dump(@input))
        dup_input.delete :request
        client = described_class.new
        expect { client.deliver(dup_input) }.to raise_error(Promoted::Ruby::Client::ValidationError, /request/)
      end
  
      it "does not pass the request through the validator when no perform checks" do
        dup_input = Marshal.load(Marshal.dump(@input))
        dup_input.delete :request
        client = described_class.new({ :perform_checks => false })
        expect(client).to receive(:send_request).and_return({
          :insertion => []
        })
        expect { client.deliver(dup_input) }.not_to raise_error
      end
    end
    
    it "passes the endpoint and api key" do
      client = described_class.new(ENDPOINTS.merge( { :delivery_api_key => "my api key" } ))
      recv_headers = nil
      recv_endpoint = nil
      allow(client.http_client).to receive(:send) { |endpoint, timeout, request, headers|
        recv_endpoint = endpoint
        recv_headers = headers
      }
      expect { client.deliver(input) }.not_to raise_error
      expect(recv_endpoint).to eq(ENDPOINTS[:delivery_endpoint])
      expect(recv_headers.key?("x-api-key")).to be true
      expect(recv_headers["x-api-key"]).to eq("my api key")
    end  
        
    it "delivers in a good case" do
      client = described_class.new
      full_insertion = @input[:fullInsertion]
      expect(client).to receive(:send_request).and_return({
        :insertion => full_insertion
      })
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).to be nil
    end

    it "delivers with empty insertions, which is not an error" do
      client = described_class.new
      full_insertion = @input[:fullInsertion]
      expect(client).to receive(:send_request).and_return({
        :insertion => []
      })
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true
      expect(deliver_resp[:insertion].length()).to be 0

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).to be nil
    end

    it "delivers with nil insertions, which should default to request insertions" do
      client = described_class.new
      full_insertion = @input[:fullInsertion]
      expect(client).to receive(:send_request).and_return({
        :insertion => nil
      })
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true
      expect(deliver_resp[:insertion].length()).to be full_insertion.length()

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).to be nil
    end

    it "does not deliver for request only_log" do
      client = described_class.new
      @input[:only_log] = true
      expect(client).not_to receive(:send_request)
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).not_to be nil
    end

    it "does not deliver for default only_log" do
      client = described_class.new( { :default_only_log => true } )
      expect(client).not_to receive(:send_request)
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).not_to be nil
    end

    it "swallows errors and defaults the insertions" do
      client = described_class.new
      expect(client).to receive(:send_request).and_raise(StandardError)
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true
      expect(deliver_resp[:insertion].length()).to eq(@input[:fullInsertion].length())
      expect(deliver_resp[:log_request]).not_to be nil
    end
    
    it "can custom compact insertions" do
      @input[:to_compact_delivery_insertion_func] = described_class.copy_and_remove_properties

      client = described_class.new
      full_insertion = @input[:fullInsertion]
      delivery_req = nil
      allow(client).to receive(:send_request) { |value|
        delivery_req = value
        { :insertion => full_insertion }
      }

      deliver_resp = client.deliver @input

      delivery_req[:insertion].each do |insertion|
        expect(insertion.key?(:properties)).to be false
      end

      expect(deliver_resp).not_to be nil
      expect(deliver_resp.key?(:insertion)).to be true

      # No log request generated since there's no experiment and we delivered the request.
      expect(deliver_resp[:log_request]).to be nil
    end
  end

  context "enabled" do
    before(:example) do
      @input = Marshal.load(Marshal.dump(SAMPLE_INPUT_CAMEL))
    end

    it "defaults to enabled" do
      client = described_class.new
      expect(client.enabled?).to be true
    end

    it "can be initialized to enabled" do
      client = described_class.new({ :enabled => true })
      expect(client.enabled?).to be true
    end

    it "can be initialized to disabled" do
      client = described_class.new({ :enabled => false })
      expect(client.enabled?).to be false
    end

    it "can be toggled" do
      client = described_class.new
      expect(client.enabled?).to be true
      client.enabled = false
      expect(client.enabled?).to be false
      client.enabled = true
      expect(client.enabled?).to be true
    end

    it "does not deliver when disabled, no paging" do
      client = described_class.new({ :enabled => false })
      resp = client.deliver @input
      expect(client).not_to receive(:send_request)
      expect(resp[:insertion].length).to be 3
      expect(resp[:log_request]).to be nil
    end

    it "does not deliver when disabled, with paging" do
      dup_input = Marshal.load(Marshal.dump(@input))
      dup_input[:request][:paging] = { size: 1, offset: 0 }

      client = described_class.new({ :enabled => false })
      resp = client.deliver dup_input
      expect(client).not_to receive(:send_request)
      expect(resp[:insertion].length).to be 1
      expect(resp[:log_request]).to be nil
    end

    it "preempts prepare_for_logging when disabled" do
      client = described_class.new({ :enabled => false })
      logging_json = client.prepare_for_logging(@input)
      expect(logging_json[:request]).to be nil
    end
  end

  context "cohorts" do
    before(:example) do
      @input = Marshal.load(Marshal.dump(SAMPLE_INPUT_CAMEL))
      @input["experiment"] = {
        "cohortId" => "HOLD_OUT",
        "arm" => "CHANGE ME"
      }
    end

    it "does not deliver for control arm" do
      client = described_class.new
      @input["experiment"]["arm"] = Promoted::Ruby::Client::COHORT_ARM['CONTROL']
      expect(client).not_to receive(:send_request)
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp[:log_request].key?(:insertion)).to be true
      expect(deliver_resp[:log_request].key?(:request)).to be true
      expect(deliver_resp[:log_request].key?(:cohort_membership)).to be true
      expect(deliver_resp.key?(:insertion)).to be true

      # Since we did not deliver, log request should have ids set
      logging_json = deliver_resp[:log_request]
      expect(logging_json[:request].length).to eq 1
      expect(logging_json[:request][0][:request_id]).not_to be nil
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end

    it "does not deliver with custom treatment function" do
      called_with = nil
      should_apply_func = Proc.new do |cohort_membership|
        called_with = cohort_membership
        false
      end

      client = described_class.new({ :should_apply_treatment_func => should_apply_func })

      @input["experiment"]["arm"] = Promoted::Ruby::Client::COHORT_ARM['TREATMENT']
      expect(client).not_to receive(:send_request)
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp[:log_request].key?(:insertion)).to be true
      expect(deliver_resp[:log_request].key?(:request)).to be true
      expect(deliver_resp[:log_request].key?(:cohort_membership)).to be true
      expect(deliver_resp.key?(:insertion)).to be true
      
      expect(called_with[:arm]).to eq @input["experiment"]["arm"]
      expect(called_with.key?(:timing)).to be true
      expect(called_with.key?(:user_info)).to be true

      # Since we did not deliver, log request should have ids set
      logging_json = deliver_resp[:log_request]
      expect(logging_json[:request].length).to eq 1
      expect(logging_json[:request][0][:request_id]).not_to be nil
      logging_json[:insertion].each do |insertion|
        expect(insertion[:request_id]).not_to be nil
      end
    end

    it "does deliver for treatment arm" do
      full_insertion = @input[:fullInsertion]
      client = described_class.new
      @input["experiment"]["arm"] = Promoted::Ruby::Client::COHORT_ARM['TREATMENT']
      expect(client).to receive(:send_request).and_return({
        :insertion => full_insertion
      })
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp[:log_request].key?(:insertion)).to be false
      expect(deliver_resp[:log_request].key?(:request)).to be false
      expect(deliver_resp[:log_request].key?(:cohort_membership)).to be true
      expect(deliver_resp.key?(:insertion)).to be true
    end

    it "does deliver with custom treatment function" do
      called_with = nil
      should_apply_func = Proc.new do |cohort_membership|
        called_with = cohort_membership
        true
      end

      full_insertion = @input[:fullInsertion]

      client = described_class.new({ :should_apply_treatment_func => should_apply_func })

      @input["experiment"]["arm"] = Promoted::Ruby::Client::COHORT_ARM['CONTROL']
      expect(client).to receive(:send_request).and_return({
        :insertion => full_insertion
      })
      deliver_resp = client.deliver @input
      expect(deliver_resp).not_to be nil
      expect(deliver_resp[:log_request].key?(:insertion)).to be false
      expect(deliver_resp[:log_request].key?(:request)).to be false
      expect(deliver_resp[:log_request].key?(:cohort_membership)).to be true
      expect(deliver_resp.key?(:insertion)).to be true

      expect(called_with[:arm]).to eq @input["experiment"]["arm"]
      expect(called_with.key?(:timing)).to be true
      expect(called_with.key?(:user_info)).to be true
    end
  end

  context "prepare_for_logging when user defined method is passed" do
    let!(:to_compact_metrics_insertion_func) do
      Proc.new do |insertion|
        insertion[:properties].delete(:invites_required)
        insertion[:properties].delete(:should_discount_addons)
        insertion[:properties].delete(:total_uses)
        insertion[:properties].delete(:is_archived)
        insertion
      end
    end
    let!(:input_with_prop) do
      input_with_prop = Hash[SAMPLE_INPUT_WITH_PROP]
      input_with_prop[:to_compact_metrics_insertion_func] = to_compact_metrics_insertion_func
      input_with_prop
    end

    it "should take proc from input and delete the property values accordingly" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        expect(insertion[:properties].key?(:invites_required)).to be false
        expect(insertion[:properties].key?(:should_discount_addons)).to be false
        expect(insertion[:properties].key?(:total_uses)).to be false
        expect(insertion[:properties].key?(:is_archived)).to be false
      end
    end

    it "should take proc from input but should not delete the property values that are not included in proc" do
      client = described_class.new ENDPOINTS
      logging_json = client.prepare_for_logging(input_with_prop)
      logging_json[:insertion].each do |insertion|
        # some_property_1 is nil so it gets stripped from the compacted insertions.
        expect(insertion[:properties].key?(:some_property_1)).to be false

        expect(insertion[:properties].key?(:some_property_2)).to be true
        expect(insertion[:properties].key?(:last_used_at)).to be true
        expect(insertion[:properties].key?(:last_purchase_at)).to be true
      end
    end
  end
end
