#!/bin/bash

if cf app $1-old > /dev/null 2>&1 ; then
  cf delete $1-old -f
fi
if cf app $1 > /dev/null 2>&1 ; then
  cf rename $1 $1-old
fi
cf push
if cf app $1 > /dev/null 2>&1 ; then
  if [ `cf curl /v2/apps/\`cf app $1 --guid\`/stats | jq -r '."0".state'` == "RUNNING" ] ; then
    if cf app $1-old > /dev/null 2>&1 ; then
      cf delete $1-old -f
    fi
  fi
fi