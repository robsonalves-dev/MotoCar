<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$municipio = trim($_GET['municipio'] ?? '');
$combustivel = trim($_GET['combustivel'] ?? '');

if ($municipio === '' || $combustivel === '') {
    echo json_encode([
        'status' => false,
        'mensagem' => 'Informe o município e o combustível.'
    ]);
    exit;
}

try {

    $stmt = $pdo->prepare(
        "SELECT DISTINCT
            p.id,
            p.posto,
            p.endereco,
            p.numero,
            p.bairro,
            p.cep,
            p.municipio,
            p.combustivel,
            p.preco,
            p.data_coleta
         FROM precos_anp p
         WHERE p.municipio = :municipio
         AND p.combustivel = :combustivel
         AND p.preco = (
             SELECT MIN(p2.preco)
             FROM precos_anp p2
             WHERE p2.posto = p.posto
             AND p2.endereco = p.endereco
             AND p2.numero = p.numero
             AND p2.bairro = p.bairro
             AND p2.cep = p.cep
             AND p2.municipio = p.municipio
             AND p2.combustivel = p.combustivel
         )
         ORDER BY p.preco ASC"
    );

    $stmt->execute([
        'municipio' => $municipio,
        'combustivel' => $combustivel
    ]);

    $precos = $stmt->fetchAll();

    $postoMaisBarato = null;
    $precoMaisCaro = null;

    if (!empty($precos)) {

        $postoMaisBarato = $precos[0];

        $ultimoIndice = count($precos) - 1;

        $precoMaisCaro =
            (float) $precos[$ultimoIndice]['preco'];
    }

    foreach ($precos as &$preco) {

        $valor = (float) $preco['preco'];

        if ($precoMaisCaro !== null) {
            $preco['economia_por_litro'] =
                $precoMaisCaro - $valor;
        } else {
            $preco['economia_por_litro'] = 0;
        }
    }

    unset($preco);

    $economiaMaxima = null;

    if (
        $postoMaisBarato !== null &&
        $precoMaisCaro !== null
    ) {
        $economiaMaxima =
            $precoMaisCaro -
            (float) $postoMaisBarato['preco'];
    }

    echo json_encode([
        'status' => true,
        'fonte' => 'ANP',
        'municipio' => $municipio,
        'combustivel' => $combustivel,
        'total' => count($precos),
        'posto_mais_barato' => $postoMaisBarato,
        'preco_mais_caro' => $precoMaisCaro,
        'economia_maxima_por_litro' => $economiaMaxima,
        'precos' => $precos
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao consultar os preços da ANP.'
    ]);
}