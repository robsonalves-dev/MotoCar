<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$municipioSelecionado = $_GET['municipio'] ?? '';
$combustivel = $_GET['combustivel'] ?? 'Gasolina';

$municipios = [];
$precos = [];
$postoMaisBarato = null;
$economiaMaxima = null;
$mensagem = '';

/* =========================
   MUNICÍPIOS
========================= */

$urlMunicipios =
    'https://motocarweb.com.br/backend/api/anp_municipios.php';

$ch = curl_init($urlMunicipios);

curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 15,
    CURLOPT_SSL_VERIFYPEER => true
]);

$resposta = curl_exec($ch);

curl_close($ch);

$dadosMunicipios = json_decode($resposta, true);

if (
    isset($dadosMunicipios['status']) &&
    $dadosMunicipios['status'] === true
) {
    $municipios = $dadosMunicipios['municipios'] ?? [];
}

/* =========================
   PREÇOS
========================= */

if ($municipioSelecionado !== '') {

    $urlPrecos =
        'https://motocarweb.com.br/backend/api/anp.php'
        . '?municipio=' . urlencode($municipioSelecionado)
        . '&combustivel=' . urlencode($combustivel);

    $ch = curl_init($urlPrecos);

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_SSL_VERIFYPEER => true
    ]);

    $resposta = curl_exec($ch);

    curl_close($ch);

    $dadosPrecos = json_decode($resposta, true);

    if (
        isset($dadosPrecos['status']) &&
        $dadosPrecos['status'] === true
    ) {

        $precos = $dadosPrecos['precos'] ?? [];

        $postoMaisBarato =
            $dadosPrecos['posto_mais_barato'] ?? null;

        $economiaMaxima =
            $dadosPrecos['economia_maxima_por_litro'] ?? null;

        if (empty($precos)) {
            $mensagem =
                'Nenhum preço encontrado para essa consulta.';
        }

    } else {

        $mensagem =
            $dadosPrecos['mensagem'] ??
            'Erro ao consultar os preços.';
    }
}

/* =========================
   FORMATA PREÇO
========================= */

function formatarPreco($valor)
{
    if (!is_numeric($valor)) {
        return '-';
    }

    return number_format(
        (float) $valor,
        2,
        ',',
        '.'
    );
}

/* =========================
   ENDEREÇO PARA GOOGLE MAPS
========================= */

