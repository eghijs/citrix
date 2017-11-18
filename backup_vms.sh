#!/bin/bash
###########################################
##     Criado por: Rafael Ferreira  em 09/11/2011       ##
##     Modificado por: Erik Pereira Ghijs em 18/11/2017       ##
###########################################
#
LOG=/var/log/backup_diario_xenserver.log
rm -rf $LOG
echo " - Backup XenServer - " >> $LOG
echo " - Backup diario -" >> $LOG
CLIENTE="nome_do_cliente"
#
checardir(){
if [ -e "/backup" ]
then
echo " O diretorio existe" >> $LOG
else
echo " O diretorio nao existe, criando o diretorio." >> $LOG
mkdir /backup
fi
}
#
montavolume(){
echo "Listando todos discos do servidor." >> $LOG
echo " "
ls -lh /dev/disk/by-uuid/* | sed "s/^.*\/dev\/.*\/by-uuid\/\(.*\) -> .*\/\([^\/]*\)/\/dev\/\2 -> \1/g"
echo " "
read LIST_UUID
echo " "
mount UUID="$LIST_UUID" /backup
echo " "
echo "Volume montando..." >> $LOG
mount | grep /backup
#
montado=`mount | grep /backup`
#
# Se a montagem nao estiver OK, finaliza o processo e nao realiza o BKP
if [ -z "$montado" ]; then
 echo "unidade de backup nao montado!!" >> $LOG
 exit 1
 else
 echo "unidade de backup montado: $montado" >> $LOG
 fi
}
#
dadosfull(){
# diretorio que sera feito o backup
destino="/backup/"
# nome do arquivo
nome_saida=" VM.xva"
#data de inicio backup
data=$(date +%d-%m-%Y-%H.%M)
# Iniciando Log
echo "Iniciando Backup das VMs: `date +%d-%m-%Y_%H:%M`" >> $LOG
echo "-----------------------------" >> $LOG
echo " " >> $LOG
}
#
#remove backups antigos para liberar espaçno hd
deletabackup(){
#define o tempo para manter o arquivo de bakcup
NDIAS="90"
# 90 = 3 meses, tudo que tiver mais que esse tempo de vida seráemovido
echo "Backups a serem removidos:" >> $LOG
find $destino/* -mmin +$NDIAS >> $LOG
find $destino/* -mmin +$NDIAS -exec rm -rf {} \;
echo "Backups removidos com sucesso" >> $LOG
}
#
backupmetadados(){
# backup dos metadados do xenserver contem informacoes do Dom0 para ser
# importado no caso de perda do XenServer por inteiro, para importacao utilizar
# o comando: xe pool-restore-database file-name="nome_do_arquivo_de_bkp" --force.
# utilizar a importacao apos refazer o servidor, a citrix recomenda a
# reinstalacao completa do host hospedeiro antes de importar o backup de metadados.
cd $destino
echo "Backupeando Metadados..." >> $LOG
xe pool-dump-database file-name=bkp_metadados_$data
echo "Backup Metadados concluido" >> $LOG
}
#
listavm(){
# Criar a lista de backup
echo "Criando lista para backup..." >> $LOG
vm_backup_list=()
vm_backup_list_count=${#vm_backup_list[@]}
echo "Lista criada com sucesso..." >> $LOG
# Listando as Maquinas Virtuais
vm_list_string=`xe vm-list is-control-domain=false`
IFS="
"
vm_list_array=($vm_list_string)
vm_list_count=${#vm_list_array[@]}
# Criando arrays para utilizacao
vm_uuid_array=()
vm_label_array=()
}
#
getvm(){
# Pegando as VM da lista de backup para exportacao
echo "Analisando a lista de VMs..." >> $LOG
#Contador
cont=0
index=0
for line in ${vm_list_array[@]}; do
 if [ ${line:0:4} = "uuid" ]; then
 uuid=`expr "$line" : '.*: \(.*\)$'`
 label=`expr "${vm_list_array[cont+1]}" : '.*: \(.*\)$'`
 vm_uuid_array[index]=$uuid
 vm_label_array[index]=$label
 echo "Added VM #$index: $uuid, $label" >> $LOG
 let "index = $index+1"
 fi
 # Incrementa contador
 let "cont = $cont+1"
done
echo "Analise da Lista de VMs concluido..." >> $LOG
echo " " >> $LOG
}
#
backupvm(){
# Backupeando as VMs
echo "Backupeando as  VMs" >> $LOG
echo " " >> $LOG
#Contador
cont=0
for uuid in ${vm_uuid_array[@]}; do
 # Setando o estado da maquina
 backup_vm=false
 # Se a lista de Backups estiver vazia
 if [ $vm_backup_list_count = 0 ]; then
 # Faca backup de todas a maquinas
 backup_vm=true
 # Senao verifica se a maquina esta na lista de backups
 else
 for backup_uuid in ${vm_backup_list[@]}; do
 if [ $uuid = $backup_uuid ]; then
 backup_vm=true
 break
 fi
 done
 fi
 # Se o backup for para ser realizado
 if [ $backup_vm = true ]; then
 # O processo e iniciado
 echo "VM: $uuid" >> $LOG
 # Label
 label=${vm_label_array[cont]}
 # Cria snapshot
 echo "Criando Snapshot..." >> $LOG
 snapshot=`xe vm-snapshot vm=$uuid new-name-label=$label`
 echo "Snapshot: $snapshot" >> $LOG
 # Seta a VM para nao ser um Template
 echo "Setando para nao ser um Template..." >> $LOG
 snapshot_template=`xe template-param-set is-a-template=false uuid=$snapshot`
 # Exporta
 echo "Exportando VM..." >> $LOG
 snapshot_export=`xe vm-export vm=$snapshot filename="$destino$label-$data$arq_saida"`
 echo "Exportado: $snapshot_export" >> $LOG
 # Apaga snapshot
 echo "Deletando Snapshot..." >> $LOG
 snapshot_delete=`xe vm-uninstall uuid=$snapshot force=true`
 echo "Deletado: $snapshot_delete" >> $LOG


# Se o backup nao foi realizado
 else
 # Log
 echo " " >> $LOG
 echo "VM: $uuid" $LOG
 echo "Backup de maquina Virtual nao realizado!" >> $LOG
 fi
 # Incrementa contador
 let "cont = $cont+1"
done
echo " " >> $LOG
echo "Backup realizado com sucesso!!!" >> $LOG
echo "Backup finalizado em: `date +%d-%m-%y_%H:%M`" >> $LOG
echo "=============================================" >> $LOG
echo "Lista de Backups disponiveis:" >> $LOG
ls -clht $destino >> $LOG
}
enviaemail(){
#Envia email
echo " Enviando e-mail em `date +%d-%m-%y_%H:%M`" >> $LOG
cat $LOG|mailx -s "Backup Diario XenServer $CLIENTE Finalizado" admredegyn@gmail.com
}
#
desmontavolume(){
cd /
umount -f /backup
}
#
#Chamada das Funcoes
montavolume
dadosfull
deletabackup
backupmetadados
listavm
getvm
backupvm
enviaemail
desmontavolume
exit 0
