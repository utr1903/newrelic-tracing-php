################
### Workflow ###
################

resource "newrelic_workflow" "php_policy_to_email" {

  name       = "workflow-php-policy-to-email"
  account_id = var.NEW_RELIC_ACCOUNT_ID

  # enrichments_enabled   = true
  destinations_enabled  = true
  enabled               = true
  muting_rules_handling = "NOTIFY_ALL_ISSUES"

  # enrichments {
  #   nrql {
  #     name = "Metric"
  #     configuration {
  #       query = "SELECT count(*) FROM Metric WHERE metricName = 'myMetric'"
  #     }
  #   }
  # }

  issues_filter {
    name = "policy-name-${newrelic_alert_policy.php.name}"
    type = "FILTER"

    predicate {
      attribute = "policyName"
      operator  = "EXACTLY_MATCHES"
      values    = [newrelic_alert_policy.php.name]
    }
  }

  destination {
    channel_id = newrelic_notification_channel.email.id
  }
}
