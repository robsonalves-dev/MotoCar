<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];

$url = 'https://motocarweb.com.br/backend/api/abastecimentos_lista.php?usuario_id=' . $usuarioId;

$ch = curl_init($url);

curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_SSL_VERIFYPEER => true
]);

$resposta = curl_exec($ch);
curl_close($ch);

$dados = json_decode($resposta, true);

$abastecimentos = [];

if (isset($dados['status']) && $dados['status'] === true) {
    $abastecimentos = $dados['abastecimentos'] ?? [];
}

/* PERÍODO */

$periodo = $_GET['periodo'] ?? 'Todos';

if ($periodo !== 'Todos') {

    $meses = match ($periodo) {
        '3 meses' => 3,
        '6 meses' => 6,
        '12 meses' => 12,
        default => 0
    };

    if ($meses > 0) {

        $dataInicial = strtotime("-$meses months");

        $abastecimentos = array_filter(
            $abastecimentos,
            function ($item) use ($dataInicial) {

                $data = strtotime(
                    $item['data_abastecimento'] ?? ''
                );

                return $data !== false &&
                       $data >= $dataInicial;
            }
        );
    }
}

/* CÁLCULOS */

$totalGasto = 0;
$totalLitros = 0;
$distanciaTotal = 0;

$abastecimentos = array_values($abastecimentos);

foreach ($abastecimentos as $i => $item) {

    $valor = (float) str_replace(
        ',',
        '.',
        $item['valor_total'] ?? 0
    );

    $litros = (float) str_replace(
        ',',
        '.',
        $item['litros'] ?? 0
    );

    $totalGasto += $valor;
    $totalLitros += $litros;

    if ($i < count($abastecimentos) - 1) {

        $kmAtual = (float) str_replace(
            ',',
            '.',
            $item['quilometragem'] ?? 0
        );

        $kmAnterior = (float) str_replace(
            ',',
            '.',
            $abastecimentos[$i + 1]['quilometragem'] ?? 0
        );

        $distancia = $kmAtual - $kmAnterior;

        if ($distancia > 0) {
            $distanciaTotal += $distancia;
        }
    }
}

$consumoMedio = 0;

if ($totalLitros > 0 && $distanciaTotal > 0) {
    $consumoMedio = $distanciaTotal / $totalLitros;
}

$custoMedioKm = 0;

if ($distanciaTotal > 0) {
    $custoMedioKm = $totalGasto / $distanciaTotal;
}

?>

<!DOCTYPE html>
<html lang="pt-BR">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Análise do histórico - MotoCar</title>
    <link rel="stylesheet" href="assets/css/analise_historico.css?v=5">

</head>

<body>

<main>

    <h1>Análise do histórico</h1>

    <form method="GET">

        <label>Período</label>

        <select name="periodo" onchange="this.form.submit()">

            <option value="Todos"
                <?= $periodo === 'Todos' ? 'selected' : '' ?>>
                Todos
            </option>

            <option value="3 meses"
                <?= $periodo === '3 meses' ? 'selected' : '' ?>>
                Últimos 3 meses
            </option>

            <option value="6 meses"
                <?= $periodo === '6 meses' ? 'selected' : '' ?>>
                Últimos 6 meses
            </option>

            <option value="12 meses"
                <?= $periodo === '12 meses' ? 'selected' : '' ?>>
                Últimos 12 meses
            </option>

        </select>

    </form>

    <hr>

    <h2>Resumo</h2>

    <p>
        <strong>Total gasto:</strong>
        R$ <?= number_format($totalGasto, 2, ',', '.') ?>
    </p>

    <p>
        <strong>Total abastecido:</strong>
        <?= number_format($totalLitros, 2, ',', '.') ?> L
    </p>

    <p>
        <strong>Consumo médio:</strong>
        <?= $consumoMedio > 0
            ? number_format($consumoMedio, 2, ',', '.') . ' km/l'
            : '-' ?>
    </p>

    <p>
        <strong>Custo médio por km:</strong>
        <?= $custoMedioKm > 0
            ? 'R$ ' . number_format($custoMedioKm, 2, ',', '.')
            : '-' ?>
    </p>

    <hr>

    <h2>Abastecimentos do período</h2>

    <?php if (empty($abastecimentos)): ?>

        <p>Nenhum abastecimento encontrado no período.</p>

    <?php else: ?>

        <?php foreach ($abastecimentos as $item): ?>

            <div>

                <strong>
                    <?= htmlspecialchars(
                        $item['combustivel'] ?? 'Combustível'
                    ) ?>
                </strong>

                <p>
                    Data:
                    <?= htmlspecialchars(
                        $item['data_abastecimento'] ?? '-'
                    ) ?>
                </p>

                <p>
                    Litros:
                    <?= number_format(
                        (float)($item['litros'] ?? 0),
                        2,
                        ',',
                        '.'
                    ) ?> L
                </p>

                <p>
                    Valor:
                    R$
                    <?= number_format(
                        (float)($item['valor_total'] ?? 0),
                        2,
                        ',',
                        '.'
                    ) ?>
                </p>

                <p>
                    KM:
                    <?= number_format(
                        (float)($item['quilometragem'] ?? 0),
                        2,
                        ',',
                        '.'
                    ) ?>
                </p>

                <hr>

            </div>

        <?php endforeach; ?>

    <?php endif; ?>

</main>

</body>

</html>