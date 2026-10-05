
<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];

$urlApi = 'https://motocarweb.com.br/backend/api/';

/*
|--------------------------------------------------------------------------
| FUNÇÃO PARA CONSULTAR A API
|--------------------------------------------------------------------------
*/

function consultarApiMotoCar($endpoint, $usuarioId, $metodo = 'GET', $dados = null)
{
    global $urlApi;

    $url = $urlApi . $endpoint;

    if ($metodo === 'GET') {
        $url .= '?usuario_id=' . urlencode($usuarioId);
    }

    $ch = curl_init($url);

    $opcoes = [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 20,
        CURLOPT_CONNECTTIMEOUT => 10,
        CURLOPT_HTTPHEADER => [
            'Accept: application/json'
        ]
    ];

    if ($metodo === 'POST') {
        $opcoes[CURLOPT_POST] = true;
        $opcoes[CURLOPT_HTTPHEADER] = [
            'Content-Type: application/json',
            'Accept: application/json'
        ];
        $opcoes[CURLOPT_POSTFIELDS] = json_encode($dados);
    }

    curl_setopt_array($ch, $opcoes);

    $resposta = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    curl_close($ch);

    if ($resposta === false || $httpCode !== 200) {
        return [
            'status' => false,
            'mensagem' => 'Não foi possível consultar a API.'
        ];
    }

    $json = json_decode($resposta, true);

    if (!is_array($json)) {
        return [
            'status' => false,
            'mensagem' => 'Resposta inválida da API.'
        ];
    }

    return $json;
}

/*
|--------------------------------------------------------------------------
| COMPARAÇÃO DE COMBUSTÍVEIS
|--------------------------------------------------------------------------
*/

if (
    $_SERVER['REQUEST_METHOD'] === 'POST' &&
    ($_POST['acao'] ?? '') === 'comparar'
) {
    header('Content-Type: application/json; charset=utf-8');

    $dados = [
        'preco_gasolina' => (float) ($_POST['preco_gasolina'] ?? 0),
        'preco_etanol' => (float) ($_POST['preco_etanol'] ?? 0),
        'consumo_gasolina' => (float) ($_POST['consumo_gasolina'] ?? 0),
        'consumo_etanol' => (float) ($_POST['consumo_etanol'] ?? 0)
    ];

    $resultado = consultarApiMotoCar(
        'comparar_combustiveis.php',
        $usuarioId,
        'POST',
        $dados
    );

    echo json_encode($resultado);
    exit;
}

/*
|--------------------------------------------------------------------------
| CARREGAMENTO DOS CÁLCULOS
|--------------------------------------------------------------------------
*/

$respostaApi = consultarApiMotoCar(
    'calculos.php',
    $usuarioId
);

$veiculo = $respostaApi['veiculo'] ?? null;
$calculos = $respostaApi['calculos'] ?? [];

$consumoMedio = $calculos['consumo_medio_km_l'] ?? null;
$custoPorKm = $calculos['custo_por_km'] ?? null;
$gastoMensal = $calculos['gasto_mensal'] ?? 0;

$erroApi = ($respostaApi['status'] ?? false) !== true;

function moeda($valor)
{
    if ($valor === null) {
        return 'Não calculado';
    }

    return 'R$ ' . number_format(
        (float) $valor,
        2,
        ',',
        '.'
    );
}

