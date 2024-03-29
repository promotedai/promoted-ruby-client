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
### [Net::HTTP::Persistent](https://github.com/drbrain/net-http-persistent)
Faraday binding (provides connection pool support)
### [Concurrent Ruby](https://github.com/ruby-concurrency/concurrent-ruby)
Provides a thread pool for making shadow traffic requests to Delivery API in the background on a subset of calls to ```deliver```
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
```:shadow_traffic_delivery_percent``` | Number between 0 and 1 | % of ```deliver``` traffic that gets directed to Delivery API as "shadow traffic". Defaults to 0 (no shadow traffic).
```:send_shadow_traffic_for_control``` | Boolean | If true, the ```deliver``` method will send shadow traffic for users in the CONTROL arm of an experiment. Defaults to true.
```:default_request_headers``` | Hash | Additional headers to send on the request beyond ```x-api-key```. Defaults to {}
```:default_only_log``` | Boolean | If true, the ```deliver``` method will not direct traffic to Delivery API but rather return a request suitable for logging. Defaults to false.
```:should_apply_treatment_func``` | Proc | Called during delivery, accepts an experiment and returns a Boolean indicating whether the request should be considered part of the control group (false) or in the experiment (true). If nil, the default behavior of checking the experiement ```:arm``` is applied.
```:warmup``` | Boolean | If true, the client will prime the `Net::HTTP::Persistent` connection pool on construction; this can make the first few calls to Promoted complete faster. Defaults to false.
```:max_request_insertions``` | Number | Maximum number of request insertions that will be passed to Delivery API on a single request (any more will be truncated by the SDK). Defaults to 1000.  

## Data Types

### UserInfo
Basic information about the request user.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_id``` | String | Yes | The platform user id, cleared from Promoted logs.
```:anon_user_id``` | String | Yes | A different user id (presumably a UUID) disconnected from the platform user id, good for working with unauthenticated users or implementing right-to-be-forgotten.
```:is_internal_user``` | Boolean | Yes | If this user is a test user or not, defaults to false.
```:ignore_usage``` | Boolean | Yes | If you want to ignore usage from this user, defaults to false.

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
```:request_id``` | String | Yes | Generated by the SDK when needed (*do not set*)
```:content_id``` | String | No | Identifier for the content to be shown, must be set.
```:retrieval_rank``` | Number | Yes | Optional original ranking of this content item.
```:retrieval_score``` | Number | Yes | Optional original quality score of this content item.
```:properties``` | Properties | Yes | Any additional custom properties to associate. For v1 integrations, it is fine not to fill in all the properties.
---
### Size
User's screen dimensions.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:width``` | Integer | No | Screen width
```:height``` | Integer | No | Screen height
---

### Screen
State of the screen including scaling.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:size``` | Size | Yes | Screen size
```:scale``` | Float | Yes | Current screen scaling factor
---

### ClientHints
Alternative to user-agent strings. See https://raw.githubusercontent.com/snowplow/iglu-central/master/schemas/org.ietf/http_client_hints/jsonschema/1-0-0
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:is_mobile``` | Boolean | Yes | Mobile flag
```:brand``` | Array of ClientBrandHint | Yes |
```:architecture``` | String | Yes |
```:model``` | String | Yes |
```:platform``` | String | Yes |
```:platform_version``` | String | Yes |
```:ua_full_version``` | String | Yes |

---
### ClientBrandHint
See https://raw.githubusercontent.com/snowplow/iglu-central/master/schemas/org.ietf/http_client_hints/jsonschema/1-0-0
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:brand``` | String | Yes | Mobile flag
```:version``` | String | Yes |

---
### Location
Information about the user's location.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:latitude``` | Float | No | Location latitude
```:longitude``` | Float | No | Location longitude
```:accuracy_in_meters``` | Integer | Yes | Location accuracy if available
---

### Browser
Information about the user's browser.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_agent``` | String | Yes | Browser user agent string
```:viewport_size``` | Size | Yes | Size of the browser viewport
```:client_hints``` | ClientHints | Yes | HTTP client hints structure
```referrer``` | String | Yes | Request referrer
---
### Device
Information about the user's device.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:device_type``` | one of (`UNKNOWN_DEVICE_TYPE`, `DESKTOP`, `MOBILE`, `TABLET`) | Yes | Type of device
```:brand``` | String | Yes | "Apple, "google", Samsung", etc.
```:manufacturer``` | String | Yes | "Apple", "HTC", Motorola", "HUAWEI", etc.
```:identifier``` | String | Yes | Android: android.os.Build.MODEL; iOS: iPhoneXX,YY, etc.
```:screen``` | Screen | Yes | Screen dimensions
```:ip_address``` | String | Yes | Originating IP address
```:location``` | Location | Yes | Location information
```:browser``` | Browser | Yes | Browser information
---
### Paging
Paging parameters.

