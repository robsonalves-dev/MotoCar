<?php

require_once '../../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}

$dados = json_decode(file_get_contents('php://input'), true) ?? [];

$email = trim($dados['email'] ?? '');
$senha = $dados['senha'] ?? '';

if ($email === '' || $senha === '') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'E-mail e senha são obrigatórios.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT id, nome, email, senha, status
         FROM usuarios
         WHERE email = :email
         LIMIT 1"
    );

    $stmt->execute([
        'email' => $email
    ]);

    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'E-mail ou senha incorretos.'
        ]);
        exit;
    }

    if ((int) $usuario['status'] !== 1) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Esta conta está desativada.'
        ]);
        exit;
    }

    // Mesmo método usado pelo cadastro do site
    $senhaHash = hash('sha256', $senha);

    if (!hash_equals($usuario['senha'], $senhaHash)) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'E-mail ou senha incorretos.'
        ]);
        exit;
    }

    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Login realizado com sucesso.',
        'usuario' => [
            'id' => (int) $usuario['id'],
            'nome' => $usuario['nome'],
            'email' => $usuario['email']
        ]
    ]);
    exit;

} catch (PDOException $e) {

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Erro ao realizar login.'
    ]);
    exit;
}