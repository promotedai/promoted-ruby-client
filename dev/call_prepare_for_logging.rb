require "logger"

client = Promoted::Ruby::Client::PromotedClient.new({
    :metrics_endpoint => "http://localhost:3000/metrics",
    :delivery_endpoint => "https://delivery.dev.hipcamp.ext.promoted.ai/deliver",
    :delivery_timeout_millis => 250,
    :shadow_traffic_delivery_percent => 1.0,
    :delivery_api_key => ENV["HIPCAMP_DEV_DELIVERY_API_KEY"],
    :async_shadow_traffic => false,
    :logger => Logger.new(STDERR, :progname => "promotedai")})

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
insertions = products.map { |product| 
    {
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
    }
  },
  :full_insertion => insertions,
  :insertion_page_type => 'UNPAGED'
}

1.upto(20) {|i|
  start = Time.now
  log_request = client.prepare_for_logging(metrics_request)
  puts (Time.now - start).to_f * 1000
  puts log_request
}
