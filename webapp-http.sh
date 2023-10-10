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
echo "Subscription,Resource Group,Web App Name,HTTP Version,Action" > "$OUTPUT_CSV"

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
    appstatus=$(az webapp config show --resource-group $resource_group --name $web_app --query 'http20Enabled')
    if [ "$appstatus" != "" ]; then
      if [ "$appstatus" != "true" ]; then
        az webapp config set --resource-group $resource_group --name $web_app --http20-enable true
        echo "$web_app Webapp is Updated successfully"
        status="Updated"
      else
        echo "$web_app Webapp is Already Updated"
        status="Already Updated"
      fi
      echo "$subscription,$resource_group,$web_app,Enable HTTP/2,$status" >> "$OUTPUT_CSV"
    else
      echo "error $web_app Webapp and $resource_group ResourceGroup didnt match"
    fi
  done
