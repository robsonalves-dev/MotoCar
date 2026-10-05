<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];
$nomeUsuario = $_SESSION['usuario_nome'] ?? 'Motorista';

function h($valor) {
    return htmlspecialchars((string)$valor, ENT_QUOTES, 'UTF-8');
}

function dinheiro($valor) {
    return 'R$ ' . number_format((float)$valor, 2, ',', '.');
}

function consultarApi($endpoint, $usuarioId) {

    $url = 'https://motocarweb.com.br/backend/api/'
         . $endpoint
         . '?usuario_id=' . urlencode((string)$usuarioId);

    $ch = curl_init($url);

    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_HTTPHEADER => [
            'Accept: application/json'
        ]
    ]);

    $resposta = curl_exec($ch);
    $status = curl_getinfo($ch, CURLINFO_HTTP_CODE);

    curl_close($ch);

    if ($resposta === false || $status !== 200) {
        return null;
    }

    return json_decode($resposta, true);
}


/* Valores iniciais */

$veiculoNome = 'Nenhum veículo cadastrado';
$combustivel = '-';

$custoKm = 0;
$custoMensal = 0;
$custoViagem = 0;

$quantidadeAbastecimentos = 0;

$ultimoPosto = 'Nenhum abastecimento';
$ultimoCombustivel = '-';
$ultimoValor = 'R$ 0,00';
$ultimaData = '-';

$erroApi = false;


/* Carregar dados do veículo e cálculos */

$dadosCalculos = consultarApi('calculos.php', $usuarioId);

if (is_array($dadosCalculos)) {

    $veiculo = $dadosCalculos['veiculo'] ?? null;

    if (is_array($veiculo)) {

        $marca = $veiculo['marca'] ?? '';
        $modelo = $veiculo['modelo'] ?? '';

        $veiculoNome = trim($marca . ' ' . $modelo);

        if ($veiculoNome === '') {
            $veiculoNome = 'Veículo cadastrado';
        }

        $combustivel = $veiculo['combustivel'] ?? '-';
    }

    $custoKm = (float)($dadosCalculos['custo_km'] ?? 0);
    $custoMensal = (float)($dadosCalculos['custo_mensal'] ?? 0);
    $custoViagem = (float)($dadosCalculos['custo_viagem'] ?? 0);

} else {
    $erroApi = true;
}


/* Carregar abastecimentos */

$dadosAbastecimentos = consultarApi(
    'abastecimentos_lista.php',
    $usuarioId
);

$listaAbastecimentos = [];

if (is_array($dadosAbastecimentos)) {

    if (array_is_list($dadosAbastecimentos)) {

        $listaAbastecimentos = $dadosAbastecimentos;

    } elseif (
        isset($dadosAbastecimentos['abastecimentos']) &&
        is_array($dadosAbastecimentos['abastecimentos'])
    ) {

        $listaAbastecimentos = $dadosAbastecimentos['abastecimentos'];

    } elseif (
        isset($dadosAbastecimentos['dados']) &&
        is_array($dadosAbastecimentos['dados'])
    ) {

        $listaAbastecimentos = $dadosAbastecimentos['dados'];
    }

} else {
    $erroApi = true;
}

$quantidadeAbastecimentos = count($listaAbastecimentos);

if (!empty($listaAbastecimentos)) {

    $ultimo = $listaAbastecimentos[0];

    $ultimoPosto = $ultimo['posto']
        ?? $ultimo['nome_posto']
        ?? 'Posto não informado';

    $ultimoCombustivel = $ultimo['combustivel'] ?? '-';

    $valor = $ultimo['valor']
        ?? $ultimo['valor_total']
        ?? $ultimo['preco']
        ?? 0;

    $ultimoValor = dinheiro($valor);

    $data = $ultimo['data']
        ?? $ultimo['created_at']
        ?? $ultimo['data_abastecimento']
        ?? '-';

    if ($data !== '-' && strtotime($data) !== false) {
        $ultimaData = date('d/m/Y', strtotime($data));
    } else {
        $ultimaData = $data;
    }
}

