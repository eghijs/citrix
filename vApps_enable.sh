#!/bin/bash
# 
# Criado por: Erik P. GHijs
# Data: 19/11/2017
# Descricao: Script para instalar e ativar do servico “AutoStart”, no qual gerencia o ligamento   
#            das vm´s no host XenServer quando houver uma falta de energia. O script esta
#            agregado ao vApps.
#
# Obs.: Este script vai precisar de um gerenciador de no-break, no meu caso, utilizo Smart-UPS 3000 RM XL da APC, 
#       com um cartão UPS Network Management Card 2 que esta conectado ao meu servidor e sendo gerenciado pelo 
#       APCUPSD (http://www.apcupsd.com).
#
# OS: Xenserver 7.2
#
# Parametros de configuração
NAMEFILE=Start_vApps

# Criação da estrutura do script
cd /etc/init.d
touch $NAMEFILE
chmod a+x $NAMEFILE

cat <<EOF > $NAMEFILE
#!/bin/bash
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
echo -n "Script $NAMEFILE criado."
#
# Modificando o rc.local
cd /etc/rc.d
cat <<EOF > rc.local
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

# Script para iniciar autostart "vApps" 
sleep 60
/etc/init.d/Start_vApps

EOF
#
chmod u+x rc.local
echo -n "Permissao alterada no rc.local (OK)."
echo -n ""
echo -n "Verificando o status do serviço rc-local."
systemctl status rc-local
echo -n ""
echo -n "Gostaria de ativar o rc.local, Continue? [Y/N]"
read YN
case "$YN" in
Y)
echo ""
echo -n "Servico rc.local ativado..."
systemctl start rc-local

;;
y)
echo ""
echo -n "Servico rc.local ativado..."
systemctl start rc-local

;;
N)
echo -n "Cancelado ativacao do servico rc.local..."
echo " "
exit 1
;;
n)
echo -n "Cancelado ativacao do servico rc.local..."
echo " "
exit 1
;;
*)
echo -n "Opcao invalida, cancelando."
echo ""
exit 1
esac
