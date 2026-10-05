<?php

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Método não permitido.'
    ]);
    exit;
}

$dados = json_decode(file_get_contents('php://input'), true);

$precoGasolina = (float) ($dados['preco_gasolina'] ?? 0);
$precoEtanol = (float) ($dados['preco_etanol'] ?? 0);
$consumoGasolina = (float) ($dados['consumo_gasolina'] ?? 0);
$consumoEtanol = (float) ($dados['consumo_etanol'] ?? 0);

if (
    $precoGasolina <= 0 ||
    $precoEtanol <= 0 ||
    $consumoGasolina <= 0 ||
    $consumoEtanol <= 0
) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe preços e consumos válidos.'
    ]);
    exit;
}

$custoKmGasolina = $precoGasolina / $consumoGasolina;
$custoKmEtanol = $precoEtanol / $consumoEtanol;

$limiteEtanol = $precoGasolina * 0.70;

if ($custoKmEtanol < $custoKmGasolina) {
    $maisEconomico = 'etanol';
} elseif ($custoKmEtanol > $custoKmGasolina) {
    $maisEconomico = 'gasolina';
} else {
    $maisEconomico = 'equivalente';
}

echo json_encode([
    'status' => true,
    'preco_gasolina' => $precoGasolina,
    'preco_etanol' => $precoEtanol,
    'consumo_gasolina' => $consumoGasolina,
    'consumo_etanol' => $consumoEtanol,
    'custo_km_gasolina' => $custoKmGasolina,
    'custo_km_etanol' => $custoKmEtanol,
    'limite_etanol' => $limiteEtanol,
    'mais_economico' => $maisEconomico
]);