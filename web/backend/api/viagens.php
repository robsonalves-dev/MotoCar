<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$metodo = $_SERVER['REQUEST_METHOD'];

if ($metodo === 'POST') {

    $dados = json_decode(file_get_contents('php://input'), true);

    $usuarioId = (int) ($dados['usuario_id'] ?? 0);
    $veiculoId = (int) ($dados['veiculo_id'] ?? 0);

    $origem = trim($dados['origem'] ?? '');
    $destino = trim($dados['destino'] ?? '');

    $distanciaKm = $dados['distancia_km'] ?? null;
    $tempoMinutos = $dados['tempo_minutos'] ?? null;

    $combustivel = trim($dados['combustivel'] ?? '');
    $consumoKmL = $dados['consumo_km_l'] ?? null;
    $precoCombustivel = $dados['preco_combustivel'] ?? null;

    $litrosNecessarios = $dados['litros_necessarios'] ?? null;
    $custoViagem = $dados['custo_viagem'] ?? null;

    if (
        $usuarioId <= 0 ||
        $veiculoId <= 0 ||
        $origem === '' ||
        $destino === '' ||
        $distanciaKm === null ||
        $tempoMinutos === null ||
        $combustivel === '' ||
        $consumoKmL === null ||
        $precoCombustivel === null ||
        $litrosNecessarios === null ||
        $custoViagem === null
    ) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Todos os dados da viagem são obrigatórios.'
        ]);
        exit;
    }

    try {

        $stmt = $pdo->prepare(
            "INSERT INTO viagens
            (
                usuario_id,
                veiculo_id,
                origem,
                destino,
                distancia_km,
                tempo_minutos,
                combustivel,
                consumo_km_l,
                preco_combustivel,
                litros_necessarios,
                custo_viagem
            )
            VALUES
            (
                :usuario_id,
                :veiculo_id,
                :origem,
                :destino,
                :distancia_km,
                :tempo_minutos,
                :combustivel,
                :consumo_km_l,
                :preco_combustivel,
                :litros_necessarios,
                :custo_viagem
            )"
        );

        $stmt->execute([
            'usuario_id' => $usuarioId,
            'veiculo_id' => $veiculoId,
            'origem' => $origem,
            'destino' => $destino,
            'distancia_km' => $distanciaKm,
            'tempo_minutos' => $tempoMinutos,
            'combustivel' => $combustivel,
            'consumo_km_l' => $consumoKmL,
            'preco_combustivel' => $precoCombustivel,
            'litros_necessarios' => $litrosNecessarios,
            'custo_viagem' => $custoViagem
        ]);

        echo json_encode([
            'status' => true,
            'mensagem' => 'Viagem registrada com sucesso!',
            'id' => (int) $pdo->lastInsertId()
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao registrar a viagem.'
        ]);
    }

    exit;
}

if ($metodo === 'GET') {

    $usuarioId = (int) ($_GET['usuario_id'] ?? 1);

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
                veiculo_id,
                origem,
                destino,
                distancia_km,
                tempo_minutos,
                combustivel,
                consumo_km_l,
                preco_combustivel,
                litros_necessarios,
                custo_viagem,
                created_at
             FROM viagens
             WHERE usuario_id = :usuario_id
             ORDER BY id DESC"
        );

        $stmt->execute([
            'usuario_id' => $usuarioId
        ]);

        echo json_encode([
            'status' => true,
            'viagens' => $stmt->fetchAll()
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao listar as viagens.'
        ]);
    }

    exit;
}

if ($metodo === 'DELETE') {

    $dados = json_decode(file_get_contents('php://input'), true);

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
            "DELETE FROM viagens
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
                'mensagem' => 'Viagem não encontrada.'
            ]);
            exit;
        }

        echo json_encode([
            'status' => true,
            'mensagem' => 'Viagem excluída com sucesso!'
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            'status' => false,
            'mensagem' => 'Erro ao excluir a viagem.'
        ]);
    }

    exit;
}

echo json_encode([
    'status' => false,
    'mensagem' => 'Método não permitido.'
]);