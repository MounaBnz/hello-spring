provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "North Europe"
}

resource "azurerm_app_service_plan" "example" {
  name                = "example-app-service-plan"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "example" {
  name                = "example-springboot-app"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id

  site_config {
    linux_fx_version = "DOCKER|jesstg/petclinic:latest"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io/v1/"
    "DOCKER_REGISTRY_SERVER_USER"         = var.DOCKER_REGISTRY_SERVER_USER
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.DOCKER_REGISTRY_SERVER_PASSWORD
  }
}

#------------------------------------------------------
#    App Insights + Log Analytics + Diagnostics
#------------------------------------------------------

resource "azurerm_application_insights" "example" {
  name                = "example-appinsights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "java"
  workspace_id        = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_log_analytics_workspace" "example" {
  name                       = "log-analytics-example"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  internet_ingestion_enabled = false
}

data "azurerm_monitor_diagnostic_categories" "example" {
  resource_id = azurerm_app_service.example.id
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "webapp-diagnostics"
  target_resource_id         = azurerm_app_service.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "AppServiceHTTPLogs"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  enabled_log {
    category = "AppServiceConsoleLogs"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  enabled_log {
    category = "AppServiceIPSecAuditLogs"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  enabled_log {
    category = "AppServiceAppLogs"
    retention_policy {
      enabled = true
      days    = 30
    }
  }
  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = false
    }
  }
}

locals {
  solution_name = toset([
    "Security",
    "SecurityInsights",
    "AgentHealthAssessment",
    "AzureActivity",
    "SecurityCenterFree",
    "DnsAnalytics",
    "ADAssessment",
    "AntiMalware",
    "ServiceMap",
    "SQLAssessment",
    "SQLAdvancedThreatProtection",
    "Updates"
  ])
}

resource "azurerm_log_analytics_solution" "example" {
  for_each              = local.solution_name
  solution_name         = each.key
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  workspace_resource_id = azurerm_log_analytics_workspace.example.id

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
}

#------------------------------------------------------
#    Mail Alert
#------------------------------------------------------

resource "azurerm_monitor_action_group" "example" {
  name                = "example-action-group"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "alert-example"

  email_receiver {
    email_address = "narjes.taghlet@insat.ucar.tn"
    name          = "Monitoring Alert"
  }
}

resource "azurerm_monitor_metric_alert" "example" {
  name                = "example-metric-alert"
  resource_group_name = azurerm_resource_group.example.name
  scopes              = [azurerm_app_service.example.id]
  description         = "Metric alert for web app"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }
}
