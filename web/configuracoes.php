<?php

session_start();

if (!isset($_SESSION['usuario_id'])) {
    header('Location: login.php');
    exit;
}

require_once 'backend/config.php';

$usuarioId = (int) $_SESSION['usuario_id'];

$nome = '';
$email = '';
$mensagem = '';
$tipoMensagem = '';

try {

    $stmt = $pdo->prepare("
        SELECT nome, email
        FROM usuarios
        WHERE id = :id
        LIMIT 1
    ");

    $stmt->execute([
        'id' => $usuarioId
    ]);

    $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$usuario) {
        session_destroy();
        header('Location: login.php');
        exit;
    }

    $nome = $usuario['nome'] ?? '';
    $email = $usuario['email'] ?? '';

} catch (PDOException $e) {

    $mensagem = 'Não foi possível carregar os dados da conta.';
    $tipoMensagem = 'erro';
}


/*
|--------------------------------------------------------------------------
| SALVAR DADOS PESSOAIS
|--------------------------------------------------------------------------
*/

if (
    $_SERVER['REQUEST_METHOD'] === 'POST' &&
    ($_POST['acao'] ?? '') === 'salvar_dados'
) {

    $novoNome = trim($_POST['nome'] ?? '');
    $novoEmail = trim($_POST['email'] ?? '');
    $senhaAtual = $_POST['senha_atual'] ?? '';

    if ($novoNome === '') {

        $mensagem = 'Informe seu nome.';
        $tipoMensagem = 'erro';

    } elseif (!filter_var($novoEmail, FILTER_VALIDATE_EMAIL)) {

        $mensagem = 'Informe um e-mail válido.';
        $tipoMensagem = 'erro';

    } elseif ($senhaAtual === '') {

        $mensagem =
            'Digite sua senha atual para salvar as alterações.';

        $tipoMensagem = 'erro';

    } else {

        try {

            $stmt = $pdo->prepare("
                SELECT senha
                FROM usuarios
                WHERE id = :id
                LIMIT 1
            ");

            $stmt->execute([
                'id' => $usuarioId
            ]);

            $usuarioSenha = $stmt->fetch(PDO::FETCH_ASSOC);

            /*
             * O login do MotoCar utiliza SHA-256.
             * Portanto, usamos exatamente o mesmo método.
             */

            if (
                !$usuarioSenha ||
                !hash_equals(
                    $usuarioSenha['senha'],
                    hash('sha256', $senhaAtual)
                )
            ) {

                $mensagem = 'Senha atual incorreta.';
                $tipoMensagem = 'erro';

            } else {

                $stmt = $pdo->prepare("
                    UPDATE usuarios
                    SET nome = :nome,
                        email = :email
                    WHERE id = :id
                ");

                $stmt->execute([
                    'nome' => $novoNome,
                    'email' => $novoEmail,
                    'id' => $usuarioId
                ]);

                $nome = $novoNome;
                $email = $novoEmail;

                $_SESSION['usuario_nome'] = $novoNome;
                $_SESSION['usuario_email'] = $novoEmail;

                $mensagem =
                    'Dados atualizados com sucesso!';

                $tipoMensagem = 'sucesso';
            }

        } catch (PDOException $e) {

            $mensagem =
                'Não foi possível atualizar os dados.';

            $tipoMensagem = 'erro';
        }
    }
}


/*
|--------------------------------------------------------------------------
| ALTERAR SENHA
|--------------------------------------------------------------------------
*/

if (
    $_SERVER['REQUEST_METHOD'] === 'POST' &&
    ($_POST['acao'] ?? '') === 'alterar_senha'
) {

    $senhaAtual = $_POST['senha_atual'] ?? '';
    $novaSenha = $_POST['nova_senha'] ?? '';
    $confirmarSenha = $_POST['confirmar_senha'] ?? '';

    if ($senhaAtual === '') {

        $mensagem = 'Digite sua senha atual.';
        $tipoMensagem = 'erro';

    } elseif ($novaSenha === '') {

        $mensagem = 'Digite a nova senha.';
        $tipoMensagem = 'erro';

    } elseif (strlen($novaSenha) < 8) {

        $mensagem =
            'A nova senha deve ter pelo menos 8 caracteres.';

        $tipoMensagem = 'erro';

    } elseif ($novaSenha !== $confirmarSenha) {

        $mensagem =
            'As senhas não coincidem.';

        $tipoMensagem = 'erro';

    } else {

        try {

            $stmt = $pdo->prepare("
                SELECT senha
                FROM usuarios
                WHERE id = :id
                LIMIT 1
            ");

            $stmt->execute([
                'id' => $usuarioId
            ]);

            $usuarioSenha = $stmt->fetch(PDO::FETCH_ASSOC);

            /*
             * Confirma a senha atual usando SHA-256,
             * igual ao login.
             */

            if (
                !$usuarioSenha ||
                !hash_equals(
                    $usuarioSenha['senha'],
                    hash('sha256', $senhaAtual)
                )
            ) {

                $mensagem =
                    'Senha atual incorreta.';

                $tipoMensagem = 'erro';

            } else {

                /*
                 * Nova senha também será armazenada
                 * usando SHA-256.
                 */

                $novaSenhaHash = hash(
                    'sha256',
                    $novaSenha
                );

                $stmt = $pdo->prepare("
                    UPDATE usuarios
                    SET senha = :senha
                    WHERE id = :id
                ");

                $stmt->execute([
                    'senha' => $novaSenhaHash,
                    'id' => $usuarioId
                ]);

                $mensagem =
                    'Senha alterada com sucesso!';

                $tipoMensagem = 'sucesso';
            }

        } catch (PDOException $e) {

            $mensagem =
                'Não foi possível alterar a senha.';

            $tipoMensagem = 'erro';
        }
    }
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

    <title>Configurações - MotoCar</title>

    <link
        rel="stylesheet"
        href="assets/css/configuracoes.css?v=1"
    >

</head>

<body>

<main class="configuracoes-container">

    <section class="configuracoes-header">

        <div class="configuracoes-header-icone">
            ⚙️
        </div>

        <div>

            <h1>Minha conta</h1>

            <p>
                Gerencie seus dados e a segurança da sua conta.
            </p>

        </div>

    </section>


    <?php if ($mensagem !== ''): ?>

        <div class="mensagem <?= htmlspecialchars($tipoMensagem) ?>">

            <?= htmlspecialchars($mensagem) ?>

        </div>

    <?php endif; ?>


    <!-- DADOS PESSOAIS -->

    <section class="configuracao-card">

        <div class="configuracao-card-header">

            <div class="configuracao-icone">
                👤
            </div>

            <div>

                <h2>Dados pessoais</h2>

                <p>
                    Atualize suas informações
                </p>

            </div>

        </div>


        <form method="POST">

            <input
                type="hidden"
                name="acao"
                value="salvar_dados"
            >


            <div class="campo">

                <label for="nome">
                    Nome completo
                </label>

                <input
                    type="text"
                    id="nome"
                    name="nome"
                    value="<?= htmlspecialchars($nome) ?>"
                    required
                >

            </div>


            <div class="campo">

                <label for="email">
                    E-mail
                </label>

                <input
                    type="email"
                    id="email"
                    name="email"
                    value="<?= htmlspecialchars($email) ?>"
                    required
                >

            </div>


            <div class="campo">

                <label for="senha_dados">
                    Senha atual
                </label>

                <div class="campo-senha">

                    <input
                        type="password"
                        id="senha_dados"
                        name="senha_atual"
                        required
                    >

                    <button
                        type="button"
                        class="botao-mostrar-senha"
                        data-target="senha_dados"
                    >
                        👁️
                    </button>

                </div>

            </div>


            <button
                type="submit"
                class="botao-principal"
            >
                💾 Salvar dados
            </button>

        </form>

    </section>


    <!-- SEGURANÇA -->

    <section class="configuracao-card">

        <div class="configuracao-card-header">

            <div class="configuracao-icone">
                🛡️
            </div>

            <div>

                <h2>Segurança</h2>

                <p>
                    Altere sua senha de acesso
                </p>

            </div>

        </div>


        <form method="POST">

            <input
                type="hidden"
                name="acao"
                value="alterar_senha"
            >


            <div class="campo">

                <label for="senha_atual">
                    Senha atual
                </label>

                <div class="campo-senha">

                    <input
                        type="password"
                        id="senha_atual"
                        name="senha_atual"
                        required
                    >

                    <button
                        type="button"
                        class="botao-mostrar-senha"
                        data-target="senha_atual"
                    >
                        👁️
                    </button>

                </div>

            </div>


            <div class="campo">

                <label for="nova_senha">
                    Nova senha
                </label>

                <div class="campo-senha">

                    <input
                        type="password"
                        id="nova_senha"
                        name="nova_senha"
                        minlength="8"
                        required
                    >

                    <button
                        type="button"
                        class="botao-mostrar-senha"
                        data-target="nova_senha"
                    >
                        👁️
                    </button>

                </div>

            </div>


            <div class="campo">

                <label for="confirmar_senha">
                    Confirmar nova senha
                </label>

                <div class="campo-senha">

                    <input
                        type="password"
                        id="confirmar_senha"
                        name="confirmar_senha"
                        minlength="8"
                        required
                    >

                    <button
                        type="button"
                        class="botao-mostrar-senha"
                        data-target="confirmar_senha"
                    >
                        👁️
                    </button>

                </div>

            </div>


            <button
                type="submit"
                class="botao-principal"
            >
                🔐 Alterar senha
            </button>

        </form>

    </section>


    <footer class="configuracoes-footer">

        MotoCar • Configurações da conta

    </footer>

</main>


<script src="assets/js/configuracoes.js?v=1"></script>

</body>

</html>