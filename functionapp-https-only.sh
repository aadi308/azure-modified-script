#!/bin/bash

# Create two empty arrays
rg=()
fa=()

OUTPUT_CSV="updated_function_apps_https_only.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Function App Name,Action" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false

# Skip the first argument (subscription value)
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
    elif [ "$arg" == "--fa" ]; then
        # Switch to adding elements to array2
        in_array1=false
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        else
            fa+=("$arg")
        fi
    fi
done

# Loop through each resource group and function app
for ((i=0; i<${#fa[@]}; i++)); do
    resource_group=${rg[$i]}
    function_app=${fa[$i]}

    # Check if the function app exists in the resource group
    function_app_exists=$(az functionapp show --resource-group "$resource_group" --name "$function_app" --query 'name' -o tsv 2>/dev/null)

    if [ -z "$function_app_exists" ]; then
        echo "Function App '$function_app' not found in resource group '$resource_group'. Skipping..."
        continue
    fi

    https_only=$(az functionapp show --resource-group "$resource_group" --name "$function_app" --query 'httpsOnly' -o tsv)

    if [ "$https_only" == "true" ]; then
        echo "$subscription,$resource_group,$function_app,HTTPS Only is already enabled" >> "$OUTPUT_CSV"
    else
        az functionapp update --resource-group "$resource_group" --name "$function_app" --set httpsOnly=true
        echo "$function_app Function App has been updated to use HTTPS Only"
        echo "$subscription,$resource_group,$function_app,Enable HTTPS Only,Updated" >> "$OUTPUT_CSV"
    fi
done
