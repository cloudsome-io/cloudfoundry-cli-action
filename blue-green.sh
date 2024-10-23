#!/bin/bash

if cf app $1-old > /dev/null 2>&1 ; then
  cf delete $1-old -f
fi
if cf app $1 > /dev/null 2>&1 ; then
  cf rename $1 $1-old
fi

echo "Pushing $1"
if [ -n "$2" ]; then
  cf push -f ./manifest.yml -s $2
else
  cf push -f ./manifest.yml
fi

if cf app $1 > /dev/null 2>&1 ; then
  if [ `cf curl /v2/apps/\`cf app $1 --guid\`/stats | jq -r '."0".state'` == "RUNNING" ] ; then
    if cf app $1-old > /dev/null 2>&1 ; then
      cf delete $1-old -f
    fi
  fi
fi

cf delete-orphaned-routes -f