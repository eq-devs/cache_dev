import 'dart:convert';

/// The real `Jana Post` orders API response used by the benchmark, decoded once
/// from its JSON form. Kept as a raw JSON string so it matches a real network
/// payload exactly (no hand-transcription into Dart literals).
final Map<String, dynamic> kSampleApiResponse =
    jsonDecode(_sampleApiResponseJson) as Map<String, dynamic>;

const String _sampleApiResponseJson = r'''
{
  "success": true,
  "code": 200,
  "message": "OK",
  "trace_id": "tr_20260529_0019283746",
  "timestamp": "2026-05-29T16:42:18+05:00",
  "api_version": "v2.8.4",
  "environment": "production",
  "request": {
    "client": {
      "platform": "android",
      "app_name": "Jana Post",
      "app_version": "3.12.0",
      "build_number": 31200,
      "device": {
        "brand": "Samsung",
        "model": "Galaxy A51",
        "os": "Android",
        "os_version": "13",
        "ram_mb": 4096,
        "storage_free_mb": 28432,
        "locale": "zh-CN",
        "timezone": "Asia/Almaty"
      }
    },
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 128,
      "has_next": true,
      "next_cursor": "eyJwYWdlIjoyLCJ0cyI6MTc0ODUxMjkzOH0="
    },
    "filters": {
      "country": "KZ",
      "statuses": [
        "pending",
        "in_stock",
        "on_road",
        "branch",
        "ready_to_pick_up"
      ],
      "date_range": {
        "from": "2026-05-01",
        "to": "2026-05-29"
      },
      "sort": {
        "field": "updated_at",
        "direction": "desc"
      }
    }
  },
  "data": {
    "user": {
      "id": 10092837,
      "uuid": "usr_7f21a9d3_9b43_4e3a_a7d1_2c82f90d0011",
      "phone": "+77071234567",
      "email": "user@example.com",
      "full_name": "Test User",
      "language": "zh",
      "country": "KZ",
      "city": "Almaty",
      "branch": {
        "id": 12,
        "name": "Almaty Dostyk Branch",
        "address": {
          "country": "Kazakhstan",
          "city": "Almaty",
          "district": "Medeu",
          "street": "Dostyk Avenue",
          "building": "128",
          "floor": 1,
          "geo": {
            "lat": 43.238949,
            "lng": 76.889709
          }
        },
        "working_hours": [
          {
            "day": "monday",
            "open": "09:00",
            "close": "19:00",
            "break": null
          },
          {
            "day": "tuesday",
            "open": "09:00",
            "close": "19:00",
            "break": null
          },
          {
            "day": "wednesday",
            "open": "09:00",
            "close": "19:00",
            "break": null
          },
          {
            "day": "thursday",
            "open": "09:00",
            "close": "19:00",
            "break": null
          },
          {
            "day": "friday",
            "open": "09:00",
            "close": "19:00",
            "break": null
          },
          {
            "day": "saturday",
            "open": "10:00",
            "close": "17:00",
            "break": {
              "from": "13:00",
              "to": "14:00"
            }
          },
          {
            "day": "sunday",
            "open": null,
            "close": null,
            "break": null
          }
        ]
      },
      "membership": {
        "level": "gold",
        "points": 8420,
        "next_level": "platinum",
        "required_points": 15000,
        "benefits": [
          "priority_support",
          "discounted_delivery",
          "early_price_drop_alerts"
        ]
      },
      "settings": {
        "push_notifications": true,
        "sms_notifications": false,
        "email_notifications": true,
        "currency": "KZT",
        "theme": "system",
        "privacy": {
          "analytics_enabled": true,
          "personalized_recommendations": true,
          "location_tracking": false
        }
      }
    },
    "summary": {
      "orders_total": 128,
      "orders_by_status": {
        "pending": 17,
        "in_stock": 31,
        "on_road": 42,
        "branch": 26,
        "ready_to_pick_up": 12,
        "cancelled": 0
      },
      "financial": {
        "total_declared_value": {
          "amount": 2489123.45,
          "currency": "KZT"
        },
        "total_delivery_fee": {
          "amount": 183420.0,
          "currency": "KZT"
        },
        "unpaid_amount": {
          "amount": 32450.75,
          "currency": "KZT"
        }
      },
      "weight": {
        "total_kg": 386.72,
        "average_kg": 3.02,
        "max_kg": 28.4
      }
    },
    "orders": [
      {
        "id": 91827364,
        "order_no": "JP-KZ-20260529-0001",
        "external_order_no": "TB881234998712",
        "marketplace": {
          "id": "taobao",
          "name": "Taobao",
          "country": "CN",
          "logo_url": "https://cdn.example.com/marketplaces/taobao.png"
        },
        "status": "ready_to_pick_up",
        "status_text": {
          "zh": "可取件",
          "ru": "Готово к выдаче",
          "kk": "Алуға дайын",
          "en": "Ready to Pick Up"
        },
        "created_at": "2026-05-18T11:24:09+05:00",
        "updated_at": "2026-05-29T15:18:42+05:00",
        "estimated_arrival": "2026-05-29",
        "customer": {
          "id": 10092837,
          "name": "Test User",
          "phone": "+77071234567"
        },
        "receiver": {
          "name": "Test User",
          "phone": "+77071234567",
          "document_required": true,
          "pickup_code": "394812"
        },
        "route": {
          "from": {
            "country": "CN",
            "city": "Guangzhou",
            "warehouse": "GZ-WH-03"
          },
          "to": {
            "country": "KZ",
            "city": "Almaty",
            "branch_id": 12
          },
          "steps": [
            {
              "status": "created",
              "title": "Order created",
              "location": "Online",
              "time": "2026-05-18T11:24:09+05:00"
            },
            {
              "status": "warehouse_received",
              "title": "Received at China warehouse",
              "location": "Guangzhou",
              "time": "2026-05-20T09:14:33+08:00"
            },
            {
              "status": "customs_export",
              "title": "Export customs processing",
              "location": "China",
              "time": "2026-05-22T18:02:10+08:00"
            },
            {
              "status": "on_road",
              "title": "On road to Kazakhstan",
              "location": "International route",
              "time": "2026-05-24T06:40:00+08:00"
            },
            {
              "status": "branch",
              "title": "Arrived at branch",
              "location": "Almaty Dostyk Branch",
              "time": "2026-05-29T12:45:17+05:00"
            },
            {
              "status": "ready_to_pick_up",
              "title": "Ready to pick up",
              "location": "Almaty Dostyk Branch",
              "time": "2026-05-29T15:18:42+05:00"
            }
          ]
        },
        "items": [
          {
            "sku": "SKU-8812-A",
            "title": "Wireless Keyboard",
            "title_original": "无线键盘",
            "category": {
              "id": 501,
              "name": "Electronics",
              "path": [
                "Electronics",
                "Computer Accessories",
                "Keyboard"
              ]
            },
            "quantity": 1,
            "price": {
              "amount": 89.9,
              "currency": "CNY"
            },
            "declared_price": {
              "amount": 5900,
              "currency": "KZT"
            },
            "images": [
              {
                "url": "https://cdn.example.com/items/keyboard_1.jpg",
                "width": 800,
                "height": 800,
                "primary": true
              },
              {
                "url": "https://cdn.example.com/items/keyboard_2.jpg",
                "width": 800,
                "height": 800,
                "primary": false
              }
            ],
            "attributes": {
              "color": "black",
              "layout": "US",
              "connection": "Bluetooth",
              "battery": "rechargeable"
            }
          },
          {
            "sku": "SKU-7721-B",
            "title": "Phone Case",
            "title_original": "手机壳",
            "category": {
              "id": 602,
              "name": "Accessories",
              "path": [
                "Electronics",
                "Mobile Accessories",
                "Cases"
              ]
            },
            "quantity": 2,
            "price": {
              "amount": 19.5,
              "currency": "CNY"
            },
            "declared_price": {
              "amount": 2600,
              "currency": "KZT"
            },
            "images": [
              {
                "url": "https://cdn.example.com/items/case_1.jpg",
                "width": 1000,
                "height": 1000,
                "primary": true
              }
            ],
            "attributes": {
              "color": "transparent",
              "material": "TPU",
              "compatible_model": "iPhone 15 Pro"
            }
          }
        ],
        "package": {
          "tracking_no": "CNKZ9988127733",
          "weight_kg": 2.36,
          "volume": {
            "length_cm": 32,
            "width_cm": 22,
            "height_cm": 12,
            "volume_weight_kg": 1.69
          },
          "dangerous_goods": false,
          "fragile": false,
          "requires_inspection": true,
          "photos": [
            "https://cdn.example.com/packages/CNKZ9988127733/front.jpg",
            "https://cdn.example.com/packages/CNKZ9988127733/label.jpg"
          ]
        },
        "payment": {
          "status": "paid",
          "method": "apple_pay",
          "transaction_id": "pay_20260529_889112",
          "amount": {
            "delivery_fee": 2450,
            "insurance_fee": 0,
            "storage_fee": 0,
            "discount": 250,
            "total": 2200,
            "currency": "KZT"
          },
          "paid_at": "2026-05-29T15:21:02+05:00"
        },
        "alerts": [
          {
            "type": "pickup",
            "priority": "high",
            "title": "Your package is ready",
            "message": "Please pick up your package from Almaty Dostyk Branch.",
            "read": false,
            "created_at": "2026-05-29T15:18:45+05:00"
          }
        ],
        "metadata": {
          "source": "mobile_app",
          "cache_key": "order_JP-KZ-20260529-0001",
          "ttl_seconds": 1800,
          "version": 4,
          "checksum": "sha256:2b4c7e9a02e7fbbfd102884af91d26e77b1f"
        }
      },
      {
        "id": 91827365,
        "order_no": "JP-KZ-20260529-0002",
        "external_order_no": "PDD77382999120",
        "marketplace": {
          "id": "pinduoduo",
          "name": "Pinduoduo",
          "country": "CN",
          "logo_url": "https://cdn.example.com/marketplaces/pinduoduo.png"
        },
        "status": "on_road",
        "status_text": {
          "zh": "运输中",
          "ru": "В пути",
          "kk": "Жолда",
          "en": "On Road"
        },
        "created_at": "2026-05-21T19:12:44+05:00",
        "updated_at": "2026-05-28T22:41:10+05:00",
        "estimated_arrival": "2026-06-02",
        "customer": {
          "id": 10092837,
          "name": "Test User",
          "phone": "+77071234567"
        },
        "receiver": {
          "name": "Test User",
          "phone": "+77071234567",
          "document_required": false,
          "pickup_code": null
        },
        "route": {
          "from": {
            "country": "CN",
            "city": "Yiwu",
            "warehouse": "YW-WH-01"
          },
          "to": {
            "country": "KZ",
            "city": "Almaty",
            "branch_id": 12
          },
          "steps": [
            {
              "status": "created",
              "title": "Order created",
              "location": "Online",
              "time": "2026-05-21T19:12:44+05:00"
            },
            {
              "status": "warehouse_received",
              "title": "Received at China warehouse",
              "location": "Yiwu",
              "time": "2026-05-23T10:02:18+08:00"
            },
            {
              "status": "packed",
              "title": "Package packed",
              "location": "Yiwu Warehouse",
              "time": "2026-05-24T14:30:00+08:00"
            },
            {
              "status": "on_road",
              "title": "On road to Kazakhstan",
              "location": "International route",
              "time": "2026-05-26T08:15:00+08:00"
            }
          ]
        },
        "items": [
          {
            "sku": "PDD-2026-9981",
            "title": "Children Backpack",
            "title_original": "儿童书包",
            "category": {
              "id": 710,
              "name": "Bags",
              "path": [
                "Fashion",
                "Bags",
                "Backpacks"
              ]
            },
            "quantity": 1,
            "price": {
              "amount": 45.8,
              "currency": "CNY"
            },
            "declared_price": {
              "amount": 3100,
              "currency": "KZT"
            },
            "images": [
              {
                "url": "https://cdn.example.com/items/backpack_1.jpg",
                "width": 800,
                "height": 800,
                "primary": true
              }
            ],
            "attributes": {
              "color": "blue",
              "size": "medium",
              "material": "polyester"
            }
          }
        ],
        "package": {
          "tracking_no": "CNKZ8877362910",
          "weight_kg": 1.18,
          "volume": {
            "length_cm": 40,
            "width_cm": 30,
            "height_cm": 9,
            "volume_weight_kg": 1.8
          },
          "dangerous_goods": false,
          "fragile": false,
          "requires_inspection": false,
          "photos": []
        },
        "payment": {
          "status": "unpaid",
          "method": null,
          "transaction_id": null,
          "amount": {
            "delivery_fee": 1800,
            "insurance_fee": 0,
            "storage_fee": 0,
            "discount": 0,
            "total": 1800,
            "currency": "KZT"
          },
          "paid_at": null
        },
        "alerts": [
          {
            "type": "payment",
            "priority": "medium",
            "title": "Payment required",
            "message": "Delivery fee is not paid yet.",
            "read": false,
            "created_at": "2026-05-28T22:45:00+05:00"
          }
        ],
        "metadata": {
          "source": "backend_sync",
          "cache_key": "order_JP-KZ-20260529-0002",
          "ttl_seconds": 900,
          "version": 4,
          "checksum": "sha256:a38f92d17c281bdfa0000c827adfd912a2"
        }
      }
    ],
    "price_tracking": {
      "enabled": true,
      "tracked_products_count": 64,
      "currency": "KZT",
      "products": [
        {
          "id": "prd_001",
          "marketplace": "taobao",
          "url": "https://item.taobao.com/item.htm?id=8812999123",
          "title": "Xiaomi Power Bank 20000mAh",
          "image_url": "https://cdn.example.com/products/powerbank.jpg",
          "current_price": {
            "amount": 109.0,
            "currency": "CNY"
          },
          "original_price": {
            "amount": 149.0,
            "currency": "CNY"
          },
          "lowest_price_30d": {
            "amount": 99.0,
            "currency": "CNY"
          },
          "target_price": {
            "amount": 95.0,
            "currency": "CNY"
          },
          "price_change": {
            "amount": -40.0,
            "percent": -26.85,
            "direction": "down"
          },
          "history": [
            {
              "date": "2026-05-01",
              "price": 149.0
            },
            {
              "date": "2026-05-08",
              "price": 139.0
            },
            {
              "date": "2026-05-15",
              "price": 129.0
            },
            {
              "date": "2026-05-22",
              "price": 119.0
            },
            {
              "date": "2026-05-29",
              "price": 109.0
            }
          ],
          "notification": {
            "price_drop_alert": true,
            "target_price_alert": true,
            "stock_alert": true,
            "last_sent_at": "2026-05-29T10:12:00+05:00"
          },
          "stock": {
            "available": true,
            "quantity": 238,
            "warehouse": "CN"
          }
        }
      ]
    },
    "home_widget": {
      "last_refresh": "2026-05-29T16:41:59+05:00",
      "small": {
        "title": "Order Status",
        "primary_count": 12,
        "primary_label": "Ready to Pick Up",
        "secondary_text": "128 total orders"
      },
      "medium": {
        "title": "订单状态",
        "items": [
          {
            "label": "Pending",
            "count": 17
          },
          {
            "label": "In Stock",
            "count": 31
          },
          {
            "label": "On Road",
            "count": 42
          },
          {
            "label": "Branch",
            "count": 26
          },
          {
            "label": "Ready to Pick Up",
            "count": 12
          }
        ],
        "footer": "Updated at: 16:41"
      },
      "large": {
        "sections": [
          {
            "title": "Need Action",
            "items": [
              {
                "type": "pickup",
                "count": 12,
                "priority": "high"
              },
              {
                "type": "unpaid",
                "count": 6,
                "priority": "medium"
              }
            ]
          },
          {
            "title": "Logistics",
            "items": [
              {
                "type": "on_road",
                "count": 42
              },
              {
                "type": "in_stock",
                "count": 31
              },
              {
                "type": "branch",
                "count": 26
              }
            ]
          }
        ]
      }
    },
    "feature_flags": {
      "apple_pay_enabled": true,
      "google_pay_enabled": true,
      "freedompay_enabled": true,
      "new_order_detail_ui": true,
      "price_tracking_enabled": true,
      "microapp_webview_enabled": true,
      "home_widget_enabled": true,
      "experimental_messagepack_cache": false,
      "adaptive_performance_mode": true
    },
    "performance": {
      "device_level": "medium",
      "config": {
        "image_cache_mb": 128,
        "list_cache_extent": 250,
        "enable_blur": true,
        "enable_heavy_animation": false,
        "target_fps": 60,
        "json_decode_strategy": "isolate",
        "disk_cache_format": "json"
      },
      "metrics": {
        "api_latency_ms": 184,
        "decode_time_ms": 22,
        "memory_cache_hit": true,
        "disk_cache_hit": false,
        "payload_size_bytes": 47218
      }
    }
  },
  "errors": [],
  "warnings": [
    {
      "code": "PAYMENT_REQUIRED",
      "message": "Some orders have unpaid delivery fees.",
      "count": 6
    },
    {
      "code": "PICKUP_PENDING",
      "message": "Some packages are ready to pick up.",
      "count": 12
    }
  ],
  "links": {
    "self": "https://api.example.com/v2/orders?page=1",
    "next": "https://api.example.com/v2/orders?page=2",
    "web": "https://janapost.kz/app/orders"
  },
  "cache": {
    "key": "orders_user_10092837_page_1_v4",
    "ttl_seconds": 1800,
    "created_at": "2026-05-29T16:42:18+05:00",
    "expires_at": "2026-05-29T17:12:18+05:00",
    "stale_while_revalidate_seconds": 600,
    "schema_version": 4
  }
}
''';
