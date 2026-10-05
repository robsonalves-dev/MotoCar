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

$nome  = trim($dados['nome'] ?? '');
$email = trim($dados['email'] ?? '');
$senha = $dados['senha'] ?? '';

if ($nome === '' || $email === '' || $senha === '') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Nome, e-mail e senha são obrigatórios.'
    ]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Informe um e-mail válido.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT id FROM usuarios WHERE email = :email LIMIT 1"
    );

    $stmt->execute([
        'email' => $email
    ]);

    if ($stmt->fetch()) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Este e-mail já está cadastrado.'
        ]);
        exit;
    }

    // Mesmo padrão usado pelo cadastro web e pelo login.
    $senhaHash = hash('sha256', $senha);

    $stmt = $pdo->prepare(
        "INSERT INTO usuarios (nome, email, senha, status)
         VALUES (:nome, :email, :senha, 1)"
    );

    $stmt->execute([
        'nome'  => $nome,
        'email' => $email,
        'senha' => $senhaHash
    ]);

    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Cadastro realizado com sucesso.'
    ]);
    exit;

} catch (PDOException $e) {

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Erro ao realizar cadastro.'
    ]);
    exit;
}