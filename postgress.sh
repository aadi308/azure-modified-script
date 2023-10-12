#!/bin/bash

# Create empty arrays
rg=()
pg_servers=()

OUTPUT_CSV="updated_pg_servers_log_retention.csv"
subscription="$1"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Resource Group,PostgreSQL Server Name,Action,Log Retention Days" > "$OUTPUT_CSV"

# Flags to differentiate between the arrays
in_array1=false


# Skip the first argument (subscription value)
shift


# Loop through the remaining command-line arguments
for arg in "$@"; do
    if [ "$arg" == "--rg" ]; then
        # Switch to adding elements to array1
        in_array1=true
    elif [ "$arg" == "--pg_servers" ]; then
        # Switch to adding elements to array2
        in_array1=false
    else
        # Add the argument to the appropriate array
        if [ "$in_array1" == true ]; then
            rg+=("$arg")
        else
            pg_servers+=("$arg")
        fi
    fi
done
# Loop through each resource group and PostgreSQL server
for ((i=0; i<${#pg_servers[@]}; i++)); do
    resource_group=${rg[$i]}
    pg_server_name=${pg_servers[$i]}
    # Get the current log retention days
    current_log_retention=$(az postgres server configuration show --resource-group $resource_group --server-name $pg_server_name --name log_retention_days --query "value" -o tsv)

    
    if [ "$current_log_retention" -gt 3 ]; then
        echo "Log retention days for PostgreSQL Server $pg_server_name is already greater than 3. No action taken."
        echo "PostgreSQL Server: $subscription,$resource_group,$pg_server_name,No action taken,$current_log_retention" >> "$OUTPUT_CSV"
    else
        # Update the log retention days
        az postgres server configuration set --resource-group $resource_group --server $pg_server_name --name log_retention_days --value 5

        echo "PostgreSQL Server: $subscription,$resource_group,$pg_server_name,Updated,$current_log_retention" >> "$OUTPUT_CSV"
    fi
done
