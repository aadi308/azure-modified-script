#!/bin/bash

# Create two empty arrays
rg=()
fa=()
allowed_origins=()

OUTPUT_CSV="updated_function_apps_cors.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,Function App Name,Action,CORS Allows All (*)" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false
in_array2=false

# Flags to track if allowed origins are provided
origins_provided=false

# Skip the first argument (subscription value)
shift

# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
        in_array2=false
    elif [ "$arg" == "--fa" ]; then
        # Switch to adding elements to array2
        in_array1=false
        in_array2=true
    elif [ "$arg" == "--allowed-origins" ]; then
        origins_provided=true
        in_array1=false
        in_array2=false
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        elif [ "$in_array2" == true ]; then
            fa+=("$arg")
        elif [ "$origins_provided" == true ]; then
            allowed_origins+=("$arg")
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

    current_origins=$(az functionapp cors show --name $function_app --resource-group $resource_group --query "allowedOrigins" -o tsv)

    if [[ $current_origins == *"*"* ]]; then
        updated_cors="Yes"
    else
        updated_cors="No"
    fi

    if [ ${#allowed_origins[@]} -gt 0 ]; then
        # Remove the wildcard (*) from the CORS rules
        az functionapp cors remove --name $function_app --resource-group $resource_group --allowed-origins '*'

        # Add the specific allowed origins
        for allowed_origin in "${allowed_origins[@]}"; do
            az functionapp cors add --name $function_app --resource-group $resource_group --allowed-origins $allowed_origin
        done

        echo "CORS rules updated for Function App: $function_app"
        echo "$subscription,$resource_group,$function_app,Updated CORS rules,$updated_cors" >> "$OUTPUT_CSV"
    else
        echo "No allowed origins provided. Skipping CORS update for Function App $function_app."
        echo "$subscription,$resource_group,$function_app,No allowed origins provided,$updated_cors" >> "$OUTPUT_CSV"
    fi
done
