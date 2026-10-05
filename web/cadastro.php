<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Criar conta - MotoCar</title>
    <link rel="stylesheet" href="assets/css/cadastro.css">
</head>
<body>

<main>
    <h1>Criar conta</h1>

    <form action="backend/api/cadastro.php" method="POST">
        <input type="text" name="nome" placeholder="Nome" required>
        <input type="email" name="email" placeholder="E-mail" required>
        <input type="password" name="senha" placeholder="Senha" required>

        <button type="submit">Criar conta</button>
    </form>

    <a href="login.php">Já tenho uma conta</a>
</main>

</body>
</html>