# Telegraf InfluxDB Grafana + Terraform Workbench
This Repository contains a basic TIG stack for experimenting with Grafana Terraform provider.

## Requirements
- terraform
- docker
- docker-compose

### OSX install
```Bash
sudo port install terraform colima docker docker-compose-plugin

% optional
sudo port install tflint
```

## Dashboarding export
This procedure ensures to export a JSON version of the dashboard definition which is the most reusable one.

1. visually configure your board, then hit `export` button
2. Select `classic` model, and make sure that `Export for sharing externally` is selected

![imgs/export.gif](imgs/export.gif)

## Alternate solution
Since Terraform 1.5 you can use the `import` block combined with `terraform plan -generate-config-out` to have Terraform both import the state and generate the HCL code for you.

### Step 1: Declare the import block
 Declare the import block

You need the dashboard's UID from Grafana (visible in the URL: `/d/<uid>/...`):
```hcl
# import.tf
import {
  to = grafana_dashboard.boards["live_test_board"]
  id = "live_test_board_uid"   # the Grafana dashboard UID
}
```

### Step 2: Generate the config
```Bash
terraform plan -generate-config-out=generated.tf
```

Terraform will scan Grafana, pull the current state of the resource, and write the HCL into `generated.tf`. You can then clean it up and fold it into your codebase.

### Bulk import: scan all dashboards
If you have many dashboards, you can combine this with the Grafana provider's data source to avoid looking up UIDs manually:

```hcl
data "grafana_dashboards" "all" {}

import {
  for_each = { for d in data.grafana_dashboards.all.dashboards : replace(lower(d.title), " ", "_") => d.uid }
  to = grafana_dashboard.boards[each.key]
  id = each.value
}
```

Then run the same generate command and Terraform will produce one config block per dashboard.

### Realistic workflow

1. Use `-generate-config-out` to get the raw config and state imported
2. Extract `config_json` strings to individual `.json` files
3. Re-introduce `templatefile()` + the `dashboards` locals map from the refactor we did earlier
4. Delete the `import.tf` once applied