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
  kind                = "Linux" # Change to Linux for Docker container support
  reserved            = true    # Required for Linux App Service Plans

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
    linux_fx_version = "DOCKER|jesstg/petclinic:latest" # Specify the Docker image
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "true" # Required for containerized apps
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io/v1/" # Optional for public Docker images
    "DOCKER_REGISTRY_SERVER_USER"         = var.DOCKER_REGISTRY_SERVER_USER # DockerHub username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = var.DOCKER_REGISTRY_SERVER_PASSWORD # DockerHub password
  }
}

# ------------------------------------------------------------
# Application Insights
# ------------------------------------------------------------

resource "azurerm_application_insights" "example" {
  name                = "example-app-insights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "web" # Choose appropriate application type (web, java, etc.)
}

# ------------------------------------------------------------
# Log Analytics Workspace (for diagnostic logs)
# ------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "example" {
  name                       = "example-log-analytics"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
}

# ------------------------------------------------------------
# Diagnostic Setting to Connect App Service to Application Insights
# ------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "app-service-diagnostics"
  target_resource_id         = azurerm_app_service.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }
  enabled_log {
    category = "AppServiceAppLogs"
  }
}


# ------------------------------------------------------------
# Action Group (Email Alerts)
# ------------------------------------------------------------

resource "azurerm_monitor_action_group" "example" {
  name                = "example-action-group"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "alert-group"

  email_receiver {
    name          = "Admin Alert"
    email_address = var.alert_email
  }
}

# ------------------------------------------------------------
# Metric Alert (Triggered by metric thresholds)
# ------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "example" {
  name                = "metric-alert"
  resource_group_name = azurerm_resource_group.example.name
  scopes              = [azurerm_app_service.example.id]
  description         = "Alert when the number of requests exceeds threshold"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.example.id
  }
}
