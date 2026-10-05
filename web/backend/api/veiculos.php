<?php

session_start();

require_once '../config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

/*
|--------------------------------------------------------------------------
| IDENTIFICA O USUÁRIO
|--------------------------------------------------------------------------
*/

$contentType = $_SERVER['CONTENT_TYPE'] ?? '';

if (stripos($contentType, 'application/json') !== false) {

    $dados = json_decode(
        file_get_contents('php://input'),
        true
    ) ?? [];

    $usuarioId = (int) ($dados['usuario_id'] ?? $_GET['usuario_id'] ?? 0);

} else {

    $dados = $_POST;

    // Web usa o usuário logado
    $usuarioId = (int) ($_SESSION['usuario_id'] ?? 0);
}


/*
|--------------------------------------------------------------------------
| LISTAR VEÍCULOS
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] === 'GET') {

    $usuarioId = (int) ($_GET['usuario_id'] ?? 0);

    if ($usuarioId <= 0) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Usuário inválido.'
        ]);
        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "SELECT
                id,
                usuario_id,
                tipo,
                marca,
                modelo,
                ano,
                combustivel,
                consumo_medio
             FROM veiculos
             WHERE usuario_id = :usuario_id
             ORDER BY id DESC"
        );

        $stmt->execute([
            'usuario_id' => $usuarioId
        ]);

        $veiculos = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            'status' => true,
            'veiculos' => $veiculos
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao listar veículos.'
        ]);
    }

    exit;
}


/*
|--------------------------------------------------------------------------
| EXCLUIR VEÍCULO
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] === 'DELETE') {

    $veiculoId = (int) ($dados['id'] ?? 0);

    if ($usuarioId <= 0 || $veiculoId <= 0) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Dados inválidos.'
        ]);
        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "DELETE FROM veiculos
             WHERE id = :id
             AND usuario_id = :usuario_id"
        );

        $stmt->execute([
            'id' => $veiculoId,
            'usuario_id' => $usuarioId
        ]);

        if ($stmt->rowCount() === 0) {

            echo json_encode([
                'status' => false,
                'mensagem' => 'Veículo não encontrado.'
            ]);

            exit;
        }

        echo json_encode([
            'status' => true,
            'mensagem' => 'Veículo excluído com sucesso!'
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao excluir veículo.'
        ]);
    }

    exit;
}


/*
|--------------------------------------------------------------------------
| EDITAR VEÍCULO
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] === 'PUT') {

    $veiculoId = (int) ($dados['id'] ?? 0);

    $tipo = trim($dados['tipo'] ?? 'carro');
    $marca = trim($dados['marca'] ?? '');
    $modelo = trim($dados['modelo'] ?? '');
    $ano = $dados['ano'] ?? null;
    $combustivel = trim($dados['combustivel'] ?? '');
    $consumoMedio = $dados['consumo_medio'] ?? null;

    if (
        $usuarioId <= 0 ||
        $veiculoId <= 0 ||
        $marca === '' ||
        $modelo === '' ||
        $combustivel === '' ||
        $consumoMedio === null ||
        $consumoMedio === ''
    ) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Dados obrigatórios não preenchidos.'
        ]);
        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "UPDATE veiculos
             SET
                tipo = :tipo,
                marca = :marca,
                modelo = :modelo,
                ano = :ano,
                combustivel = :combustivel,
                consumo_medio = :consumo_medio
             WHERE id = :id
             AND usuario_id = :usuario_id"
        );

        $stmt->execute([
            'tipo' => $tipo,
            'marca' => $marca,
            'modelo' => $modelo,
            'ano' => $ano,
            'combustivel' => $combustivel,
            'consumo_medio' => $consumoMedio,
            'id' => $veiculoId,
            'usuario_id' => $usuarioId
        ]);

        echo json_encode([
            'status' => true,
            'mensagem' => 'Veículo atualizado com sucesso!'
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao atualizar veículo.'
        ]);
    }

    exit;
}


/*
|--------------------------------------------------------------------------
| CADASTRAR VEÍCULO
|--------------------------------------------------------------------------
*/

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Método não permitido.'
    ]);

    exit;
}

$tipo = trim($dados['tipo'] ?? 'carro');
$marca = trim($dados['marca'] ?? '');
$modelo = trim($dados['modelo'] ?? '');
$ano = $dados['ano'] ?? null;
$combustivel = trim($dados['combustivel'] ?? '');
$consumoMedio = $dados['consumo_medio'] ?? null;

if (
    $usuarioId <= 0 ||
    $marca === '' ||
    $modelo === '' ||
    $combustivel === '' ||
    $consumoMedio === null ||
    $consumoMedio === ''
) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Marca, modelo, combustível e consumo médio são obrigatórios.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "INSERT INTO veiculos
        (
            usuario_id,
            tipo,
            marca,
            modelo,
            ano,
            combustivel,
            consumo_medio
        )
        VALUES
        (
            :usuario_id,
            :tipo,
            :marca,
            :modelo,
            :ano,
            :combustivel,
            :consumo_medio
        )"
    );

    $stmt->execute([
        'usuario_id' => $usuarioId,
        'tipo' => $tipo,
        'marca' => $marca,
        'modelo' => $modelo,
        'ano' => $ano,
        'combustivel' => $combustivel,
        'consumo_medio' => $consumoMedio
    ]);

    $id = (int) $pdo->lastInsertId();

    /*
     * Web continua funcionando
     */
    if (stripos($contentType, 'application/json') === false) {

        header('Location: ../../veiculos.php');
        exit;
    }

    echo json_encode([
        'status' => true,
        'mensagem' => 'Veículo cadastrado com sucesso!',
        'id' => $id,
        'usuario_id' => $usuarioId
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao cadastrar veículo.'
    ]);
}