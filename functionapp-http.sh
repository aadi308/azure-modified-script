#!/bin/bash

# Create two empty arrays
rg=()
fa=()

OUTPUT_CSV="updated_function_apps_http_version.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Function App Name,HTTP Version,Action" > "$OUTPUT_CSV"

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

    appstatus=$(az functionapp config show --resource-group $resource_group --name $function_app --query 'http20Enabled')
    if [ "$appstatus" != "" ]; then
        if [ "$appstatus" != "true" ]; then
            az functionapp config set --resource-group $resource_group --name $function_app --http20-enable true
            echo "$function_app Function App is Updated successfully"
            status="Updated"
        else
            echo "$function_app Function App is Already Updated"
            status="Already Updated"
        fi
        echo "$subscription,$resource_group,$function_app,Enable HTTP/2,$status" >> "$OUTPUT_CSV"
    else
        echo "error $function_app Function App and $resource_group ResourceGroup didn't match"
    fi
done
