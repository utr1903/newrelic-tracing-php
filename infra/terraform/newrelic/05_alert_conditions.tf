#######################
### Alert Condition ###
#######################

# Alert condition - Response time
resource "newrelic_nrql_alert_condition" "response_time_above_3_sec_at_least_once" {
  name       = "response_time_above_3_sec_at_least_once"
  account_id = var.NEW_RELIC_ACCOUNT_ID
  policy_id  = newrelic_alert_policy.php.id

  type                           = "static"
  description                    = "Alert when transactions are taking too long"

  enabled                        = true
  violation_time_limit_seconds   = 3 * 24 * 60 * 60 // days calculated into seconds
  fill_option                    = "none"
  aggregation_window             = 60
  aggregation_method             = "event_flow"
  aggregation_delay              = 120
  expiration_duration            = 120
  open_violation_on_expiration   = true
  close_violations_on_expiration = true
  slide_by                       = 30

  nrql {
    query = "FROM Span SELECT average(duration) WHERE entity.name = '${var.php_proxy_app_name}' OR entity.name = '${var.php_persistence_app_name}'"
  }

  critical {
    operator              = "above"
    threshold             = 5
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 3.5
    threshold_duration    = 60
    threshold_occurrences = "at_least_once"
  }
}

# Alert condition tag
resource "newrelic_entity_tags" "response_time_above_3_sec_at_least_once" {
    guid = newrelic_nrql_alert_condition.response_time_above_3_sec_at_least_once.entity_guid 

    tag {
        key = "environment"
        values = ["prod"]
    }

    tag {
        key = "maintainers"
        values = ["Bill Burr", "Chris Rock"]
    }
}

#########
