<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];

$url = 'https://motocarweb.com.br/backend/api/viagens.php?usuario_id=' . $usuarioId;

$ch = curl_init($url);

curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$resposta = curl_exec($ch);

curl_close($ch);

$dados = json_decode($resposta, true);

$viagens = [];

if (isset($dados['status']) && $dados['status'] === true) {
    $viagens = $dados['viagens'] ?? [];
}

?>

<!DOCTYPE html>
<html lang="pt-BR">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Histórico de viagens - MotoCar</title>
    
    <link rel="stylesheet" href="assets/css/historico_viagens.css?v=10">
    
    <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7540081483916932"
     crossorigin="anonymous"></script>
</head>

<body>

    <h1>Histórico de viagens</h1>

    <?php if (empty($viagens)): ?>

        <p>Nenhuma viagem registrada.</p>

    <?php else: ?>

        <?php foreach ($viagens as $viagem): ?>

            <div class="viagem">

                <h3>
                    <?= htmlspecialchars($viagem['origem']) ?>
                    →
                    <?= htmlspecialchars($viagem['destino']) ?>
                </h3>

                <p>
                    Distância:
                    <?= number_format((float)$viagem['distancia_km'], 2, ',', '.') ?>
                    km
                </p>

                <p>
                    Combustível:
                    <?= htmlspecialchars($viagem['combustivel']) ?>
                </p>

                <p>
                    Custo:
                    R$
                    <?= number_format((float)$viagem['custo_viagem'], 2, ',', '.') ?>
                </p>

                <p>
                    Litros:
                    <?= number_format((float)$viagem['litros_necessarios'], 2, ',', '.') ?>
                </p>

                <hr>

            </div>

        <?php endforeach; ?>

    <?php endif; ?>

</body>

</html>