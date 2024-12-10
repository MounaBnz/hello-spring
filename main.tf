provider "azurerm" {
  features {}
  subscription_id=var.subscription_id
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



#------------------------------------------------------###################
#    App Insights + Log Analytics + Diagnostics 
#------------------------------------------------------###################

resource "azurerm_application_insights" "example" {
  name                = "tf-test-appinsights-stage"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  application_type    = "java" #java web app
  workspace_id        = azurerm_log_analytics_workspace.rg.id
}

# Azure Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "rg" {
  name                       = "log-analytics"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  sku                        = "PerGB2018"
  retention_in_days          = 30
  tags                       = null
  internet_ingestion_enabled = false #best practice to disable public access
}

data "azurerm_monitor_diagnostic_categories" "main" {
  resource_id = azurerm_linux_web_app.app.id
}

# Connecter le Azure Web App au Log Analytics Workspace
#Activer qqes paramètres de diagnostic de l'application
resource "azurerm_monitor_diagnostic_setting" "example" {
  name                       = "webapp-diagnostics"
  target_resource_id         = azurerm_linux_web_app.app.id
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
    "Security", "SecurityInsights", "AgentHealthAssessment", "AzureActivity", "SecurityCenterFree", "DnsAnalytics", "ADAssessment", "AntiMalware", "ServiceMap", "SQLAssessment", "SQLAdvancedThreatProtection", "Updates"
  ])
}

resource "azurerm_log_analytics_solution" "solutions" {
  for_each              = local.solution_name
  solution_name         = each.key
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  workspace_resource_id = azurerm_log_analytics_workspace.example.id
  workspace_name        = azurerm_log_analytics_workspace.example.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/${each.key}"
  }
} 


#------------------------------------------------------###################
#    Mail Alert
#------------------------------------------------------###################


resource "azurerm_monitor_action_group" "monitor" {
  name                = "actiongroup"
  resource_group_name = azurerm_resource_group.example.name
  short_name          = "alert1234"
 email_receiver {
   email_address = "narjes.taghlet@insat.ucar.tn"
   name = "Monitoring Alert ! "
 }
}

# define criteria
resource "azurerm_monitor_metric_alert" "metric" {
  name                = "metricalert-webapp"
  resource_group_name = azurerm_resource_group.example.name
  scopes              = [azurerm_linux_web_app.frontwebapp.id]
  description         = "alerts"
  enabled = true

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.monitor.id
  }
  }

