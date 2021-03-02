
## Index Lifecycle Policy

```
PUT _ilm/policy/logs-container-kubernetes
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "32gb"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "delete": {
        "min_age": "7d",
        "actions": {
          "delete": {
            "delete_searchable_snapshot": true
          }
        }
      }
    }
  }
}
```

## Template

```
PUT _index_template/logs-container-kubernetes
{
  "template": {
    "settings": {
      "index": {
        "lifecycle": {
          "name": "logs-container-kubernetes"
        },
        "number_of_shards": "1",
        "number_of_replicas": "0",
        "refresh_interval": "10s"
      }
    },
    "mappings": {
      "_routing": {
        "required": false
      },
      "numeric_detection": false,
      "dynamic_date_formats": [
        "strict_date_optional_time",
        "yyyy/MM/dd HH:mm:ss Z||yyyy/MM/dd Z"
      ],
      "dynamic": true,
      "_source": {
        "enabled": false
      },
      "dynamic_templates": [
        {
          "kubernetes_fields_as_keywords": {
            "path_match": "kubernetes.*",
            "mapping": {
              "ignore_above": 256,
              "type": "keyword"
            },
            "match_mapping_type": "string"
          }
        },
        {
          "cloud_fields_as_keywords": {
            "path_match": "cloud.*",
            "mapping": {
              "ignore_above": 256,
              "type": "keyword"
            },
            "match_mapping_type": "string"
          }
        },
        {
          "low_priority_string": {
            "mapping": {
              "norms": false,
              "ignore_above": 256,
              "type": "keyword"
            },
            "match_mapping_type": "string"
          }
        }
      ],
      "date_detection": true,
      "properties": {
        "@timestamp": {
          "type": "date"
        },
        "message": {
          "type": "text"
        }
      }
    }
  },
  "index_patterns": [
    "logs-container-kubernetes-*"
  ],
  "data_stream": {
    "hidden": false
  },
  "composed_of": [
    "logs-settings"
  ]
}
```
