<?php

session_start();

require_once '../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';

if (stripos($contentType, 'application/json') !== false) {
    $dados = json_decode(file_get_contents('php://input'), true) ?? [];
} else {
    $dados = $_POST;
}

$email = trim($dados['email'] ?? '');
$senha = $dados['senha'] ?? '';

if ($email === '' || $senha === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'E-mail e senha são obrigatórios.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT id, nome, email, senha
         FROM usuarios
         WHERE email = :email AND status = 1
         LIMIT 1"
    );

    $stmt->execute([
        'email' => $email
    ]);

    $usuario = $stmt->fetch();

   if (
    !$usuario ||
    !hash_equals(
        $usuario['senha'],
        hash('sha256', $senha)
    )
) {
    header('Location: ../../login.php?erro=1');
    exit;
}

    // Guarda o usuário logado no Web
    $_SESSION['usuario_id'] = (int) $usuario['id'];
    $_SESSION['usuario_nome'] = $usuario['nome'];
    $_SESSION['usuario_email'] = $usuario['email'];

    // Web → painel
    if (stripos($contentType, 'application/json') === false) {
        header('Location: ../../dashboard.php');
        exit;
    }

    // Flutter → JSON
    header('Content-Type: application/json; charset=utf-8');

    echo json_encode([
        'status' => true,
        'mensagem' => 'Login realizado com sucesso!',
        'usuario' => [
            'id' => (int) $usuario['id'],
            'nome' => $usuario['nome'],
            'email' => $usuario['email']
        ]
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao realizar login.'
    ]);
}