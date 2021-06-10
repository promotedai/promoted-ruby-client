# promoted-ruby-client

Ruby client designed for calling Promoted's Delivery and Metrics API.

This version of the library only supports preparing objects for logging.  TODO - support Delivery API.

## Expected pseudo-code flow for Metrics logging

This example is for the integration where we do not want to modify the list of items to include `insertionId`.  TODO - add this example too.

```
def get_items args
  items = retrieve_items((args))
  async_log_request(items)
  return items
end

# Done async
def log_request items
  log_request = Promoted::Ruby::Client.prepare_for_logging(input)
  # Send JSON to Event API.
  log_to_promoted_event_api(log_request)
end
```

## Example to run the client

1. Clone the repo on your local machine
2. `cd promoted-ruby-client`
3. `bundle`
4. `irb -Ilib -rpromoted/ruby/client`

A console will launch with the library loaded.  Here is example code to use.

```
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

# Converts the Products to a list of Insertions.
def to_insertions products
  @to_insertions = []
  products.each_with_index do |product, index|
    @to_insertions << {
      content_id: product[:id],
      properties: {
        struct: {
          product: product.reject { |k, v| [:id].include? k }
        }
      }
    }
  end
  @to_insertions
end

request_input = {
  request: {
    user_info: { user_id: "912", log_user_id: "912191"},
    use_case: "FEED",
    properties: {
      struct: {
        active: true
      }
    }
  },
  fullInsertion: to_insertions(products)
}

log_request = Promoted::Ruby::Client.prepare_for_logging(request_input)
log_request.to_json
```

`log_request.to_json` returns a result that looks like the following
```
=> "{\"user_info\":{\"user_id\":\"912\",\"log_user_id\":\"912191\"},\"timing\":{\"client_log_timestamp\":1623302267},\"request\":[{\"user_info\":{\"user_id\":\"912\",\"log_user_id\":\"912191\"},\"use_case\":\"FEED\",\"properties\":{\"struct\":{\"active\":true}}}],\"insertion\":[{\"content_id\":\"123\",\"properties\":{\"struct\":{\"product\":{\"type\":\"SHOE\",\"name\":\"Blue shoe\",\"total_sales\":1000}}},\"user_info\":{\"user_id\":\"912\",\"log_user_id\":\"912191\"},\"timing\":{\"client_log_timestamp\":1623302267},\"insertion_id\":\"cf4c3dfb-9e08-4ea2-84b5-c44cc222e686\",\"request_id\":\"f4c5173d-2131-4b97-9c3c-a7cbe37393e9\",\"position\":0},{\"content_id\":\"124\",\"properties\":{\"struct\":{\"product\":{\"type\":\"SHIRT\",\"name\":\"Green shirt\",\"total_sales\":800}}},\"user_info\":{\"user_id\":\"912\",\"log_user_id\":\"912191\"},\"timing\":{\"client_log_timestamp\":1623302267},\"insertion_id\":\"696d0f0b-ec04-4627-8f50-39e7ca632ee0\",\"request_id\":\"f4c5173d-2131-4b97-9c3c-a7cbe37393e9\",\"position\":1},{\"content_id\":\"125\",\"properties\":{\"struct\":{\"product\":{\"type\":\"DRESS\",\"name\":\"Red dress\",\"total_sales\":1200}}},\"user_info\":{\"user_id\":\"912\",\"log_user_id\":\"912191\"},\"timing\":{\"client_log_timestamp\":1623302267},\"insertion_id\":\"71256116-2357-493e-8662-85681f358a94\",\"request_id\":\"f4c5173d-2131-4b97-9c3c-a7cbe37393e9\",\"position\":2}]}"
```

## Other input syntaxes

The client should also work if Hash rocket too.
```
products = [
  {
    "id"=>"123",
    "type"=>"SHOE",
    "name"=>"Blue shoe",
    "totalSales"=>1000
  },
  {
    "id"=>"124",
    "type"=>"SHIRT",
    "name"=>"Green shirt",
    "totalSales"=>800
  },
  {
    "id"=>"125",
    "type"=>"DRESS",
    "name"=>"Red dress",
    "totalSales"=>1200
  }
]

input = {
  "request"=>{
    "user_info"=>{"user_id"=> "912", "log_user_id"=> "912191"},
    "use_case"=>"FEED",
    "properties"=>{
      "struct"=>{
        "active"=>true
      }
    }
  },
  "fullInsertion"=>to_insertions(products)
}
```

Or inlined full request.
```
input = {
  "request"=>{
    "user_info"=>{"user_id"=> "912", "log_user_id"=> "912191"},
    "use_case"=>"FEED",
    "properties"=>{
      "struct"=>{
        "active"=>true
      }
    }
  },
  "fullInsertion"=>[
    {
      "contentId"=>"123",
      "properties"=>{
        "struct"=>{
          "product"=>{
            "type"=>"SHOE",
            "name"=>"Blue shoe",
            "totalSales"=>1000
          }
        }
      }
    },
    {
      "contentId"=>"124",
      "properties"=>{
        "struct"=>{
          "product"=>{
            "type"=>"SHIRT",
            "name"=>"Green shirt",
            "totalSales"=>800
          }
        }
      }
    },
    {
      "contentId"=>"125",
      "properties"=>{
        "struct"=>{
          "product"=>{
            "type"=>"DRESS",
            "name"=>"Red dress",
            "totalSales"=>1200
          }
        }
      }
    }
  ]
}
```