function gerarLinkMaps($posto)
{
    $endereco = trim(
        ($posto['endereco'] ?? '') . ' ' .
        ($posto['numero'] ?? '') . ', ' .
        ($posto['bairro'] ?? '') . ', ' .
        ($posto['municipio'] ?? '') . ', SP, Brasil'
    );

    return 'https://www.google.com/maps/dir/?api=1&destination='
        . urlencode($endereco);
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

    <title>Preços dos combustíveis - MotoCar</title>

    <link
        rel="stylesheet"
        href="assets/css/postos.css?v=2"
    >

</head>

<body>

<main>

    <h1>Preços da ANP</h1>

    <p class="subtitulo">
        Consulte os preços dos combustíveis por município.
    </p>

    <form method="GET" class="formulario">

        <label>
            Município
        </label>

        <div class="campo-pesquisa">

            <input
                type="text"
                id="pesquisaMunicipio"
                placeholder="Digite o município..."
                autocomplete="off"
                value="<?= htmlspecialchars($municipioSelecionado) ?>"
            >

            <div id="listaMunicipios"></div>

        </div>

        <input
            type="hidden"
            name="municipio"
            id="municipioSelecionado"
            value="<?= htmlspecialchars($municipioSelecionado) ?>"
        >

        <label>
            Combustível
        </label>

        <select name="combustivel">

            <option
                value="Gasolina"
                <?= $combustivel === 'Gasolina'
                    ? 'selected'
                    : '' ?>
            >
                Gasolina
            </option>

            <option
                value="Etanol"
                <?= $combustivel === 'Etanol'
                    ? 'selected'
                    : '' ?>
            >
                Etanol
            </option>

        </select>

        <button type="submit">
            🔍 Buscar preços
        </button>

    </form>


    <?php if ($postoMaisBarato !== null): ?>

        <section class="mais-barato">

            <h2>
                ⭐ Posto mais barato
            </h2>

            <h3>
                <?= htmlspecialchars(
                    $postoMaisBarato['posto'] ?? 'Posto'
                ) ?>
            </h3>

            <p>
                <?= htmlspecialchars(
                    $postoMaisBarato['endereco'] ?? ''
                ) ?>,

                <?= htmlspecialchars(
                    $postoMaisBarato['numero'] ?? ''
                ) ?>
            </p>

            <p>
                Bairro:
                <?= htmlspecialchars(
                    $postoMaisBarato['bairro'] ?? '-'
                ) ?>
            </p>

            <p>
                CEP:
                <?= htmlspecialchars(
                    $postoMaisBarato['cep'] ?? '-'
                ) ?>
            </p>

            <div class="posto-preco">

                R$
                <?= formatarPreco(
                    $postoMaisBarato['preco'] ?? null
                ) ?>

            </div>

            <?php if ($economiaMaxima !== null): ?>

                <p class="economia">

                    Economia máxima:
                    R$
                    <?= formatarPreco($economiaMaxima) ?>
                    por litro

                </p>

            <?php endif; ?>

            <a
                class="botao-rota"
                href="<?= htmlspecialchars(
                    gerarLinkMaps($postoMaisBarato)
                ) ?>"
                target="_blank"
                rel="noopener noreferrer"
            >
                📍 Traçar rota
            </a>

            <p class="data">

                Data da coleta:
                <?= htmlspecialchars(
                    $postoMaisBarato['data_coleta'] ?? '-'
                ) ?>

            </p>

        </section>

    <?php endif; ?>


    <?php if ($mensagem !== ''): ?>

        <div class="mensagem">
            <?= htmlspecialchars($mensagem) ?>
        </div>

    <?php endif; ?>


    <?php if (!empty($precos)): ?>

        <h2 class="titulo-resultados">
            Preços encontrados
        </h2>

        <?php foreach ($precos as $preco): ?>

            <article class="preco-card">

                <h3>
                    ⛽
                    <?= htmlspecialchars(
                        $preco['posto'] ?? 'Posto'
                    ) ?>
                </h3>

                <p>
                    <?= htmlspecialchars(
                        $preco['endereco'] ?? ''
                    ) ?>,

                    <?= htmlspecialchars(
                        $preco['numero'] ?? ''
                    ) ?>
                </p>

                <p>
                    Bairro:
                    <?= htmlspecialchars(
                        $preco['bairro'] ?? '-'
                    ) ?>
                </p>

                <p>
                    CEP:
                    <?= htmlspecialchars(
                        $preco['cep'] ?? '-'
                    ) ?>
                </p>

                <p>
                    <?= htmlspecialchars(
                        $preco['municipio'] ?? ''
                    ) ?>

                    ·

                    <?= htmlspecialchars(
                        $preco['data_coleta'] ?? '-'
                    ) ?>
                </p>

                <strong>
                    R$
                    <?= formatarPreco(
                        $preco['preco'] ?? null
                    ) ?>
                </strong>

                <?php if (
                    isset($preco['economia_por_litro'])
                    && $preco['economia_por_litro'] !== null
                ): ?>

                    <p class="preco-economia">

                        Economiza R$
                        <?= formatarPreco(
                            $preco['economia_por_litro']
                        ) ?>
                        por litro

                    </p>

                <?php endif; ?>

                <a
                    class="botao-rota"
                    href="<?= htmlspecialchars(
                        gerarLinkMaps($preco)
                    ) ?>"
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    📍 Traçar rota
                </a>

            </article>

        <?php endforeach; ?>

    <?php endif; ?>

</main>

<script>
const municipios = <?= json_encode(
    $municipios,
    JSON_UNESCAPED_UNICODE
) ?>;
</script>

<script src="assets/js/postos.js?v=2"></script>

</body>

</html>