?>

<!DOCTYPE html>
<html lang="pt-BR">

<head>

    <meta charset="UTF-8">

    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>MotoCar - Painel</title>

    <link rel="stylesheet" href="assets/css/dashboard.css?v=15">

    <script
        async
        src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7540081483916932"
        crossorigin="anonymous">
    </script>

    <style>

        /*
        ==========================================
        IFRAME DAS PÁGINAS
        ==========================================
        */

        #conteudoFrame {
            display: none;
            width: 100%;
            min-height: calc(100vh - 90px);
            border: none;
            background: #f4f6fa;
        }

        /*
        ==========================================
        QUANDO O IFRAME ESTIVER ABERTO
        ==========================================
        */

        .iframe-aberto #paginaInicial {
            display: none;
        }

        .iframe-aberto #conteudoFrame {
            display: block;
        }

    </style>

</head>


<body>


<div class="menu-overlay" id="menuOverlay"></div>


<div class="dashboard">


    <!-- =========================================
         BARRA LATERAL
         ========================================= -->

    <aside class="sidebar" id="sidebar">

        <div class="logo">
            MotoCar
        </div>


        <div class="menu-titulo">
            MENU PRINCIPAL
        </div>


        <nav class="menu">


            <!-- PAINEL -->

            <a
                href="dashboard.php"
                class="menu-link ativo"
                data-pagina="inicio"
            >

                <span class="menu-icone">⌂</span>

                <span>Painel</span>

            </a>


            <!-- MEU VEÍCULO -->

            <a
                href="veiculos.php"
                class="menu-link"
                data-pagina="veiculos.php"
            >

                <span class="menu-icone">🚗</span>

                <span>Meu veículo</span>

            </a>


            <!-- ABASTECIMENTOS -->

            <a
                href="abastecimentos.php"
                class="menu-link"
                data-pagina="abastecimentos.php"
            >

                <span class="menu-icone">⛽</span>

                <span>Abastecimentos</span>

            </a>


            <!-- CÁLCULOS -->

            <a
                href="calculos.php"
                class="menu-link"
                data-pagina="calculos.php"
            >

                <span class="menu-icone">▤</span>

                <span>Cálculos</span>

            </a>


            <!-- ROTAS -->

            <a
                href="rotas.php"
                class="menu-link"
                data-pagina="rotas.php"
            >

                <span class="menu-icone">⌁</span>

                <span>Rotas e viagens</span>

            </a>


          <!-- HISTÓRICO --> <a href="analise_historico.php" class="menu-link" data-pagina="analise_historico.php"><span class="menu-icone">◷</span><span>Analise de Histórico</span></a> <!-- HISTÓRICO DE VIAGENS --> <a href="historico_viagens.php" class="menu-link" data-pagina="historico_viagens.php"><span class="menu-icone">📍</span><span>Histórico de viagens</span></a>


            <!-- POSTOS -->

            <a
                href="postos.php"
                class="menu-link"
                data-pagina="postos.php"
            >

                <span class="menu-icone">⛽</span>

                <span>Postos</span>

            </a>
            
            <a href="configuracoes.php" class="menu-link" data-pagina="configuracoes.php"><span class="menu-icone">⚙️</span><span>Configurações</span></a>


        </nav>


        <!-- RODAPÉ DO MENU -->

        <div class="menu-rodape">

            <a
                href="logout.php"
                class="menu-link sair"
            >

                <span class="menu-icone">⇥</span>

                <span>Sair</span>

            </a>

        </div>


    </aside>


    <!-- =========================================
         ÁREA PRINCIPAL
         ========================================= -->

    <div class="conteudo">


        <!-- TOPBAR -->

        <header class="topbar">

            <div class="topbar-esquerda">

                <button
                    type="button"
                    class="botao-menu"
                    id="botaoMenu"
                >
                    ☰
                </button>

                <h1>MotoCar</h1>

            </div>

        </header>


        <!-- =====================================
             PÁGINA INICIAL DO DASHBOARD
             ===================================== -->

        <div id="paginaInicial">


            <main>


                <!-- SAUDAÇÃO -->

                <section class="boas-vindas">

                    <h2>
                        Olá, <?= h($nomeUsuario) ?>! 👋
                    </h2>

                    <p>
                        Confira as informações do seu veículo.
                    </p>

                </section>


                <!-- ERRO API -->

                <?php if ($erroApi): ?>

                    <p class="aviso-api">

                        Não foi possível carregar todos os dados.
                        Tente atualizar a página.

                    </p>

                <?php endif; ?>


                <!-- VEÍCULO -->

                <section class="card-veiculo">


                    <div class="veiculo-icone">
                        🚗
                    </div>


                    <div class="veiculo-dados">

                        <span class="veiculo-label">
                            Meu veículo
                        </span>

                        <h2>
                            <?= h($veiculoNome) ?>
                        </h2>

                        <p>
                            Combustível:
                            <?= h($combustivel) ?>
                        </p>

                    </div>


                </section>


                <!-- RESUMO -->

                <section class="secao">


                    <h2 class="secao-titulo">
                        Resumo
                    </h2>


                    <div class="resumo">


                        <article class="card-resumo">

                            <div class="resumo-icone">
                                ◉
                            </div>

                            <span class="resumo-label">
                                Custo por km
                            </span>

                            <strong>
                                <?= h(dinheiro($custoKm)) ?>
                            </strong>

                        </article>


                        <article class="card-resumo">

                            <div class="resumo-icone">
                                ▦
                            </div>

                            <span class="resumo-label">
                                Custo mensal
                            </span>

                            <strong>
                                <?= h(dinheiro($custoMensal)) ?>
                            </strong>

                        </article>


                        <article class="card-resumo">

                            <div class="resumo-icone">
                                ⌁
                            </div>

                            <span class="resumo-label">
                                Custo viagem
                            </span>

                            <strong>
                                <?= h(dinheiro($custoViagem)) ?>
                            </strong>

                        </article>


                        <article class="card-resumo">

                            <div class="resumo-icone">
                                ⛽
                            </div>

                            <span class="resumo-label">
                                Abastecimentos
                            </span>

                            <strong>
                                <?= $quantidadeAbastecimentos ?>
                            </strong>

                        </article>


                    </div>


                </section>


                <!-- ÚLTIMOS ABASTECIMENTOS -->

                <section class="secao ultimos">


                    <div class="secao-cabecalho">

                        <h2 class="secao-titulo">
                            Últimos abastecimentos
                        </h2>


                        <a
                            href="historico.php"
                            class="ver-todos"
                            data-pagina="historico.php"
                        >
                            Ver histórico
                        </a>

                    </div>


                    <?php if (empty($listaAbastecimentos)): ?>


                        <article class="card-abastecimento">

                            <p>
                                Nenhum abastecimento encontrado.
                            </p>

                        </article>


                    <?php else: ?>


                        <?php foreach (
                            array_slice(
                                $listaAbastecimentos,
                                0,
                                5
                            ) as $abastecimento
                        ): ?>


                            <?php

                            $posto =
                                $abastecimento['posto']
                                ?? $abastecimento['nome_posto']
                                ?? 'Posto não informado';


                            $tipo =
                                $abastecimento['combustivel']
                                ?? '-';


                            $valor =
                                $abastecimento['valor']
                                ?? $abastecimento['valor_total']
                                ?? $abastecimento['preco']
                                ?? 0;


                            $data =
                                $abastecimento['data']
                                ?? $abastecimento['created_at']
                                ?? $abastecimento['data_abastecimento']
                                ?? '-';


                            if (
                                $data !== '-' &&
                                strtotime($data) !== false
                            ) {

                                $data =
                                    date(
                                        'd/m/Y',
                                        strtotime($data)
                                    );
                            }

                            ?>


                            <article class="card-abastecimento">


                                <div class="abastecimento-topo">


                                    <div class="abastecimento-icone">
                                        ⛽
                                    </div>


                                    <div class="abastecimento-dados">

                                        <strong>
                                            <?= h($posto) ?>
                                        </strong>

                                        <span>
                                            <?= h($tipo) ?>
                                        </span>

                                    </div>


                                    <div class="abastecimento-valor">

                                        <?= h(dinheiro($valor)) ?>

                                    </div>


                                </div>


                                <div class="abastecimento-divisor"></div>


                                <div class="abastecimento-data">

                                    <?= h($data) ?>

                                </div>


                            </article>


                        <?php endforeach; ?>


                    <?php endif; ?>


                </section>


            </main>


        </div>


        <!-- =====================================
             IFRAME
             ===================================== -->

        <iframe
            id="conteudoFrame"
            title="Conteúdo do MotoCar"
        ></iframe>


    </div>


