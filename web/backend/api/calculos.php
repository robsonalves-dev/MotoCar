<?php

require_once '../config.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

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
            v.id,
            v.marca,
            v.modelo,
            v.combustivel,
            v.consumo_medio
         FROM veiculos v
         WHERE v.usuario_id = :usuario_id
         ORDER BY v.id ASC
         LIMIT 1"
    );

    $stmt->execute([
        'usuario_id' => $usuarioId
    ]);

    $veiculo = $stmt->fetch();

    if (!$veiculo) {
        echo json_encode([
            'status' => false,
            'mensagem' => 'Nenhum veículo cadastrado.'
        ]);
        exit;
    }

    $stmt = $pdo->prepare(
        "SELECT
            id,
            litros,
            valor_total,
            quilometragem,
            data_abastecimento
         FROM abastecimentos
         WHERE usuario_id = :usuario_id
         AND veiculo_id = :veiculo_id
         ORDER BY quilometragem ASC, id ASC"
    );

    $stmt->execute([
        'usuario_id' => $usuarioId,
        'veiculo_id' => $veiculo['id']
    ]);

    $abastecimentos = $stmt->fetchAll();

    $consumoMedio = null;
    $custoPorKm = null;
    $gastoMensal = 0;

    /*
     * Calcula o consumo real quando existem
     * pelo menos dois abastecimentos.
     */
    if (count($abastecimentos) >= 2) {

        $distanciaTotal = 0;
        $litrosTotal = 0;
        $valorTotal = 0;

        for ($i = 1; $i < count($abastecimentos); $i++) {

            $abastecimentoAnterior = $abastecimentos[$i - 1];
            $abastecimentoAtual = $abastecimentos[$i];

            $distancia = (float) $abastecimentoAtual['quilometragem']
                - (float) $abastecimentoAnterior['quilometragem'];

            if ($distancia > 0) {

                $distanciaTotal += $distancia;

                /*
                 * Consideramos o abastecimento atual
                 * para calcular o consumo do período.
                 */
                $litrosTotal += (float) $abastecimentoAtual['litros'];

                $valorTotal += (float) $abastecimentoAtual['valor_total'];
            }
        }

        if ($distanciaTotal > 0 && $litrosTotal > 0) {

            $consumoMedio = $distanciaTotal / $litrosTotal;

            $custoPorKm = $valorTotal / $distanciaTotal;
        }
    }

    /*
     * Se ainda não houver dados suficientes para calcular
     * o consumo real, utiliza o consumo cadastrado no veículo.
     */
    if ($consumoMedio === null) {

        if (
            $veiculo['consumo_medio'] !== null &&
            (float) $veiculo['consumo_medio'] > 0
        ) {
            $consumoMedio = (float) $veiculo['consumo_medio'];
        }
    }

    /*
     * Se houver apenas um abastecimento, ainda não conseguimos
     * calcular o custo real por km.
     */
    if (
        $custoPorKm === null &&
        count($abastecimentos) === 1 &&
        $consumoMedio !== null
    ) {

        $primeiroAbastecimento = $abastecimentos[0];

        $litros = (float) $primeiroAbastecimento['litros'];
        $valor = (float) $primeiroAbastecimento['valor_total'];

        if ($litros > 0) {

            $precoPorLitro = $valor / $litros;

            $custoPorKm = $precoPorLitro / $consumoMedio;
        }
    }

    /*
     * Gasto realizado no mês atual.
     */
    foreach ($abastecimentos as $abastecimento) {

        $data = strtotime(
            $abastecimento['data_abastecimento']
        );

        if ($data !== false) {

            if (date('Y-m', $data) === date('Y-m')) {

                $gastoMensal += (float) $abastecimento['valor_total'];
            }
        }
    }

    echo json_encode([
        'status' => true,

        'veiculo' => [
            'id' => (int) $veiculo['id'],
            'marca' => $veiculo['marca'],
            'modelo' => $veiculo['modelo'],
            'combustivel' => $veiculo['combustivel'],
            'consumo_medio_cadastrado' =>
                $veiculo['consumo_medio'] !== null
                    ? (float) $veiculo['consumo_medio']
                    : null
        ],

        'calculos' => [
            'consumo_medio_km_l' => $consumoMedio,
            'custo_por_km' => $custoPorKm,
            'gasto_mensal' => $gastoMensal
        ]
    ]);

} catch (PDOException $e) {

    echo json_encode([
        'status' => false,
        'mensagem' => 'Erro ao calcular os dados.'
    ]);
}