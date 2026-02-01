
#!/bin/bash

trap 'printf "\nSaliendo...\n"; killall php > /dev/null 2>&1; exit' SIGINT

clear
echo "========================================"
echo "          GESTOR DE DESPLIEGUE"
echo "========================================"

if [ ! -d "sites" ]; then
    echo "Carpeta /sites/ no encontrada."
    exit 1
fi

echo "Sitios disponibles:"
ls sites/
echo "----------------------------------------"
read -p "Elige el sitio: " sitio

if [ ! -d "sites/$sitio" ]; then
    echo "Ese sitio no existe."
    exit 1
fi

read -p "Puerto (por defecto 8080): " puerto
if [ -z "$puerto" ]; then
    puerto=8080
fi

cat <<EOF > sites/$sitio/router.php
<?php
\$ip = \$_SERVER['REMOTE_ADDR'];
\$uri = \$_SERVER['REQUEST_URI'];
\$path = __DIR__ . "/\$ip" . \$uri;

if (\$uri == '/' || \$uri == '') {
    if (file_exists(__DIR__ . "/\$ip/index.html")) {
        header("Location: /\$ip/index.html");
        exit;
    } else if (file_exists(__DIR__ . "/\$ip/index.php")) {
        header("Location: /\$ip/index.php");
        exit;
    } else {
        echo "Error: No hay index en sites/$sitio/\$ip/";
        exit;
    }
}

return false;
?>
EOF

echo "Corriendo $sitio en http://0.0.0.0:$puerto"
echo "Ruta de archivos: /sites/$sitio/(IP del cliente)/"

cd sites/$sitio
php -S 0.0.0.0:$puerto router.php
