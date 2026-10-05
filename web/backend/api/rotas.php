<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$origem = trim($_GET['origem'] ?? '');
$destino = trim($_GET['destino'] ?? '');

if ($origem === '' || $destino === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe a origem e o destino.'
    ]);
    exit;
}

function obterCoordenadas(string $endereco): ?array
{
    $url = 'https://nominatim.openstreetmap.org/search?' . http_build_query([
        'q' => $endereco,
        'format' => 'json',
        'limit' => 1,
        'countrycodes' => 'br'
    ]);

    $ch = curl_init($url);

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_USERAGENT => 'MotoCar/1.0',
    ]);

    $resposta = curl_exec($ch);
    curl_close($ch);

    if ($resposta === false || $resposta === '') {
        return null;
    }

    $dados = json_decode($resposta, true);

    if (empty($dados[0])) {
        return null;
    }

    return [
        'latitude' => (float) $dados[0]['lat'],
        'longitude' => (float) $dados[0]['lon']
    ];
}

try {

    $coordenadasOrigem = obterCoordenadas($origem);
    $coordenadasDestino = obterCoordenadas($destino);

    if ($coordenadasOrigem === null) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Não foi possível localizar a origem.'
        ]);
        exit;
    }

    if ($coordenadasDestino === null) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Não foi possível localizar o destino.'
        ]);
        exit;
    }

    $urlRota =
        'https://router.project-osrm.org/route/v1/driving/' .
        $coordenadasOrigem['longitude'] . ',' .
        $coordenadasOrigem['latitude'] . ';' .
        $coordenadasDestino['longitude'] . ',' .
        $coordenadasDestino['latitude'] .
        '?overview=false';

    $ch = curl_init($urlRota);

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_USERAGENT => 'MotoCar/1.0',
    ]);

    $respostaRota = curl_exec($ch);
    curl_close($ch);

    if ($respostaRota === false || $respostaRota === '') {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Não foi possível calcular a rota.'
        ]);
        exit;
    }

    $dadosRota = json_decode($respostaRota, true);

    if (
        empty($dadosRota['routes']) ||
        !isset($dadosRota['routes'][0])
    ) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Nenhuma rota encontrada.'
        ]);
        exit;
    }

    $rota = $dadosRota['routes'][0];

    $distanciaKm = $rota['distance'] / 1000;
    $duracaoMinutos = $rota['duration'] / 60;

    echo json_encode([
        'status' => true,
        'origem' => [
            'endereco' => $origem,
            'latitude' => $coordenadasOrigem['latitude'],
            'longitude' => $coordenadasOrigem['longitude']
        ],
        'destino' => [
            'endereco' => $destino,
            'latitude' => $coordenadasDestino['latitude'],
            'longitude' => $coordenadasDestino['longitude']
        ],
        'rota' => [
            'distancia_km' => round($distanciaKm, 2),
            'tempo_minutos' => round($duracaoMinutos, 1)
        ]
    ]);

} catch (Throwable $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao calcular a rota.'
    ]);
}