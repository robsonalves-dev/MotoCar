<?php
session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];

function h($valor) {
    return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8');
}

/*
|--------------------------------------------------------------------------
| Buscar abastecimentos
|--------------------------------------------------------------------------
*/

$url = 'https://motocarweb.com.br/backend/api/abastecimentos_lista.php?usuario_id=' . $usuarioId;

$ch = curl_init($url);

curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_HTTPHEADER => ['Accept: application/json']
]);

$resposta = curl_exec($ch);
curl_close($ch);

$dados = json_decode($resposta ?: '', true);

$abastecimentos = [];

if (is_array($dados)) {
    $abastecimentos = $dados['abastecimentos'] ?? [];
}

/*
|--------------------------------------------------------------------------
| Buscar veículos
|--------------------------------------------------------------------------
*/

require_once 'backend/config.php';

try {
    $stmt = $pdo->prepare(
        "SELECT id, marca, modelo, ano, combustivel
         FROM veiculos
         WHERE usuario_id = :usuario_id
         ORDER BY id DESC"
    );

    $stmt->execute([
        'usuario_id' => $usuarioId
    ]);

    $veiculos = $stmt->fetchAll();

} catch (PDOException $e) {
    $veiculos = [];
}
?>

<!DOCTYPE html>
<html lang="pt-BR">

<head>

<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Abastecimentos - MotoCar</title>

<link rel="stylesheet" href="assets/css/abastecimentos.css?v=17">

</head>

<body>

<main data-usuario-id="<?= $usuarioId ?>">

    <!-- LISTA DE ABASTECIMENTOS -->

    <section class="lista-abastecimentos" id="listaAbastecimentos">

        <?php if (empty($abastecimentos)): ?>

            <div class="card-abastecimento">
                <p>Nenhum abastecimento cadastrado.</p>
            </div>

        <?php else: ?>

            <?php foreach ($abastecimentos as $item): ?>

                <?php

                $id = (int)($item['id'] ?? 0);

                $veiculo = $item['veiculo']
                    ?? $item['modelo']
                    ?? 'Meu veículo';

                $combustivel = $item['combustivel'] ?? '-';

                $litros = (float)($item['litros'] ?? 0);

                $valor = (float)(
                    $item['valor_total']
                    ?? $item['valor_pago']
                    ?? 0
                );

                $km = (float)($item['quilometragem'] ?? 0);

                $data = $item['data_abastecimento']
                    ?? $item['data']
                    ?? '-';

                ?>

                <article
                    class="card-abastecimento"
                    data-id="<?= $id ?>"
                    data-veiculo="<?= h($veiculo) ?>"
                    data-combustivel="<?= h($combustivel) ?>"
                    data-litros="<?= h($litros) ?>"
                    data-valor="<?= h($valor) ?>"
                    data-km="<?= h($km) ?>"
                    data-data="<?= h($data) ?>"
                >

                    <div class="card-topo">

                        <div class="icone-combustivel">
                            ⛽
                        </div>

                        <div class="dados-veiculo">

                            <strong>
                                <?= h($veiculo) ?>
                            </strong>

                            <span>
                                <?= h($combustivel) ?>
                            </span>

                        </div>

                        <details class="menu-acoes">

                            <summary>⋮</summary>

                            <div>

                                <button
                                    type="button"
                                    onclick="editarAbastecimento(this)"
                                >
                                    Editar
                                </button>

                            </div>

                        </details>

                    </div>

                    <hr class="linha">

                   <div class="detalhes-principais">
    <strong class="valor-litros">
        <?= rtrim(rtrim(number_format($litros, 3, ',', '.'), '0'), ',') ?> litros
    </strong>

                        <span class="valor-abastecimento">
                            R$ <?= number_format($valor, 2, ',', '.') ?>
                        </span>

                    </div>

                    <div class="detalhes-secundarios">

                        <span>
                            ◉ <?= number_format($km, 2, ',', '.') ?> km
                        </span>

                        <span>
                            ▢ <?= h($data) ?>
                        </span>

                    </div>

                </article>

            <?php endforeach; ?>

        <?php endif; ?>

    </section>


    <!-- FORMULÁRIO DE NOVO ABASTECIMENTO -->

    <section class="formulario-novo" id="formularioNovo">

        <h2>Novo abastecimento</h2>

        <form
            action="backend/api/abastecimentos.php"
            method="POST"
        >

            <label>Veículo</label>

            <select name="veiculo_id" required>

                <option value="">
                    Selecione seu veículo
                </option>

                <?php foreach ($veiculos as $veiculo): ?>

                    <option value="<?= (int)$veiculo['id'] ?>">

                        <?= h(
                            $veiculo['marca'] . ' ' . $veiculo['modelo']
                        ) ?>

                    </option>

                <?php endforeach; ?>

            </select>


            <label>Combustível</label>

            <select name="combustivel" required>

                <option value="">
                    Combustível
                </option>

                <option value="gasolina">
                    Gasolina
                </option>

                <option value="etanol">
                    Etanol
                </option>

            </select>


            <label>Litros</label>

            <input
                type="number"
                step="0.01"
                name="litros"
                placeholder="Litros"
                required
            >


            <label>Valor pago</label>

            <input
                type="number"
                step="0.01"
                name="valor_pago"
                placeholder="Valor pago"
                required
            >


            <label>Quilometragem</label>

            <input
                type="number"
                step="0.01"
                name="quilometragem"
                placeholder="Quilometragem atual"
                required
            >


            <label>Data do abastecimento</label>

            <input
                type="date"
                name="data"
                required
            >


            <button type="submit">
                Salvar abastecimento
            </button>

        </form>

    </section>


    <!-- FORMULÁRIO DE EDIÇÃO -->

    <section class="formulario-edicao" id="formularioEdicao">

        <h2>Editar abastecimento</h2>

        <form id="formEditarAbastecimento">

            <input
                type="hidden"
                id="editarId"
            >

            <label>Combustível</label>

            <select id="editarCombustivel" required>

                <option value="gasolina">
                    Gasolina
                </option>

                <option value="etanol">
                    Etanol
                </option>

            </select>


            <label>Litros</label>

            <input
                type="number"
                step="0.01"
                id="editarLitros"
                required
            >


            <label>Valor pago</label>

            <input
                type="number"
                step="0.01"
                id="editarValor"
                required
            >


            <label>Quilometragem</label>

            <input
                type="number"
                step="0.01"
                id="editarKm"
                required
            >


            <label>Data</label>

            <input
                type="date"
                id="editarData"
                required
            >


            <button type="submit">
                Salvar alterações
            </button>

            <button
                type="button"
                class="botao-cancelar"
                onclick="cancelarEdicao()"
            >
                Cancelar
            </button>

        </form>

    </section>

</main>


<!-- BOTÃO ADICIONAR -->

<button
    class="botao-adicionar"
    id="botaoAdicionar"
    type="button"
    onclick="abrirFormulario()"
>
    ＋ Adicionar abastecimento
</button>


<!-- JAVASCRIPT EXTERNO -->

<script src="assets/js/abastecimentos.js?v=11"></script>

</body>
</html>