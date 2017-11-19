
#!/bin/bash
# 
# Criado por: Erik P. GHijs
# Data: 19/11/2017
# Descricao: Este script tem a finalidade de ativar o auto-start das vm´s no Xenserver 7.2.
#
# Parametros de configuração
PATH=/sbin:/usr/sbin:$PATH



cat <<EOF > /opt/autostartvapps.sh
# AutoStart XenServer vApps with the tag autostart in their description
# Script originally created by Raido Consultants - http://www.raido.be
# Script updated and shared by E.Y. Barthel - http://www.virtues.it
TAG="autostart"
 
# helper function
function xe_param()
{
    PARAM=$1
    while read DATA; do
        LINE=$(echo $DATA | egrep "$PARAM")
        if [ $? -eq 0 ]; then
            echo "$LINE" | awk 'BEGIN{FS=": "}{print $2}'
        fi
    done
} # Get all Applicances
sleep 20
VAPPS=$(xe appliance-list | xe_param uuid)
for VAPP in $VAPPS
do
    # debug info
    # echo "Esther's AutoStart : Checking vApp $VAPP"
    VAPP_TAGS="$(xe appliance-param-get uuid=$VAPP param-name=name-description)"
    if [[ $VAPP_TAGS == *$TAG* ]]; then
        # action info:
        echo "starting vApp $VAPP";
        xe appliance-start uuid=$VAPP;
        sleep 20
    fi
done
EOF
chmod +x /opt/autostartvapps.sh
