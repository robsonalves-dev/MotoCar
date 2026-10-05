<?php

session_start();

require_once '../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'OPTIONS') {
    exit;
}

/*
|--------------------------------------------------------------------------
| POST - Cadastrar abastecimento
|--------------------------------------------------------------------------
*/

if ($metodo === 'POST') {

    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

    // Flutter → JSON
    if (stripos($contentType, 'application/json') !== false) {

        $dados = json_decode(
            file_get_contents('php://input'),
            true
        ) ?? [];

        $usuarioId = (int) ($dados['usuario_id'] ?? 0);

        $veiculoId = (int) ($dados['veiculo_id'] ?? 0);

        $combustivel = trim(
            $dados['combustivel'] ?? ''
        );

        $litros = $dados['litros'] ?? null;

        $valorTotal = $dados['valor_total']
            ?? $dados['valor_pago']
            ?? null;

        $quilometragem = $dados['quilometragem']
            ?? null;

        $dataAbastecimento = $dados['data_abastecimento']
            ?? $dados['data']
            ?? '';

    } else {

        // Web → formulário POST
        $dados = $_POST;

        $usuarioId = (int) ($_SESSION['usuario_id'] ?? 0);

        $veiculoId = (int) ($dados['veiculo_id'] ?? 0);

        $combustivel = trim(
            $dados['combustivel'] ?? ''
        );

        $litros = $dados['litros'] ?? null;

        $valorTotal = $dados['valor_pago']
            ?? $dados['valor_total']
            ?? null;

        $quilometragem = $dados['quilometragem']
            ?? null;

        $dataAbastecimento = $dados['data']
            ?? $dados['data_abastecimento']
            ?? '';
    }

    if (
        $usuarioId <= 0 ||
        $veiculoId <= 0 ||
        $combustivel === '' ||
        $litros === null ||
        $valorTotal === null ||
        $quilometragem === null ||
        $dataAbastecimento === ''
    ) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Todos os dados são obrigatórios.'
        ]);

        exit;
    }

    try {

        /*
         * Confirma que o veículo pertence ao usuário.
         */
        $stmt = $pdo->prepare(
            "SELECT id
             FROM veiculos
             WHERE id = :veiculo_id
             AND usuario_id = :usuario_id
             LIMIT 1"
        );

        $stmt->execute([
            'veiculo_id' => $veiculoId,
            'usuario_id' => $usuarioId
        ]);

        if (!$stmt->fetch()) {

            echo json_encode([
                'status' => false,
                'mensagem' => 'Veículo não pertence ao usuário logado.'
            ]);

            exit;
        }

        /*
         * Salva o abastecimento.
         */
        $stmt = $pdo->prepare(
            "INSERT INTO abastecimentos
            (
                usuario_id,
                veiculo_id,
                combustivel,
                litros,
                valor_total,
                quilometragem,
                data_abastecimento
            )
            VALUES
            (
                :usuario_id,
                :veiculo_id,
                :combustivel,
                :litros,
                :valor_total,
                :quilometragem,
                :data_abastecimento
            )"
        );

        $stmt->execute([
            'usuario_id' => $usuarioId,
            'veiculo_id' => $veiculoId,
            'combustivel' => $combustivel,
            'litros' => $litros,
            'valor_total' => $valorTotal,
            'quilometragem' => $quilometragem,
            'data_abastecimento' => $dataAbastecimento
        ]);

        $id = (int) $pdo->lastInsertId();

        /*
         * Web → volta para a página.
         */
        if (stripos($contentType, 'application/json') === false) {

            header('Location: ../../abastecimentos.php');
            exit;
        }

        /*
         * Flutter → JSON.
         */
        header('Content-Type: application/json; charset=utf-8');

        echo json_encode([
            'status' => true,
            'mensagem' => 'Abastecimento cadastrado com sucesso!',
            'id' => $id
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => $e->getMessage()
        ]);
    }

    exit;
}


/*
|--------------------------------------------------------------------------
| PUT - Atualizar abastecimento
|--------------------------------------------------------------------------
*/

if ($metodo === 'PUT') {

    $dados = json_decode(
        file_get_contents('php://input'),
        true
    ) ?? [];

    $id = (int) ($dados['id'] ?? 0);

    $usuarioId = (int) ($dados['usuario_id'] ?? 0);

    $combustivel = trim(
        $dados['combustivel'] ?? ''
    );

    $litros = $dados['litros'] ?? null;

    $valorTotal = $dados['valor_total'] ?? null;

    $quilometragem = $dados['quilometragem'] ?? null;

    $dataAbastecimento =
        $dados['data_abastecimento'] ?? '';

    if (
        $id <= 0 ||
        $usuarioId <= 0 ||
        $combustivel === '' ||
        $litros === null ||
        $valorTotal === null ||
        $quilometragem === null ||
        $dataAbastecimento === ''
    ) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Todos os dados são obrigatórios.'
        ]);

        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "UPDATE abastecimentos
             SET
                combustivel = :combustivel,
                litros = :litros,
                valor_total = :valor_total,
                quilometragem = :quilometragem,
                data_abastecimento = :data_abastecimento
             WHERE id = :id
             AND usuario_id = :usuario_id"
        );

        $stmt->execute([
            'id' => $id,
            'usuario_id' => $usuarioId,
            'combustivel' => $combustivel,
            'litros' => $litros,
            'valor_total' => $valorTotal,
            'quilometragem' => $quilometragem,
            'data_abastecimento' => $dataAbastecimento
        ]);

        echo json_encode([
            'status' => true,
            'mensagem' => 'Abastecimento atualizado com sucesso!'
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao atualizar abastecimento.'
        ]);
    }

    exit;
}


/*
|--------------------------------------------------------------------------
| DELETE - Excluir abastecimento
|--------------------------------------------------------------------------
*/

if ($metodo === 'DELETE') {

    $dados = json_decode(
        file_get_contents('php://input'),
        true
    ) ?? [];

    $id = (int) ($dados['id'] ?? 0);

    $usuarioId = (int) ($dados['usuario_id'] ?? 0);

    if ($id <= 0 || $usuarioId <= 0) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Dados inválidos para exclusão.'
        ]);

        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "DELETE FROM abastecimentos
             WHERE id = :id
             AND usuario_id = :usuario_id"
        );

        $stmt->execute([
            'id' => $id,
            'usuario_id' => $usuarioId
        ]);

        if ($stmt->rowCount() === 0) {

            echo json_encode([
                'status' => false,
                'mensagem' => 'Abastecimento não encontrado.'
            ]);

            exit;
        }

        echo json_encode([
            'status' => true,
            'mensagem' => 'Abastecimento excluído com sucesso!'
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao excluir abastecimento.'
        ]);
    }

    exit;
}


echo json_encode([
    'status' => false,
    'mensagem' => 'Método não permitido.'
]);