#################
### Variables ###
#################

### General ###

# New Relic Account ID
variable "NEW_RELIC_ACCOUNT_ID" {
  type = string
}

# New Relic API Key
variable "NEW_RELIC_API_KEY" {
  type = string
}

# New Relic Region
variable "NEW_RELIC_REGION" {
  type = string
}
######

### Applications ###

# Proxy
variable "php_proxy_app_name" {
  type = string
}

# Persistence
variable "php_persistence_app_name" {
  type = string
}

### Notification destination ###

# Email
variable "notification_email" {
  type = string
}
