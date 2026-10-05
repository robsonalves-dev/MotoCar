<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

$usuarioId = (int) $_SESSION['usuario_id'];

?>

<!DOCTYPE html>
<html lang="pt-BR">

<head>

    <meta charset="UTF-8">

    <meta
        name="viewport"
        content="width=device-width, initial-scale=1.0"
    >

    <title>Rotas - MotoCar</title>

    <link
        rel="stylesheet"
        href="assets/css/rotas.css?v=3"
    >

<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-7540081483916932"
     crossorigin="anonymous"></script>
</head>

<body>

<main>

    <h2>Informações da viagem</h2>

    <form id="form-rota">
    <label>Origem</label>
    <input type="text" id="origem" name="origem" placeholder="📍  CEP, rua ou cidade" required>

    <label>Destino</label>
    <input type="text" id="destino" name="destino" placeholder="⚑  CEP, rua ou cidade" required>

    <label>Consumo do veículo</label>
    <input type="number" step="0.1" id="consumo" name="consumo" placeholder="◉  Consumo em km/l" required>

    <label>Combustível</label>
    <select id="combustivel" name="combustivel">
        <option value="gasolina">⛽  Gasolina</option>
        <option value="etanol">⛽  Etanol</option>
    </select>

    <label>Preço do combustível</label>
    <input type="number" step="0.01" id="preco_litro" name="preco_litro" placeholder="▣  Preço por litro" required>

    <button type="submit">↕  Calcular rota</button>
</form>

    <section id="resultado">

        <p>
            Informe a origem, destino e preço do combustível
            para calcular sua viagem.
        </p>

    </section>

</main>
<script>const usuarioId = <?= $usuarioId ?>;</script>
<script src="assets/js/rotas.js?v=11"></script>

</body>

</html>