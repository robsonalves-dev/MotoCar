<?php

require_once '../../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

/*
|--------------------------------------------------------------------------
| BUSCAR DADOS DO USUÁRIO
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $usuarioId = (int) ($_GET['usuario_id'] ?? 0);

    if ($usuarioId <= 0) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Usuário inválido.'
        ]);
        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "SELECT id, nome, email
             FROM usuarios
             WHERE id = :id
             AND status = 1
             LIMIT 1"
        );

        $stmt->execute([
            'id' => $usuarioId
        ]);

        $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$usuario) {
            echo json_encode([
                'sucesso' => false,
                'mensagem' => 'Usuário não encontrado.'
            ]);
            exit;
        }

        echo json_encode([
            'sucesso' => true,
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
            'mensagem' => 'Erro ao carregar dados da conta.'
        ]);
        exit;
    }
}

/*
|--------------------------------------------------------------------------
| ATUALIZAR CONTA
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}

$dados = json_decode(
    file_get_contents('php://input'),
    true
) ?? [];

$usuarioId = (int) ($dados['usuario_id'] ?? 0);

$nome = trim(
    $dados['nome'] ?? ''
);

$email = trim(
    $dados['email'] ?? ''
);

$senhaAtual = $dados['senha_atual'] ?? '';

$novaSenha = $dados['nova_senha'] ?? '';

if ($usuarioId <= 0) {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Usuário inválido.'
    ]);
    exit;
}

if ($nome === '' || $email === '') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Nome e e-mail são obrigatórios.'
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

/*
|--------------------------------------------------------------------------
| SE ESTIVER ALTERANDO QUALQUER DADO,
| CONFIRMAMOS A SENHA ATUAL
|--------------------------------------------------------------------------
*/

if ($senhaAtual === '') {
    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Informe sua senha atual para salvar as alterações.'
    ]);
    exit;
}

try {

    /*
    |--------------------------------------------------------------------------
    | BUSCAR USUÁRIO
    |--------------------------------------------------------------------------
    */

    $stmt = $pdo->prepare(
        "SELECT id, nome, email, senha, status
         FROM usuarios
         WHERE id = :id
         LIMIT 1"
    );

    $stmt->execute([
        'id' => $usuarioId
    ]);

    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Usuário não encontrado.'
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

    /*
    |--------------------------------------------------------------------------
    | VALIDAR SENHA ATUAL
    |--------------------------------------------------------------------------
    */

    $senhaAtualHash = hash(
        'sha256',
        $senhaAtual
    );

    if (!hash_equals(
        $usuario['senha'],
        $senhaAtualHash
    )) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Senha atual incorreta.'
        ]);
        exit;
    }

    /*
    |--------------------------------------------------------------------------
    | VERIFICAR E-MAIL DUPLICADO
    |--------------------------------------------------------------------------
    */

    $stmt = $pdo->prepare(
        "SELECT id
         FROM usuarios
         WHERE email = :email
         AND id != :id
         LIMIT 1"
    );

    $stmt->execute([
        'email' => $email,
        'id' => $usuarioId
    ]);

    if ($stmt->fetch()) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'Este e-mail já está cadastrado.'
        ]);
        exit;
    }

    /*
    |--------------------------------------------------------------------------
    | ATUALIZAR NOME E E-MAIL
    |--------------------------------------------------------------------------
    */

    if ($novaSenha === '') {

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

        echo json_encode([
            'sucesso' => true,
            'mensagem' => 'Dados atualizados com sucesso.',
            'usuario' => [
                'id' => $usuarioId,
                'nome' => $nome,
                'email' => $email
            ],
            'senha_alterada' => false
        ]);
        exit;
    }

    /*
    |--------------------------------------------------------------------------
    | ALTERAR SENHA
    |--------------------------------------------------------------------------
    */

    if (strlen($novaSenha) < 8) {
        echo json_encode([
            'sucesso' => false,
            'mensagem' => 'A nova senha deve ter pelo menos 8 caracteres.'
        ]);
        exit;
    }

    $novaSenhaHash = hash(
        'sha256',
        $novaSenha
    );

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
        'senha' => $novaSenhaHash,
        'id' => $usuarioId
    ]);

    echo json_encode([
        'sucesso' => true,
        'mensagem' => 'Dados e senha atualizados com sucesso.',
        'usuario' => [
            'id' => $usuarioId,
            'nome' => $nome,
            'email' => $email
        ],
        'senha_alterada' => true
    ]);
    exit;

} catch (PDOException $e) {

    echo json_encode([
        'sucesso' => false,
        'mensagem' => 'Erro ao atualizar a conta.'
    ]);
    exit;
}