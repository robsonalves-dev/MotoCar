<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');

try {
    $stmt = $pdo->query("SELECT COUNT(*) AS total FROM usuarios");
    $resultado = $stmt->fetch();

    echo json_encode([
        'status' => true,
        'mensagem' => 'API MotoCar conectada ao banco!',
        'usuarios' => (int) $resultado['total']
    ]);

} catch (PDOException $e) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao acessar o banco de dados.'
    ]);
}