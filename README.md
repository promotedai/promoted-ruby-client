# promoted-ruby-client

Ruby client designed for calling Promoted's Delivery and Metrics API.

More information at [http://www.promoted.ai](http://www.promoted.ai)

## Installation
```gem 'promoted-ruby-client'```

## Local Development
1. Clone or fork the repo on your local machine
2. `cd promoted-ruby-client`
3. `bundle`
4. To test interactively: `irb -Ilib -rpromoted/ruby/client`

## Dependencies

### [Faraday](https://github.com/lostisland/faraday)
HTTP client for calling Promoted.
### [Concurrent Ruby](https://github.com/ruby-concurrency/concurrent-ruby)
Provides a thread pool for making shadow traffic requests to Delivery API in the background on a subset of calls to ```prepare_for_logging```
## Creating a Client
```rb
client = Promoted::Ruby::Client::PromotedClient.new
```

This client will suffice for building log requests. To send actually send traffing to the API, some configuration is required.

```rb
client = Promoted::Ruby::Client::PromotedClient.new({
  :metrics_endpoint => "https://<get this from Promoted>",
  :delivery_endpoint => "https://<get this from Promoted>",
  :metrics_api_key => "<get this from Promoted>",
  :delivery_api_key => "<get this from Promoted>"
})
```

### Client Configuration Parameters
Name | Type | Description
---- | ---- | -----------
```:delivery_endpoint``` | String | POST URL for the Promoted Delivery API (get this from Promoted)
```:metrics_endpoint``` | String | POST URL for the Promoted Metrics API (get this from Promoted)
```:metrics_api_key``` | String | Used as the ```x-api-key``` header on Metrics API requests to Promoted (get this value from Promoted)
```:delivery_api_key``` | String | Used as the ```x-api-key``` header on Delivery API requests to Promoted (get this value from Promoted)
```:delivery_timeout_millis``` | Number | Timeout on the Delivery API call. Defaults to 3000.
```:metrics_timeout_millis``` | Number | Timeout on the Metrics API call. Defaults to 3000.
```:perform_checks``` | Boolean | Whether or not to perform detailed input validation, defaults to true but may be disabled for performance
```:logger``` | Ruby Logger-compatible logger | Defaults to nil (no logging). Example: ```Logger.new(STDERR, :progname => 'promotedai')```
```:shadow_traffic_delivery_percent``` | Number between 0 and 1 | % of ```prepare_for_logging``` traffic that gets directed to Delivery API as "shadow traffic". Defaults to 0 (no shadow traffic).
```:default_request_headers``` | Hash | Additional headers to send on the request beyond ```x-api-key```. Defaults to {}
```:default_only_log``` | Boolean | If true, the ```deliver``` method will not direct traffic to Delivery API but rather return a request suitable for logging. Defaults to false.
```:should_apply_treatment_func``` | Proc | Called during delivery, accepts an experiment and returns a Boolean indicating whether the request should be considered part of the control group (false) or in the experiment (true). If nil, the default behavior of checking the experiement ```:arm``` is applied.

## Data Types

### UserInfo
Basic information about the request user.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_id``` | String | Yes | The platform user id, cleared from Promoted logs.
```:log_user_id``` | String | Yes | A different user id (presumably a UUID) disconnected from the platform user id, good for working with unauthenticated users or implementing right-to-be-forgotten.

---
### CohortMembership
Useful fields for experimentation during the delivery phase.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_info``` | UserInfo | Yes | The user info structure.
```:arm``` | String | Yes | 'CONTROL' or one of the TREATMENT values (see [constants.rb](https://github.com/promotedai/promoted-ruby-client/blob/main/lib/promoted/ruby/client/constants.rb)).
---
### Properties
Properties bag. Has the structure:

```rb
  :struct => {
    :product => {
      "id": "product3",
      "title": "Product 3",
      "url": "www.mymarket.com/p/3"
      # other key-value pairs...
    }
  }
```
---
### Insertion
Content being served at a certain position.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_info``` | UserInfo | Yes | The user info structure.
```:insertion_id``` | String | Yes | Generated by the SDK (*do not set*)
```:request_id``` | String | Yes | Generated by the SDK (*do not set*)
```:content_id``` | String | No | Identifier for the content to be shown, must be set.
```:properties``` | Properties | Yes | Any additional custom properties to associate. For v1 integrations, it is fine not to fill in all the properties.

---
### Paging
#### TODO
---
### Request
A request for content insertions.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_info``` | UserInfo | Yes | The user info structure.
```:request_id``` | String | Yes | Generated by the SDK (*do not set*)
```:use_case``` | String | Yes | One of the use case values, i.e. 'FEED' (see [constants.rb](https://github.com/promotedai/promoted-ruby-client/blob/main/lib/promoted/ruby/client/constants.rb)).
```:properties``` | Properties | Yes | Any additional custom properties to associate.
```:paging``` | Paging | Yes | Paging parameters (see TODO)
---
### MetricsRequest
Input to ```prepare_for_logging```
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:request``` | Request | No | The underlying request for content.
```:full_insertion``` | [] of Insertion | No | The proposed list of insertions.
---

### DeliveryRequest
Input to ```deliver```
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:experiment``` | CohortMembership | Yes | A cohort to evaluation in experimentation.
```:request``` | Request | No | The underlying request for content.
```:full_insertion``` | [] of Insertion | No | The proposed list of insertions with all metadata, will be compacted before forwarding to Promoted.
```:only_log``` | Boolean | Yes | Defaults to false. Set to true to override whether Delivery API is called for this request.
---

### LogRequest

Output of ```prepare_for_logging``` as well as an ouput of an SDK call to ```deliver```, input to ```send_log_request``` to log to Promoted
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:request``` | Request | No | The underlying request for content to log.
```:insertion``` | [] of Insertion | No | The insertions, which are either the original request insertions or the insertions resulting from a call to ```deliver``` if such call occurred.
---

### ClientResponse
Output of ```deliver```, includes the insertions as well as a suitable ```LogRequest``` for forwarding to Metrics API.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:insertion``` | [] of Insertion | No | The insertions, which are from Delivery API (when ```deliver``` was called, i.e. we weren't either only-log or part of an experiment) or the input insertions (when the other conditions don't hold).
```:log_request``` | LogRequest | Yes | A message suitable for logging to Metrics API via ```send_log_request```. If the call to ```deliver``` was made (i.e. the request was not part of the CONTROL arm of an experiment or marked to only log), ```:log_request``` will not be set, as you can assume logging was performed on the server-side by Promoted.
---

### PromotedClient
Method | Input | Output | Description
------ | ----- | ------ | -----------
```prepare_for_logging``` | MetricsRequest | LogRequest | Builds a request suitable for logging locally and/or to Promoted, either via a subsequent call to ```send_log_request``` in the SDK client or by using this structure to make the call yourself. Optionally, based on client configuration may send a random subset of requests to Delivery API as shadow traffic for integration purposes.
```send_log_request``` | LogRequest | n/a | Forwards a LogRequest to Promoted using an HTTP client.
```deliver``` | DeliveryRequest | ClientResponse | Makes a request (subject to experimentation) to Delivery API for insertions, which are then returned along with a LogRequest.
```close``` | n/a | n/a | Closes down the client at shutdown, currently this is just to drain the thread pool that handles shadow traffic.
---

## Metrics API
### Pagination

The `prepare_for_logging` call assumes the client has already handled pagination.  It needs a `Request.paging.offset` to be passed in for the number of items deep that the page is.
TODO: Needs more details.

### Expected flow for Metrics logging

```rb
# Retrieve a list of content (i.e. products)
# products = fetch_my_marketplace_products()

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
  :full_insertion => insertions
}

# OPTIONAL: You can pass a custom function to "compact" insertions before metrics logging.
# Note that the PromotedClient has a class method helper, copy_and_remove_properties, that does just this.
to_compact_metrics_insertion_func = Proc.new do |insertion|
  insertion.delete(:properties)
  insertion
end
# metrics_request[:to_compact_metrics_insertion_func] = to_compact_metrics_insertion

# Create a client
client = Promoted::Ruby::Client::PromotedClient.new

# Build a log request
log_request = client.prepare_for_logging(metrics_request)

# Log (assuming you have configured your client with a :metrics_endpoint)
client.send_log_request(log_request)
```

## Delivery API

### Expected flow for Delivery

```rb
# (continuing from the above example for Metrics)

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
    }
  },
  :full_insertion => insertions,
  :only_log => false
}

# Request insertions from Delivery API
client_response = client.deliver(delivery_request)

# Use the resulting insertions
client_response[:insertion]

# Log if a log request was provided (if not, deliver was called successfully
# and Promoted logged on the server-side).)
client.send_log_request(client_response[:log_request]) if client_response[:log_request]
```

### TODO Experimentation example
