<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$endereco = trim($_GET['endereco'] ?? '');

if ($endereco === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe o endereço.'
    ]);
    exit;
}

$url = 'https://nominatim.openstreetmap.org/search?' . http_build_query([
    'q' => $endereco,
    'format' => 'json',
    'limit' => 1,
    'countrycodes' => 'br'
]);

$contexto = stream_context_create([
    'http' => [
        'method' => 'GET',
        'header' => "User-Agent: MotoCar/1.0\r\n"
    ]
]);

$resposta = @file_get_contents($url, false, $contexto);

if ($resposta === false) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Não foi possível consultar o OpenStreetMap.'
    ]);
    exit;
}

$dados = json_decode($resposta, true);

if (empty($dados)) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Endereço não encontrado.'
    ]);
    exit;
}

echo json_encode([
    'status' => true,
    'endereco' => $dados[0]['display_name'],
    'latitude' => (float) $dados[0]['lat'],
    'longitude' => (float) $dados[0]['lon']
]);