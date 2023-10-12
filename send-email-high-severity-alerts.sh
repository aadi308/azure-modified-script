#!/bin/bash

# Function to enable email notifications for high severity alerts
enable_email_notifications() {
    subscription_id="$1"
    access_token="$2"
    email="$3"

    url="https://management.azure.com/subscriptions/$subscription_id/providers/Microsoft.Security/securityContacts/default1?api-version=2017-08-01-preview"

    json_data=$(cat <<-JSON
{
  "id": "/subscriptions/$subscription_id/providers/Microsoft.Security/securityContacts/default1",
  "name": "default1",
  "type": "Microsoft.Security/securityContacts",
  "properties": {
    "email": "$email",
    "alertNotifications": "On",
    "alertsToAdmins": "On"
  }
}
JSON
)

    curl -X PUT -H "Authorization: Bearer $access_token" -H "Content-Type: application/json" $url -d "$json_data"
}

OUTPUT_CSV="enabled_email_notifications.csv"
subscription="$1"
email="$2"
echo "$subscription ........."

# Set the current subscription
az account set --subscription "$subscription"

# Initialize the CSV file with headers
echo "Subscription,Action" > "$OUTPUT_CSV"

# Get access token and execute function
access_token=$(az account get-access-token --query "accessToken" -o tsv)

# Enable email notifications
enable_email_notifications "$subscription" "$access_token" "$email"

# Record the action in CSV
echo "$subscription,Enabled" >> "$OUTPUT_CSV"
