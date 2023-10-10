#!/bin/bash

# Create two empty arrays
rg=()
wa=()

OUTPUT_CSV="outdated_web_apps.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Web App Name,Action" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false

# Skip the first argument (subscription value)
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
    elif [ "$arg" == "--wa" ]; then
        # Switch to adding elements to array2
        in_array1=false
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        else
            wa+=("$arg")
        fi
    fi
done

# Loop through each resource group and web app
for ((i=0; i<${#wa[@]}; i++)); do
    resource_group=${rg[$i]}
    web_app=${wa[$i]}

    # Check if the web app exists in the resource group
    web_app_exists=$(az webapp show --resource-group "$resource_group" --name "$web_app" --query 'name' -o tsv 2>/dev/null)

    if [ -z "$web_app_exists" ]; then
        echo "Web App '$web_app' not found in resource group '$resource_group'. Skipping..."
        continue
    fi

    https_only=$(az webapp show --resource-group "$resource_group" --name "$web_app" --query 'httpsOnly' -o tsv)

    if [ "$https_only" == "true" ]; then
        echo "$subscription,$resource_group,$web_app,HTTPS Only is already enabled" >> "$OUTPUT_CSV"
    else
        az webapp update --resource-group "$resource_group" --name "$web_app" --set httpsOnly=true
        echo "$web_app Webapp has been updated to use HTTPS Only"
        echo "$subscription,$resource_group,$web_app,Enable HTTPS Only,Updated" >> "$OUTPUT_CSV"
    fi
done
