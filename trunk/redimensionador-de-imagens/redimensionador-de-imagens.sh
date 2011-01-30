#!/bin/bash

titulo='Redimensionar imagens'

func () {
    conta=0
    echo "$1" | while read item; do
        if [ -r "$item" ]; then
            conta=$((conta+1))
            echo $conta
        fi
    done
}

for comando in wc convert find qdbus expr cut; do
    if ! [ -x "`which \"$comando\"`" ]; then
        kdialog --title "$titulo" --error "Erro: o comando '$comando' nao foi encontrado no '\$PATH'."
    exit 1
    fi
done

origem="`kdialog --title 'Escolha a pasta que contem as imagens a serem redimensionadas' --getexistingdirectory \"$PWD\"`"
[ $? -eq 0 ] && [ -d "$origem" ] || exit 1
echo "Origem: '$origem'"
lenorig="`expr length \"$origem\"`"
lenorig=$((lenorig+1))

destino="`kdialog --title 'Escolha as pastas para salvar as imagens redimensionadas' --getexistingdirectory \"$origem\"`"
[ $? -eq 0 ] && [ -d "$destino" ] || exit 1
echo "Destino: '$destino'"

resolucao="`kdialog --title \"$titulo\" --inputbox 'Digite o novo tamanho das imagens, em pixels [WxH]:' '640x480'`"
[ $? -eq 0 ] && [ "$resolucao" ] || exit 1

lista=""
for tipo in jpg png gif jpeg; do
    lista="$lista `find \"$origem\" -type f -iname \"*.$tipo\"`"
done

tam="`func \"$lista\" | tail --lines=1`"

qdbus="`kdialog --title \"$titulo\" --progressbar 'Aguarde enquanto as imagens estao sendo redimensionadas...' 100`"
[ $? -eq 0 ] && [ "$qdbus" ] || exit 1

cou=0

export tam

echo "$lista" | while read item; do
    [ -r "$item" ] || continue
    while true; do
        arqd="$destino/`echo \"$item\" | cut -b \"${lenorig}-\"`"
        pasta="`dirname \"$arqd\"`"
        echo -ne "\nRedimensionando imagem '$item'\nSalvando o resultado para '$arqd'...\n"
        saida="`(mkdir -pv \"$pasta\" && rm -fv \"$arqd\" && convert \"$item\" -resize \"$resolucao\" \"$arqd\") 2>&1`"
        if [ $? -ne 0 ]; then
            msg="`echo -ne \"Ocorreu um erro durante o processamento de '$item':\\n\\n${saida}\\n\\nClique em SIM para tentar redimensionar a imagem novamente ou NAO para continuar o processo na proxima imagem.\"`"
            kdialog --title "$titulo" --warningyesnocancel "$msg"
            resu=$?
            if [ $resu -eq 2 ]; then
                qdbus $qdbus org.kde.kdialog.ProgressDialog.close
                exit 1
            elif [ $resu -eq 1 ]; then
                break
            fi
        else
            break
        fi
    done
    cou=$((cou+1))
    qdbus $qdbus org.freedesktop.DBus.Properties.Set org.kde.kdialog.ProgressDialog value $(($cou*100/$tam))
done

qdbus $qdbus org.kde.kdialog.ProgressDialog.close
kdialog --title "$titulo" --msgbox 'Concluido.'
exit 0
