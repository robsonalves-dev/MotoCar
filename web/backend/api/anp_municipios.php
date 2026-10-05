<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

try {

    $stmt = $pdo->query(
        "SELECT DISTINCT municipio
         FROM precos_anp
         WHERE municipio IS NOT NULL
         AND municipio <> ''
         ORDER BY municipio ASC"
    );

    $municipios = $stmt->fetchAll(PDO::FETCH_COLUMN);

    echo json_encode([
        'status' => true,
        'total' => count($municipios),
        'municipios' => $municipios
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao consultar os municípios.'
    ]);
}