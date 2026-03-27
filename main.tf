terraform {
  required_version = ">= 0.12"

  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 2.0"
    }
  }
}

provider "grafana" {
  url   = "http://localhost:3000"
  auth  = "admin:password123" # Use your Grafana credentials
}

# 0. Define information concerning alread created resources
data "grafana_data_source" "influxdb_flux" {
  name = "InfluxDB_Flux"   # must match the name grafana-datasource.yml
}

# 1. Create a Folder to organize your test alerts
resource "grafana_folder" "test_folder" {
  title = "Live Stream Testing"
}

locals {
  
  dashboards = {
    live_test_board = {
      json_file = "${path.module}/configs/grafana/boards/live_test_board.json"
      folder    = grafana_folder.test_folder.uid
      vars = {
        DS_INFLUXDB_FLUX = data.grafana_data_source.influxdb_flux.uid
      }
    }
  }

  dashboard_configs = {
    for name, cfg in local.dashboards :
      name => templatefile(cfg.json_file, cfg.vars)
  }
}

# 2. Create Dashboards
resource "grafana_dashboard" "boards" {
  for_each    = local.dashboard_configs
  folder      = local.dashboards[each.key].folder
  config_json = each.value
}

# # 3. Create a Cloud-style Alert Rule
# resource "grafana_rule_group" "test_alerts" {
#   name             = "HighValueAlerts"
#   folder_uid       = grafana_folder.test_folder.uid
#   interval_seconds = 10 # Check every 10 seconds

#   rule {
#     name      = "SineWaveTooHigh"
#     condition = "B" # Point to the reduction/threshold logic below

#     # Step A: Get the data
#     data {
#       ref_id = "A"
#       relative_time_range {
#         from = 60
#         to   = 0
#       }
#       datasource_uid = "InfluxDB_Flux"
#       model = jsonencode({
#         query = "from(bucket: \"test-bucket\") |> range(start: -1m) |> filter(fn: (r) => r._measurement == \"sine_wave\") |> last()"
#       })
#     }

#     # Step B: Set the Threshold
#     data {
#       ref_id = "B"
#       datasource_uid = "-1" # Special UID for built-in Grafana logic
#       model = jsonencode({
#         expression = "A"
#         type       = "threshold"
#         conditions = [{
#           evaluator = { params = [80], type = "gt" }
#           operator  = { type = "and" }
#           query     = { params = [] }
#           reducer   = { params = [], type = "last" }
#           type      = "query"
#         }]
#       })
#     }

#     no_data_state  = "OK"
#     exec_err_state = "Alerting"
#     for            = "30s" # Must be above 80 for 30s to fire
#   }
# }