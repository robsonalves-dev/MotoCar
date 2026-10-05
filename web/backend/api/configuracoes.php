
<?php

session_start();

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
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

/*
 * Identificação do usuário.
 * Web: utiliza a sessão autenticada.
 * Flutter: exige autenticação por token validado no servidor.
 */

$usuarioId = (int) ($_SESSION['usuario_id'] ?? 0);

if ($usuarioId <= 0) {
    http_response_code(401);

    echo json_encode([
        'status' => false,
        'mensagem' => 'Sessão não autenticada. Faça login novamente.'
    ]);
    exit;
}

$nome = trim($dados['nome'] ?? '');
$email = trim($dados['email'] ?? '');
$senhaAtual = $dados['senha_atual'] ?? '';
$novaSenha = $dados['nova_senha'] ?? '';

if ($nome === '' || $email === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Nome e e-mail são obrigatórios.'
    ]);
    exit;
}

if (mb_strlen($nome) > 100 || mb_strlen($email) > 150) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Nome ou e-mail excede o limite permitido.'
    ]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe um e-mail válido.'
    ]);
    exit;
}

if ($novaSenha !== '' && strlen($novaSenha) < 8) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'A nova senha deve ter pelo menos 8 caracteres.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT id, nome, email, senha
         FROM usuarios
         WHERE id = :id AND status = 1
         LIMIT 1"
    );

    $stmt->execute([
        'id' => $usuarioId
    ]);

    $usuario = $stmt->fetch();

    if (!$usuario) {
        http_response_code(404);

        echo json_encode([
            'status' => false,
            'mensagem' => 'Usuário não encontrado ou inativo.'
        ]);
        exit;
    }

    $senhaFoiAlterada = $novaSenha !== '';
    $emailFoiAlterado = $email !== $usuario['email'];
    $dadosSensíveis = $senhaFoiAlterada || $emailFoiAlterado;

    if ($dadosSensíveis) {

        if ($senhaAtual === '') {
            echo json_encode([
                'status' => false,
                'mensagem' => 'Informe sua senha atual.'
            ]);
            exit;
        }

        if (!hash_equals(
            $usuario['senha'],
            hash('sha256', $senhaAtual)
        )) {
            http_response_code(403);

            echo json_encode([
                'status' => false,
                'mensagem' => 'Senha atual incorreta.'
            ]);
            exit;
        }
    }

    $stmt = $pdo->prepare(
        "SELECT id FROM usuarios
         WHERE email = :email AND id <> :id
         LIMIT 1"
    );

    $stmt->execute([
        'email' => $email,
        'id' => $usuarioId
    ]);

    if ($stmt->fetch()) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Este e-mail já está sendo utilizado.'
        ]);
        exit;
    }

    if ($senhaFoiAlterada) {
        $senhaHash = hash('sha256', $novaSenha);

        $stmt = $pdo->prepare(
            "UPDATE usuarios
             SET nome = :nome,
                 email = :email,
                 senha = :senha
             WHERE id = :id"
        );

        $stmt->execute([
            'nome' => $nome,
            'email' => $email,
            'senha' => $senhaHash,
            'id' => $usuarioId
        ]);

    } else {

        $stmt = $pdo->prepare(
            "UPDATE usuarios
             SET nome = :nome,
                 email = :email
             WHERE id = :id"
        );

        $stmt->execute([
            'nome' => $nome,
            'email' => $email,
            'id' => $usuarioId
        ]);
    }

    $_SESSION['usuario_nome'] = $nome;
    $_SESSION['usuario_email'] = $email;

    echo json_encode([
        'status' => true,
        'mensagem' => 'Configurações atualizadas com sucesso!',
        'usuario' => [
            'id' => $usuarioId,
            'nome' => $nome,
            'email' => $email
        ],
        'senha_alterada' => $senhaFoiAlterada
    ]);

} catch (PDOException $e) {

    http_response_code(500);

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao atualizar as configurações.'
    ]);
}