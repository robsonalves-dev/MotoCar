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

$distanciaKm = (float) ($dados['distancia_km'] ?? 0);
$consumoKmL = (float) ($dados['consumo_km_l'] ?? 0);
$precoCombustivel = (float) ($dados['preco_combustivel'] ?? 0);

if (
    $distanciaKm <= 0 ||
    $consumoKmL <= 0 ||
    $precoCombustivel <= 0
) {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe distância, consumo e preço válidos.'
    ]);
    exit;
}

$litrosNecessarios = $distanciaKm / $consumoKmL;

$custoViagem = $litrosNecessarios * $precoCombustivel;

echo json_encode([
    'status' => true,
    'distancia_km' => $distanciaKm,
    'consumo_km_l' => $consumoKmL,
    'preco_combustivel' => $precoCombustivel,
    'litros_necessarios' => round($litrosNecessarios, 2),
    'custo_viagem' => round($custoViagem, 2)
]);