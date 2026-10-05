<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}

$nome = trim($_POST['nome'] ?? '');
$email = trim($_POST['email'] ?? '');
$senha = $_POST['senha'] ?? '';

if ($nome === '' || $email === '' || $senha === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Nome, e-mail e senha são obrigatórios.'
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
            'status' => false,
            'mensagem' => 'Este e-mail já está cadastrado.'
        ]);
        exit;
    }

    $senhaHash = hash('sha256', $senha);

    $stmt = $pdo->prepare(
        "INSERT INTO usuarios (nome, email, senha, status)
         VALUES (:nome, :email, :senha, 1)"
    );

    $stmt->execute([
        'nome' => $nome,
        'email' => $email,
        'senha' => $senhaHash
    ]);

    header('Location: ../../login.php');
    exit;

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao realizar cadastro.'
    ]);
    exit;
}