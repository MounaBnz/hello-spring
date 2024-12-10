provider "azurerm" {
  features {}
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
    "DOCKER_REGISTRY_SERVER_USER"         = "jesstg" # DockerHub username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = "Jess2001@@" # DockerHub password
  }
}
