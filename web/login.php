<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login | MotoCar</title>
    <link rel="stylesheet" href="assets/css/login.css">
    <!-- Ícones para os inputs e visibilidade de senha -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
</head>
<body>

    <main class="login-page">
        
        <!-- Cabeçalho / Branding -->
        <header class="brand">
            <div class="logo-icon">
                <i class="fa-solid fa-car"></i>
            </div>
            <h1>MotoCar</h1>
            <span>Seu veículo. Seus custos. Seu controle.</span>
        </header>

        <!-- Card de Formuário -->
        <div class="login-card">
            
            <div class="welcome">
                <h2>Bem-vindo de volta</h2>
                <p>Entre na sua conta para continuar.</p>
            </div>

            <!-- Form apontando para o seu backend/api/login.php -->
            <form id="loginForm" action="backend/api/login.php" method="POST">
                
                <!-- Campo E-mail -->
                <div class="form-group">
                    <i class="fa-regular fa-envelope input-icon"></i>
                    <input
                        type="email"
                        id="email"
                        name="email"
                        placeholder="E-mail"
                        autocomplete="email"
                        required
                    >
                </div>

                <!-- Campo Senha -->
                <div class="form-group">
                    <i class="fa-solid fa-lock input-icon"></i>
                    <input
                        type="password"
                        id="senha"
                        name="senha"
                        placeholder="Senha"
                        autocomplete="current-password"
                        required
                    >
                    <button type="button" class="toggle-password" id="togglePassword">
                        <i class="fa-regular fa-eye" id="eyeIcon"></i>
                    </button>
                </div>

                <!-- Botão Entrar -->
                <button type="submit" class="login-button">ENTRAR</button>

            </form>

            <!-- Divisor -->
            <div class="divider">
                <span>ou</span>
            </div>

            <!-- Botão Cadastrar -->
            <a href="cadastro.php" class="register-button">CRIAR UMA CONTA</a>

        </div>

        <!-- Rodapé -->
        <p class="footer">
            MotoCar • Mobilidade inteligente
        </p>

    </main>

    <script src="assets/js/login.js"></script>
</body>
</html>