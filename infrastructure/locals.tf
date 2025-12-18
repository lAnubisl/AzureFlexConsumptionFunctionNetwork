locals {
    unique_name = random_string.random.result

    # Resource name locals built from the unique_name prefix (match existing naming patterns)
    resource_group_name      = "rg-${local.unique_name}"
    storage_metadata_name    = "stmetadata${local.unique_name}"
    storage_function_name    = "stfunc${local.unique_name}"
    log_analytics_name       = "log-${local.unique_name}"
    app_insights_name        = "appi-${local.unique_name}"
    service_plan_name       = "app-service-plan-${local.unique_name}"
    function_app_name       = "func-${local.unique_name}"
    storage_account_name    = lower("${local.unique_name}sa")
    vnet_name               = "vnet-${local.unique_name}"
    subnet_name             = "${local.unique_name}-subnet"

}