
<?php
session_start();
require_once 'backend/config.php';

$usuarioId = $_SESSION['usuario_id'] ?? 0;
$nomeUsuario = $_SESSION['usuario_nome'] ?? 'Motorista';

if ($usuarioId <= 0) {
    header('Location: login.php');
    exit;
}

function h($valor) {
    return htmlspecialchars((string)($valor ?? ''), ENT_QUOTES, 'UTF-8');
}

$veiculos = [];
$erroBanco = false;

try {
    $stmt = $pdo->prepare(
        "SELECT
            id,
            tipo,
            marca,
            modelo,
            ano,
            combustivel,
            consumo_medio
         FROM veiculos
         WHERE usuario_id = :usuario_id
         ORDER BY id DESC"
    );

    $stmt->execute(['usuario_id' => $usuarioId]);
    $veiculos = $stmt->fetchAll(PDO::FETCH_ASSOC);

} catch (PDOException $e) {
    $erroBanco = true;
}
?>

<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Meus veículos - MotoCar</title>

    <link rel="stylesheet" href="assets/css/veiculos.css?v=2">
</head>

<body>

<main class="pagina-veiculos">

    <div class="cabecalho-veiculos">
        <div>
            <h1>Meus veículos</h1>
            <p>Gerencie os veículos cadastrados na sua conta.</p>
        </div>

        <a href="adicionar_veiculo.php" class="btn-adicionar">
            + Adicionar veículo
        </a>
    </div>

    <div class="resumo-veiculos">
        <div class="resumo-info">
            <span class="resumo-label">Veículos cadastrados</span>
            <strong><?= count($veiculos) ?></strong>
        </div>
    </div>

    <?php if ($erroBanco): ?>

        <div class="mensagem-erro">
            Não foi possível carregar seus veículos. Tente novamente.
        </div>

    <?php elseif (empty($veiculos)): ?>

        <div class="estado-vazio">
            <h3>Nenhum veículo cadastrado</h3>
            <p>Adicione seu primeiro veículo para começar a utilizar o MotoCar.</p>

            <a href="adicionar_veiculo.php" class="btn-adicionar">
                Adicionar meu veículo
            </a>
        </div>

    <?php else: ?>

        <section class="lista-veiculos">

            <?php foreach ($veiculos as $veiculo): ?>

                <article class="card-veiculo">

                    <div class="card-veiculo-topo">
                        <div>
                            <span class="veiculo-tipo">
                                <?= h($veiculo['tipo']) ?>
                            </span>

                            <h2>
                                <?= h($veiculo['marca']) ?>
                                <?= h($veiculo['modelo']) ?>
                            </h2>
                        </div>
                    </div>

                    <div class="dados-veiculo">

                        <div class="dado-veiculo">
                            <span>Ano</span>
                            <strong><?= h($veiculo['ano'] ?: 'Não informado') ?></strong>
                        </div>

                        <div class="dado-veiculo">
                            <span>Combustível</span>
                            <strong><?= h($veiculo['combustivel']) ?></strong>
                        </div>

                        <div class="dado-veiculo">
                            <span>Consumo médio</span>
                            <strong>
                                <?= $veiculo['consumo_medio'] !== null
                                    ? h($veiculo['consumo_medio']) . ' km/l'
                                    : 'Não informado' ?>
                            </strong>
                        </div>

                    </div>

                </article>

            <?php endforeach; ?>

        </section>

    <?php endif; ?>

</main>

</body>
</html>
