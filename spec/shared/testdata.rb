SAMPLE_INPUT =  {
  request: {
    user_info: {user_id:  "912", log_user_id:  "91232"},
    device: {
      device_type: "DESKTOP",
      ip_address: "127.0.0.1",
      browser: {
        user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
      }
    },
    use_case: "FEED",
    properties: {
      struct: {
        query: {}
      }
    }
  },
  full_insertion: [
    {
      content_id: "5b4a6512326bd9777abfabc34",
      properties: []
    },
    {
      content_id: "5b4a6512326bd9777abfabea",
      properties: []
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: []
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: []
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: []
    }
  ]
}.freeze

SAMPLE_INPUT_WITH_PROP =  {
  request: {
    user_info: {user_id:  "912", log_user_id:  "91232"},
    device: {
      device_type: "DESKTOP",
      ip_address: "127.0.0.1",
      browser: {
        user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
      }
    },
    use_case: "FEED",
    properties: {
      struct: {
        query: {}
      }
    }
  },
  full_insertion: [
    {
      content_id: "5b4a6512326bd9777abfabc34",
      properties: {
        struct: {
          invites_required: 0,
          should_discount_addons: false,
          total_uses: 738,
          is_archived: false,
          non_combinable: false,
          last_used_at: "2021-05-24T22:35:31.149Z",
          last_purchase_at: "2021-05-24T22:35:31.214Z",
          some_property_1: nil,
          some_property_2: "some value..."
        }
      }
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: {
        struct: {
          invites_required: 0,
          should_discount_addons: false,
          total_uses: 738,
          is_archived: false,
          non_combinable: false,
          last_used_at: "2021-05-24T22:35:31.149Z",
          last_purchase_at: "2021-05-24T22:35:31.214Z",
          some_property_1: nil,
          some_property_2: "some value..."
        }
      }
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: {
        struct: {
          invites_required: 0,
          should_discount_addons: false,
          total_uses: 738,
          is_archived: false,
          non_combinable: false,
          last_used_at: "2021-05-24T22:35:31.149Z",
          last_purchase_at: "2021-05-24T22:35:31.214Z",
          some_property_1: nil,
          some_property_2: "some value..."
        }
      }
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: {
        struct: {
          invites_required: 0,
          should_discount_addons: false,
          total_uses: 738,
          is_archived: false,
          non_combinable: false,
          last_used_at: "2021-05-24T22:35:31.149Z",
          last_purchase_at: "2021-05-24T22:35:31.214Z",
          some_property_1: nil,
          some_property_2: "some value..."
        }
      }
    },
    {
      content_id: "5b4a6512326bd9777abfabcf",
      properties: {
        struct: {
          invites_required: 0,
          should_discount_addons: false,
          total_uses: 738,
          is_archived: false,
          non_combinable: false,
          last_used_at: "2021-05-24T22:35:31.149Z",
          last_purchase_at: "2021-05-24T22:35:31.214Z",
          some_property_1: nil,
          some_property_2: "some value..."
        }
      }
    }
  ]
}.freeze

SAMPLE_INPUT_CAMEL = {
  "request": {
    "userInfo": {
      "logUserId": "logUserId1"
    },
    "device": {
      "deviceType": "DESKTOP",
      "ipAddress": "127.0.0.1",
      "browser": {
        "userAgent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
      }
    },
    "useCase": "FEED",
    "properties": {
      "struct": {
        "query": "fakequery"
      }
    }
  },
  "fullInsertion": [
    {
      "contentId": "product3",
      "properties": {
        "struct": {
          "product": {
            "id": "product3",
            "title": "Product 3",
            "url": "www.mymarket.com/p/3"
          }
        }
      }
    },
    {
      "contentId": "product2",
      "properties": {
        "struct": {
          "product": {
            "id": "product2",
            "title": "Product 2",
            "url": "www.mymarket.com/p/2"
          }
        }
      }
    },
    {
      "contentId": "product1",
      "properties": {
        "struct": {
          "product": {
            "id": "product1",
            "title": "Product 1",
            "url": "www.mymarket.com/p/1"
          }
        }
      }
    }
  ]
}.freeze
