#!/bin/bash

MANIFEST="./manifest.yml"
STACK=""
TIMEOUT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --stack)
      STACK="$2"
      shift # Skip the value
      ;;
    --timeout)
      TIMEOUT="$2"
      shift # Skip the value
      ;;
    -f)
      MANIFEST="$2"
      shift # Skip the value
      ;;
    --redis)
      REDIS_APP_NAME="$2"
      shift # Skip the value
      ;;
    --varnish)
      VARNISH_APP_NAME="$2"
      shift # Skip the value
      ;;
    -*)
      echo "Unknown named argument: $1"
      exit 1
      ;;
    *)
      APP_NAME="$1"
      ;;
  esac
  shift
done

# Ensure app name is provided
if [[ -z "$APP_NAME" ]]; then
  echo "Error: Application name is required."
  exit 1
fi

# Check for manifest file
if [[ ! -f $MANIFEST ]]; then
  echo "Error: $MANIFEST not found in the current directory."
  exit 1
fi

# Check if the app exists and manage old app versions
if cf app "$APP_NAME-old" > /dev/null 2>&1; then
  cf delete "$APP_NAME-old" -f || { echo "Failed to delete $APP_NAME-old"; exit 1; }
fi

# Rename actual app version to -old
if cf app "$APP_NAME" > /dev/null 2>&1; then
  cf rename "$APP_NAME" "$APP_NAME-old" || { echo "Failed to rename $APP_NAME adding -old"; exit 1; }
fi

echo "Creating the app reference $APP_NAME-new"
cf create-app "$APP_NAME-new" || { echo "Failed to add network policy"; exit 1; }

# Add network policy if both SOURCE and DESTINATION are set
if [[ -n "$VARNISH_APP_NAME" ]]; then
    echo "Adding network policy for communicate vanrnish to Magento"
    cf add-network-policy "$VARNISH_APP_NAME" "$APP_NAME-new" || { echo "Failed to add network policy"; exit 1; }
    cf add-network-policy "$APP_NAME-new" "$VARNISH_APP_NAME" --protocol tcp --port 80 || { echo "Failed to add network policy"; exit 1; }
fi
if [[ -n "$REDIS_APP_NAME" ]]; then
  echo "Adding network policy for communicate $APP_NAME to Redis"
  cf add-network-policy "$APP_NAME-new" "$REDIS_APP_NAME" --protocol tcp --port 6379|| { echo "Failed to add network policy for redis"; exit 1; }
fi

# Push the app
echo "Pushing $APP_NAME-new"
TIMEOUT_FLAG=""
if [[ -n "$TIMEOUT" ]]; then
  TIMEOUT_FLAG="-t $TIMEOUT"
  export CF_STARTUP_TIMEOUT=$(( (TIMEOUT + 59) / 60 ))
fi
if [[ -n "$STACK" ]]; then
  cf push "$APP_NAME-new" -f $MANIFEST -s "$STACK" --no-route $TIMEOUT_FLAG || { echo "Failed to push $APP_NAME with stack $STACK"; exit 1; }
else
  cf push "$APP_NAME-new" -f $MANIFEST --no-route $TIMEOUT_FLAG || { echo "Failed to push $APP_NAME"; exit 1; }
fi



# Verify if the new app is running
if cf app "$APP_NAME-new" > /dev/null 2>&1; then
  APP_GUID=$(cf app "$APP_NAME-new" --guid)
  APP_STATE=$(cf curl "/v2/apps/$APP_GUID/stats" | jq -r '."0".state' 2>/dev/null)

  if [[ "$APP_STATE" == "RUNNING" ]]; then
    echo "Renaming $APP_NAME"
    cf rename "$APP_NAME-new" $APP_NAME || { echo "Failed to rename $APP_NAME-new removing -new"; exit 1; }

    echo "applying manfiest for route alignment"
    cf apply-manifest -f $MANIFEST

    if cf app "$APP_NAME-old" > /dev/null 2>&1; then
      cf delete "$APP_NAME-old" -f || { echo "Failed to delete $APP_NAME-old"; exit 1; }
    fi
    echo "Restarting varnish app"
    cf restart varnish || { echo "Failed to restart $SOURCE for network policy set up"; exit 1; }

  else
    echo "Warning: $APP_NAME is not running. Check the logs for details."
  fi
else
  echo "Error: $APP_NAME not found after push."
  exit 1
fi

# Clean up orphaned routes
cf delete-orphaned-routes -f || { echo "Failed to delete orphaned routes"; exit 1; }