function escapar($valor)
{
    return htmlspecialchars(
        (string) $valor,
        ENT_QUOTES,
        'UTF-8'
    );
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

    <title>Cálculos - MotoCar</title>

    <link
        rel="stylesheet"
        href="assets/css/calculos.css?v=10"
    >

</head>

<body>

<main class="calculos-container">

    <div class="topo-calculos">

        <a href="javascript:history.back()" class="voltar">
            &#8592;
        </a>

        <h1>Cálculos</h1>

        <button
            type="button"
            class="atualizar"
            onclick="window.location.reload()"
            aria-label="Atualizar"
        >
            &#8635;
        </button>

    </div>

    <?php if ($erroApi): ?>

        <section class="sem-veiculo">

            <h2>Não foi possível carregar os cálculos</h2>

            <p>
                Verifique sua conexão e tente atualizar a página.
            </p>

        </section>

    <?php elseif (!$veiculo): ?>

        <section class="sem-veiculo">

            <h2>Nenhum veículo cadastrado</h2>

            <p>
                Cadastre um veículo para visualizar seus cálculos.
            </p>

        </section>

    <?php else: ?>

        <?php

        $marca = escapar($veiculo['marca'] ?? '');
        $modelo = escapar($veiculo['modelo'] ?? '');
        $combustivel = escapar($veiculo['combustivel'] ?? '');

        ?>

        <section class="veiculo-card">

            <div class="icone-veiculo">
                &#128663;
            </div>

            <div class="veiculo-info">

                <span class="etiqueta">
                    MEU VEÍCULO
                </span>

                <h2>
                    <?= $marca ?> <?= $modelo ?>
                </h2>

                <p>
                    <?= $combustivel ?>
                </p>

            </div>

        </section>

        <div class="titulo-secao">

            <h2>Resumo do veículo</h2>

            <p>Seus principais indicadores</p>

        </div>

        <section class="indicador-card">

            <div class="indicador-topo">

                <div class="icone indicador-azul">
                    &#9698;
                </div>

                <span>Consumo médio</span>

            </div>

            <strong class="indicador-valor">

                <?php if ($consumoMedio !== null): ?>

                    <?= number_format(
                        (float) $consumoMedio,
                        2,
                        ',',
                        '.'
                    ) ?> km/l

                <?php else: ?>

                    Não informado

                <?php endif; ?>

            </strong>

            <p class="indicador-descricao">
                Média de consumo do veículo
            </p>

        </section>

        <section class="indicador-card">

            <div class="indicador-topo">

                <div class="icone indicador-azul">
                    $
                </div>

                <span>Custo por km</span>

            </div>

            <strong class="indicador-valor">

                <?= moeda($custoPorKm) ?>

            </strong>

            <p class="indicador-descricao">
                Custo médio de cada quilômetro rodado
            </p>

        </section>

        <section class="indicador-card">

            <div class="indicador-topo">

                <div class="icone indicador-verde">
                    &#128197;
                </div>

                <span>Gasto neste mês</span>

            </div>

            <strong class="indicador-valor">

                <?= moeda($gastoMensal) ?>

            </strong>

            <p class="indicador-descricao">
                Soma dos abastecimentos registrados neste mês
            </p>

        </section>

    <?php endif; ?>

    <section class="funcionalidade-card">

        <div class="funcionalidade-titulo">

            <div class="icone indicador-azul">
                &#9981;
            </div>

            <div>
                <h2>Gasolina × Etanol</h2>
                <p>Compare o custo dos combustíveis</p>
            </div>

        </div>

        <div class="campo-visual">
            <span>&#9981;</span>
            <label for="preco_gasolina">
                Gasolina (R$/litro)
            </label>
        </div>

        <input
            id="preco_gasolina"
            type="number"
            step="0.01"
            min="0.01"
            placeholder="Preço da gasolina"
        >

        <label class="campo-legenda" for="consumo_gasolina">
            Consumo gasolina (km/l)
        </label>

        <input
            id="consumo_gasolina"
            type="number"
            step="0.01"
            min="0.01"
            placeholder="Consumo gasolina"
            value="<?= $consumoMedio !== null ? number_format((float) $consumoMedio, 2, '.', '') : '' ?>"
        >

        <div class="campo-visual">
            <span>&#9981;</span>
            <label for="preco_etanol">
                Etanol (R$/litro)
            </label>
        </div>

        <input
            id="preco_etanol"
            type="number"
            step="0.01"
            min="0.01"
            placeholder="Preço do etanol"
        >

        <label class="campo-legenda" for="consumo_etanol">
            Consumo etanol (km/l)
        </label>

        <input
            id="consumo_etanol"
            type="number"
            step="0.01"
            min="0.01"
            placeholder="Consumo etanol"
            value="<?= $consumoMedio !== null ? number_format((float) $consumoMedio * 0.70, 2, '.', '') : '' ?>"
        >

        <button
            type="button"
            class="botao-azul"
            id="btnComparar"
            onclick="compararCombustiveis()"
        >
            Comparar combustíveis
        </button>

        <p
            class="aviso-funcionalidade"
            id="resultadoComparacao"
            aria-live="polite"
        ></p>

    </section>

    <section class="funcionalidade-card">

        <div class="funcionalidade-titulo">

            <div class="icone indicador-verde">
                &#128202;
            </div>

            <div>
                <h2>Gasto mensal estimado</h2>
                <p>Veja quanto você gastaria por mês</p>
            </div>

        </div>

        <div class="campo-visual">
            <span>&#8644;</span>
            <label for="km_mes">
                Quilômetros por mês
            </label>
        </div>

        <input
            id="km_mes"
            type="number"
            min="1"
            step="1"
            placeholder="Informe os quilômetros mensais"
        >

        <button
            type="button"
            class="botao-azul"
            onclick="calcularGastoMensal()"
        >
            Calcular gasto mensal
        </button>

        <p
            class="aviso-funcionalidade"
            id="resultadoMensal"
            aria-live="polite"
        ></p>

    </section>

</main>

<script>

function valorCampo(id) {
    return parseFloat(
        document.getElementById(id).value.replace(',', '.')
    );
}

function formatarMoeda(valor) {
    return valor.toLocaleString('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    });
}

async function compararCombustiveis() {

    const botao = document.getElementById('btnComparar');
    const resultado = document.getElementById('resultadoComparacao');

    const precoGasolina = valorCampo('preco_gasolina');
    const precoEtanol = valorCampo('preco_etanol');
    const consumoGasolina = valorCampo('consumo_gasolina');
    const consumoEtanol = valorCampo('consumo_etanol');

    if (
        !precoGasolina || precoGasolina <= 0 ||
        !precoEtanol || precoEtanol <= 0 ||
        !consumoGasolina || consumoGasolina <= 0 ||
        !consumoEtanol || consumoEtanol <= 0
    ) {
        resultado.textContent = 'Informe preços e consumos válidos.';
        return;
    }

    botao.disabled = true;
    botao.textContent = 'Comparando...';
    resultado.textContent = '';

    try {

        const dados = new URLSearchParams();

        dados.append('acao', 'comparar');
        dados.append('preco_gasolina', precoGasolina);
        dados.append('preco_etanol', precoEtanol);
        dados.append('consumo_gasolina', consumoGasolina);
        dados.append('consumo_etanol', consumoEtanol);

        const resposta = await fetch(window.location.href, {
            method: 'POST',
            body: dados
        });

        const json = await resposta.json();

        if (!json.status) {
            throw new Error(json.mensagem || 'Não foi possível comparar.');
        }

        let mensagem = '';

        if (json.mais_economico === 'etanol') {
            mensagem = 'O etanol é mais econômico pelo custo por km.';
        } else if (json.mais_economico === 'gasolina') {
            mensagem = 'A gasolina é mais econômica pelo custo por km.';
        } else {
            mensagem = 'Os dois combustíveis têm custo equivalente por km.';
        }

        resultado.innerHTML = '<strong>' + mensagem + '</strong><br>Gasolina: ' + formatarMoeda(Number(json.custo_km_gasolina)) + '/km<br>Etanol: ' + formatarMoeda(Number(json.custo_km_etanol)) + '/km<br>Limite do etanol: ' + formatarMoeda(Number(json.limite_etanol)) + '/litro';

    } catch (erro) {

        resultado.textContent =
            erro.message || 'Erro ao consultar a comparação.';

    } finally {

        botao.disabled = false;
        botao.textContent = 'Comparar combustíveis';

    }
}

function calcularGastoMensal() {

    const kmMensal = valorCampo('km_mes');
    const gasolina = valorCampo('preco_gasolina');
    const etanol = valorCampo('preco_etanol');
    const consumoGasolina = valorCampo('consumo_gasolina');
    const consumoEtanol = valorCampo('consumo_etanol');

    const resultado = document.getElementById('resultadoMensal');

    if (
        !kmMensal || kmMensal <= 0 ||
        !gasolina || gasolina <= 0 ||
        !etanol || etanol <= 0 ||
        !consumoGasolina || consumoGasolina <= 0 ||
        !consumoEtanol || consumoEtanol <= 0
    ) {
        resultado.textContent =
            'Informe os quilômetros mensais, preços e consumos válidos.';
        return;
    }

    const gastoGasolina =
        (kmMensal / consumoGasolina) * gasolina;

    const gastoEtanol =
        (kmMensal / consumoEtanol) * etanol;

    resultado.textContent =
        'Estimativa com gasolina: ' + formatarMoeda(gastoGasolina) +
        '. Estimativa com etanol: ' + formatarMoeda(gastoEtanol) + '.';
}

</script>

</body>
</html>