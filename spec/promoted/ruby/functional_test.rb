require 'spec_helper'

ENDPOINTS = { :delivery_endpoint => "http://localhost:3000/delivery", :metrics_endpoint => "http://localhost:3000/metrics" } 

RSpec.describe Promoted::Ruby::Client::PromotedClient do

    it "runs the readme example" do
        products = [
            {
              id: "123",
              type: "SHOE",
              name: "Blue shoe",
              total_sales: 1000
            },
            {
              id: "124",
              type: "SHIRT",
              name: "Green shirt",
              total_sales: 800
            },
            {
              id: "125",
              type: "DRESS",
              name: "Red dress",
              total_sales: 1200
            }
        ]
          
        # Transform them into an [] of Insertions.
        insertions = products.map { |product| {
            :content_id => product[:id],
            :properties => {
                :struct => {
                    :type => product[:type],
                    :name => product[:name]
                    # etc
                }
            }
            }
        }

        # Form a MetricsRequest
        metrics_request = {
            :request => {
            :user_info => { :user_id => "912", :log_user_id => "912191"},
            :use_case => "FEED",
            :paging => {
                :offset => 0,
                :size => 5
            },
            :properties => {
                :struct => {
                :active => true
                }
            },
            :insertion => insertions
            },
            :only_log => true
        }

        client = described_class.new(ENDPOINTS)

        # Build a log request
        client_response = client.deliver(metrics_request)
        log_request = client_response[:log_request]

        client.send_log_request log_request
        
        # Form a DeliveryRequest
        delivery_request = {
            :request => {
            :user_info => { :user_id => "912", :log_user_id => "912191"},
            :use_case => "FEED",
            :paging => {
                :offset => 0,
                :size => 5
            },
            :properties => {
                :struct => {
                :active => true
                }
            },
            :insertion => insertions,
            },
            :only_log => false
        }
  
        # Request insertions from Delivery API
        client_response = client.deliver(delivery_request)

        pp client_response
    end
end