</div>



<script>

/*
==================================================
MENU MOBILE
==================================================
*/

const botaoMenu = document.getElementById('botaoMenu');

const sidebar = document.getElementById('sidebar');

const overlay = document.getElementById('menuOverlay');


botaoMenu.addEventListener('click', function () {

    sidebar.classList.toggle('aberto');

    overlay.classList.toggle('visivel');

});


overlay.addEventListener('click', function () {

    sidebar.classList.remove('aberto');

    overlay.classList.remove('visivel');

});


/*
==================================================
IFRAME
==================================================
*/

const iframe = document.getElementById('conteudoFrame');

const paginaInicial = document.getElementById('paginaInicial');

const linksMenu = document.querySelectorAll(
    '.menu-link[data-pagina]'
);


/*
==================================================
ABRIR PÁGINA NO IFRAME
==================================================
*/

function abrirPagina(pagina, link) {


    /*
    Se for o painel,
    volta para a página inicial
    */

    if (pagina === 'inicio') {

        paginaInicial.style.display = 'block';

        iframe.style.display = 'none';

        document.body.classList.remove('iframe-aberto');

    }

    /*
    Qualquer outra página
    abre dentro do iframe
    */

    else {

        iframe.src = pagina;

        document.body.classList.add('iframe-aberto');

        paginaInicial.style.display = 'none';

        iframe.style.display = 'block';

    }


    /*
    Remove ativo de todos
    */

    linksMenu.forEach(function (item) {

        item.classList.remove('ativo');

    });


    /*
    Coloca ativo no menu clicado
    */

    if (link) {

        link.classList.add('ativo');

    }


    /*
    Fecha menu no celular
    */

    sidebar.classList.remove('aberto');

    overlay.classList.remove('visivel');

}


/*
==================================================
CLIQUES NO MENU
==================================================
*/

linksMenu.forEach(function (link) {


    link.addEventListener('click', function (evento) {

        evento.preventDefault();


        const pagina =
            link.getAttribute('data-pagina');


        abrirPagina(
            pagina,
            link
        );


    });


});


/*
==================================================
LINK "VER HISTÓRICO"
==================================================
*/

const linksIframe =
    document.querySelectorAll(
        '[data-pagina="historico.php"]'
    );


linksIframe.forEach(function (link) {

    link.addEventListener('click', function (evento) {

        evento.preventDefault();


        const pagina =
            link.getAttribute('data-pagina');


        abrirPagina(
            pagina,
            null
        );


        /*
        Marca Histórico no menu
        */

        linksMenu.forEach(function (item) {

            if (
                item.getAttribute('data-pagina') === pagina
            ) {

                item.classList.add('ativo');

            }

        });


    });

});

</script>


</body>

</html>