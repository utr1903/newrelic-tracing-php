############################
### Notification Channel ###
############################

# Notification destination - Email
resource "newrelic_notification_destination" "email" {

  name       = "email"
  account_id = var.NEW_RELIC_ACCOUNT_ID
  type       = "EMAIL"

  property {
    key   = "email"
    value = var.notification_email
  }
}

# Notification channel - Email
resource "newrelic_notification_channel" "email" {
  name       = "email"
  account_id = var.NEW_RELIC_ACCOUNT_ID
  type       = "EMAIL"

  destination_id = newrelic_notification_destination.email.id
  product        = "IINT"

  property {
    key = "subject"
    value = "Alert - ${newrelic_nrql_alert_condition.response_time_above_3_sec_at_least_once.name}"
  }
}
#########
