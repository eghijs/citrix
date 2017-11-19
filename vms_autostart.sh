#!/bin/bash
# 
# Criado por: Erik P. GHijs
# Data: 19/11/2017
for UUID in $(xe vm-list power-state=running is-control-domain=false | grep uuid | cut -d: -f2- | tr -d \ )
  do
    NHOST=$(xe vm-param-list uuid=$UUID | grep -i name-label | cut -d: -f2- | tr -d \ )
    xe vm-param-set uuid=$UUID other-config:auto_poweron=true
    echo "Ativando Power-ON das VM´s listado:"
    echo "$NHOST"
done
#
for UUID in $(xe xe appliance-list | grep uuid | cut -d: -f2- | tr -d \ )
  do
   cat <<EOF > /etc/rc.d/rc.local
#!/bin/bash
# THIS FILE IS ADDED FOR COMPATIBILITY PURPOSES
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
# In contrast to previous versions due to parallel execution during boot
# this script will NOT be run after all other services.
#
# Please note that you must run 'chmod +x /etc/rc.d/rc.local' to ensure
# that this script will be executed during boot.

touch /var/lock/subsys/local
#
# Script auto-start para vm´s
sleep 40
xe appliance-start uuid=$UUID
    EOF
    echo "Arquivo rc.local modificado."
    chmod +x /etc/rc.d/rc.local
    echo "Trocado a permissao do rc.local para ser executado."
done
