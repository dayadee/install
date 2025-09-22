#!/bin/bash

# ====== PROMPT USER ======
read -p "Enter PagerDuty API Key: " API_KEY
read -p "Enter Escalation Policy ID: " ESC_POLICY

DELAY=0.5                  # seconds between requests
INPUT_FILE="services.txt"   # file containing one service ID per line

# ====== PROCESS SERVICES ======
while read -r SERVICE_ID
do
  [[ -z "$SERVICE_ID" ]] && continue  # skip empty lines

  # API call to update escalation policy
  HTTP_CODE=$(curl -s -w "%{http_code}" -o /tmp/resp.json \
    -X PUT \
    -H "Authorization: Token token=$API_KEY" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.pagerduty+json;version=2" \
    -d "{\"service\":{\"escalation_policy\":{\"id\":\"$ESC_POLICY\",\"type\":\"escalation_policy_reference\"}}}" \
    https://api.pagerduty.com/services/$SERVICE_ID)

  # Check HTTP response
  if [[ "$HTTP_CODE" == "200" ]]; then
    echo "✅ Updated service $SERVICE_ID → HTTP $HTTP_CODE"
    jq -r '.service.escalation_policy.id' /tmp/resp.json
  else
    echo "⚠️ Failed to update service $SERVICE_ID → HTTP $HTTP_CODE"
    jq -r '.error.message // "No message returned"' /tmp/resp.json
  fi

  sleep $DELAY
done < "$INPUT_FILE"

echo "All services processed."