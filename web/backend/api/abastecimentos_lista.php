<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}


/*
|--------------------------------------------------------------------------
| USUÁRIO LOGADO
|--------------------------------------------------------------------------
*/

$usuarioId = (int) ($_GET['usuario_id'] ?? 0);

if ($usuarioId <= 0) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Usuário inválido.'
    ]);
    exit;
}


/*
|--------------------------------------------------------------------------
| LISTAR ABASTECIMENTOS
|--------------------------------------------------------------------------
*/

try {

    $stmt = $pdo->prepare(
        "SELECT
            id,
            usuario_id,
            veiculo_id,
            combustivel,
            litros,
            valor_total,
            quilometragem,
            data_abastecimento
         FROM abastecimentos
         WHERE usuario_id = :usuario_id
         ORDER BY data_abastecimento DESC, id DESC"
    );

    $stmt->execute([
        'usuario_id' => $usuarioId
    ]);

    $abastecimentos = $stmt->fetchAll(PDO::FETCH_ASSOC);


    /*
     * Retorna os dados em JSON
     */

    echo json_encode([
        'status' => true,
        'abastecimentos' => $abastecimentos
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao listar abastecimentos.'
    ]);
}