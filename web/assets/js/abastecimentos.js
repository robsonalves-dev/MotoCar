
function formatarLitros(valor) {
    const numero = Number(
        String(valor ?? '0').replace(',', '.')
    );

    if (!Number.isFinite(numero)) {
        return '0';
    }

    return new Intl.NumberFormat('pt-BR', {
        maximumFractionDigits: 3
    }).format(numero);
}


function abrirFormulario() {
    const formulario = document.getElementById('formularioNovo');
    const edicao = document.getElementById('formularioEdicao');
    const lista = document.getElementById('listaAbastecimentos');
    const botao = document.getElementById('botaoAdicionar');

    edicao.classList.remove('aberto');
    formulario.classList.toggle('aberto');

    const aberto = formulario.classList.contains('aberto');

    lista.style.display = aberto ? 'none' : 'block';

    botao.style.display = aberto ? 'none' : 'block';

    botao.innerHTML = aberto
        ? '← Voltar aos abastecimentos'
        : '＋ Adicionar abastecimento';
}


function editarAbastecimento(botao) {
    const card = botao.closest('.card-abastecimento');

    if (!card) {
        alert('Não foi possível localizar o abastecimento.');
        return;
    }

    const id = card.dataset.id;

    if (!id || id === '0') {
        alert('ID do abastecimento não encontrado.');
        return;
    }

    const lista = document.getElementById('listaAbastecimentos');
    const formularioNovo = document.getElementById('formularioNovo');
    const formularioEdicao = document.getElementById('formularioEdicao');
    const botaoAdicionar = document.getElementById('botaoAdicionar');

    document.getElementById('editarId').value = id;

    const campoCombustivel = document.getElementById('editarCombustivel');

    const combustivel = card.dataset.combustivel.toLowerCase();

    campoCombustivel.value = combustivel;

    if (campoCombustivel.value !== combustivel) {
        const opcao = document.createElement('option');
        opcao.value = combustivel;
        opcao.textContent = card.dataset.combustivel;
        campoCombustivel.appendChild(opcao);
        campoCombustivel.value = combustivel;
    }

    document.getElementById('editarLitros').value =
        card.dataset.litros;

    document.getElementById('editarValor').value =
        card.dataset.valor;

    document.getElementById('editarKm').value =
        card.dataset.km;

    let data = card.dataset.data || '';

    if (data.includes('/')) {
        const partes = data.split('/');

        if (partes.length === 3) {
            data = `${partes[2]}-${partes[1].padStart(2, '0')}-${partes[0].padStart(2, '0')}`;
        }
    }

    data = data.substring(0, 10);

    document.getElementById('editarData').value = data;

    formularioNovo.classList.remove('aberto');
    formularioEdicao.classList.add('aberto');

    lista.style.display = 'none';
    botaoAdicionar.style.display = 'none';

    card.querySelector('.menu-acoes')?.removeAttribute('open');

    window.scrollTo({
        top: 0,
        behavior: 'smooth'
    });
}


function cancelarEdicao() {
    const formularioEdicao = document.getElementById('formularioEdicao');
    const lista = document.getElementById('listaAbastecimentos');
    const botaoAdicionar = document.getElementById('botaoAdicionar');

    formularioEdicao.classList.remove('aberto');

    lista.style.display = 'block';
    botaoAdicionar.style.display = 'block';

    document.getElementById('formEditarAbastecimento').reset();
}


document.addEventListener('DOMContentLoaded', function () {

    // Formata os litros exibidos nos cartões.
    document.querySelectorAll('.card-abastecimento').forEach(card => {

        const litros = card.dataset.litros;

        const elemento = card.querySelector('.valor-litros');

        if (elemento && litros !== undefined) {
            elemento.textContent = `${formatarLitros(litros)} litros`;
        }

    });

    const form = document.getElementById('formEditarAbastecimento');

    if (!form) return;

    form.addEventListener('submit', async function (event) {

        event.preventDefault();

        const id = document.getElementById('editarId').value;

        const usuarioId = Number(
            document.querySelector('main').dataset.usuarioId
        );

        if (!usuarioId || usuarioId <= 0) {
            alert('Não foi possível identificar o usuário autenticado.');
            return;
        }

        const dados = {
            id: Number(id),
            usuario_id: usuarioId,
            combustivel: document.getElementById('editarCombustivel').value,
            litros: document.getElementById('editarLitros').value,
            valor_total: document.getElementById('editarValor').value,
            quilometragem: document.getElementById('editarKm').value,
            data_abastecimento: document.getElementById('editarData').value
        };

        const botao = form.querySelector('button[type="submit"]');

        botao.disabled = true;
        botao.textContent = 'Salvando...';

        try {

            const resposta = await fetch(
                'backend/api/abastecimentos.php',
                {
                    method: 'PUT',
                    headers: {
                        'Content-Type': 'application/json',
                        'Accept': 'application/json'
                    },
                    body: JSON.stringify(dados),
                    credentials: 'same-origin'
                }
            );

            const resultado = await resposta.json();

            if (!resposta.ok || resultado.status !== true) {
                throw new Error(
                    resultado.mensagem || 'Não foi possível atualizar.'
                );
            }

            alert('Abastecimento atualizado com sucesso!');

            window.location.reload();

        } catch (erro) {

            console.error('Erro ao editar abastecimento:', erro);

            alert(erro.message || 'Erro de comunicação com o servidor.');

        } finally {

            botao.disabled = false;
            botao.textContent = 'Salvar alterações';

        }

    });

});
