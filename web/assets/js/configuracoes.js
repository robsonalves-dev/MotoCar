document.addEventListener('DOMContentLoaded', function () {

    const botoes = document.querySelectorAll(
        '.botao-mostrar-senha'
    );

    botoes.forEach(function (botao) {

        botao.addEventListener('click', function () {

            const id = botao.dataset.target;
            const campo = document.getElementById(id);

            if (!campo) {
                return;
            }

            if (campo.type === 'password') {

                campo.type = 'text';
                botao.textContent = '🙈';

            } else {

                campo.type = 'password';
                botao.textContent = '👁️';
            }
        });
    });

});