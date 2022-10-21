######################
### Alert Policies ###
######################

# Alert Policies
resource "newrelic_alert_policy" "php" {
  name                = "PHP Alert Policy"
  incident_preference = "PER_CONDITION_AND_TARGET"
}
#########