```DeliveryRequest.retrieval_insertion_offset``` also impacts paging.  That field indicate the offset of the retrieved insertions that are passed into ```Request.insertion```.  See [detailed documentation on paging and ```retrieval_insertion_offset```](https://docs.promoted.ai/docs/ranking-requests#sending-even-more-request-insertions).

Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:offset``` | Integer | Yes | The 0-based, starting index for the response page.  This should be the global position.
```:size``` | Integer | Yes | The number of items to return in a response page.
---
### Request
A request for content insertions.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:user_info``` | UserInfo | Yes | The user info structure.
```:request_id``` | String | Yes | Generated by the SDK when needed (*do not set*)
```:use_case``` | String | Yes | One of the use case values, i.e. 'FEED' (see [constants.rb](https://github.com/promotedai/promoted-ruby-client/blob/main/lib/promoted/ruby/client/constants.rb)).
```:properties``` | Properties | Yes | Any additional custom properties to associate.
```:paging``` | Paging | Yes | Paging parameters
```:device``` | Device | Yes | Device information (as available)
```:disable_personalization``` | Boolean | Yes | If true, disables personalized inputs into Delivery algorithm.

---

### DeliveryRequest
Input to ```deliver```
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:experiment``` | CohortMembership | Yes | A cohort to evaluation in experimentation.
```:request``` | Request | No | The underlying request for content.
```:only_log``` | Boolean | Yes | Defaults to false. Set to true to override whether Delivery API is called for this request.
```:retrieval_insertion_offset``` | Integer | Yes | The index of the retrieved insertions set on ```Request.insertion``` list.  If just sending the top-N from your retrieval, this is ```0```.  If this is the next batch (e.g. ```500``` to ```999```), then the value is ```500```.  This can be used to send multiple groups of retrieved insertions.  This interacts with the ```Paging``` fields.  [More detailed documentation on paging](https://docs.promoted.ai/docs/ranking-requests#sending-even-more-request-insertions).
---

### LogRequest

A log object that is sent as a RPC request to Promoted's Metrics API log endpoint.  This is outputted from the ```deliver``` SDK call.  Callers need to either input it into the ```send_log_request``` method or send it to the Metrics API directly.  Clients should avoid manipulating this object directly.
---

### ClientResponse
Output of ```deliver```, includes the insertions as well as a suitable ```LogRequest``` for forwarding to Metrics API.
Field Name | Type | Optional? | Description
---------- | ---- | --------- | -----------
```:insertion``` | [] of Insertion | No | The paged insertions, which are from Delivery API (when ```deliver``` was called, i.e. we weren't either only-log or part of an experiment) or the input insertions (when the other conditions don't hold).
```:log_request``` | LogRequest | Yes | A message suitable for logging to Metrics API via ```send_log_request```. If the call to ```deliver``` was made (i.e. the request was not part of the CONTROL arm of an experiment or marked to only log), ```:log_request``` will not be set, as you can assume logging was performed on the server-side by Promoted.
```:client_request_id``` | String | Yes | Client-generated request id sent to Delivery API and may be useful for logging and debugging.
```:execution_server``` | one of 'API' or 'SDK' | Yes | Indicates if response insertions on a delivery request came from the API or the SDK.
---

### PromotedClient
Method | Input | Output | Description
------ | ----- | ------ | -----------
```send_log_request``` | LogRequest | n/a | Forwards a LogRequest to Promoted using an HTTP client.
```deliver``` | DeliveryRequest | ClientResponse | Depending on flags, either (1) makes a request (subject to experimentation) to Delivery API for insertions, which are then returned along with a LogRequest or (2) implements SDK-side paging and prepares log records that can be logged to Promoted using ```send_log_request``` or by using this structure to make the call yourself. Optionally, based on client configuration may send a random subset of requests to Delivery API as shadow traffic for integration purposes.
```close``` | n/a | n/a | Closes down the client at shutdown, currently this is just to drain the thread pool that handles shadow traffic.
---

## Metrics API
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
    :user_info => { :user_id => "912", :anon_user_id => "912191"},
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
  :only_log => true,
}

# Create a client
client = Promoted::Ruby::Client::PromotedClient.new

# Build a log request
client_response = client.deliver(metrics_request)

# Log (assuming you have configured your client with a :metrics_endpoint)
client.send_log_request(client_response[:log_request]) if client_response[:log_request]
```

## Delivery API

### Expected flow for Delivery

```rb
# (continuing from the above example for Metrics)

# Form a DeliveryRequest
delivery_request = {
  :request => {
    :user_info => { :user_id => "912", :anon_user_id => "912191"},
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

# Use the resulting insertions
client_response[:insertion]

# Log if a log request was provided (if not, deliver was called successfully
# and Promoted logged on the server-side).)
client.send_log_request(client_response[:log_request]) if client_response[:log_request]
```

### TODO Experimentation example
