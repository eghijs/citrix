#!/bin/bash
###########################################
##     Criado por: Rafael Ferreira  em 09/11/2011       ##
##     Modificado por: Erik Pereira Ghijs em 18/11/2017       ##
###########################################
#
DIR_BACKUP=/backup
cd $DIR_BACKUP
clear
echo " "
echo "        Programa de Recuperacao de Snapshot"
echo " "
echo " "
echo " Selecione o arquivo de imagem a ser restaurado:"
echo " "
ls -clht | grep -v "bkp_metadados*"
echo " "
echo "Escolha VMs que deseja recuperar, na listagem acima."
echo "Selecione com o mouse e depois copie, com botao direito."
echo "Cole aqui em baixo:"
read IMAGEM
echo -n "O arquivo de imagem selecionado foi: $IMAGEM"
echo " "
echo -n "Continue? [Y/N]"
read YN
case "$YN" in
Y)
echo ""
echo -n "Restaurando imagem..."
xe vm-import filename="$IMAGEM" preserve=true
;;
y)
echo ""
echo -n "Restaurando imagem..."
xe vm-import filename="$IMAGEM" preserve=true
;;
N)
echo -n "Restauracao cancelada..."
echo " "
exit 1
;;
n)
echo -n "Restauracao cancelada..."
echo " "
exit 1
;;
*)
echo -n "Opcao invalida, cancelando restauracao."
echo ""
exit 1
esac
