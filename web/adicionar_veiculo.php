<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Adicionar veículo - MotoCar</title>
    <link rel="stylesheet" href="assets/css/adicionar_veiculo.css">
</head>
<body>

<main>
    <h2>Adicionar veículo</h2>

    <form action="backend/api/veiculos.php" method="POST">

        <input type="text" name="marca" placeholder="Marca" required>

        <input type="text" name="modelo" placeholder="Modelo" required>

        <input type="number" name="ano" placeholder="Ano" required>

        <input type="text" name="placa" placeholder="Placa" required>

        <select name="combustivel" required>
            <option value="">Tipo de combustível</option>
            <option value="gasolina">Gasolina</option>
            <option value="etanol">Etanol</option>
            <option value="flex">Flex</option>
        </select>
        <input type="number" name="consumo_medio" step="0.01" min="0" placeholder="Consumo médio (km/l)" required>
        <button type="submit">Salvar veículo</button>

    </form>
</main>

</body>
</html>