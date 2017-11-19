#!/bin/bash
# 
for UUID in $(xe vm-list power-state=running is-control-domain=false | grep uuid | cut -d: -f2- | tr -d \ )
  do
    NHOST=$(xe vm-param-list uuid=$UUID | grep -i name-label | cut -d: -f2- | tr -d \ )
    xe vm-param-set uuid=$UUID other-config:auto_poweron=true
    echo "$NHOST"
done
