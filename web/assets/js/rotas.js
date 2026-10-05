document.getElementById('form-rota').addEventListener('submit', async function(e) {
    e.preventDefault();

    const origem = document.getElementById('origem').value;
    const destino = document.getElementById('destino').value;
    const consumo = parseFloat(document.getElementById('consumo').value);
    const combustivel = document.getElementById('combustivel').value;
    const precoLitro = parseFloat(document.getElementById('preco_litro').value);
    const resultado = document.getElementById('resultado');

    resultado.innerHTML = '<p>Calculando rota...</p>';

    try {
        const resposta = await fetch(
            'backend/api/rotas.php?origem=' + encodeURIComponent(origem) +
            '&destino=' + encodeURIComponent(destino)
        );

        const dados = await resposta.json();

        if (!dados.status) {
            resultado.innerHTML = '<p>' + dados.mensagem + '</p>';
            return;
        }

        const distancia = parseFloat(dados.rota.distancia_km);
        const tempoTotal = parseFloat(dados.rota.tempo_minutos);
        const litros = distancia / consumo;
        const custo = litros * precoLitro;

        const horas = Math.floor(tempoTotal / 60);
        const minutos = Math.round(tempoTotal % 60);

        resultado.innerHTML = `
            <div class="resultado-header">
                <div class="resultado-icone">➜</div>
                <div>
                    <h3>Resultado da rota</h3>
                    <span>Estimativa da viagem</span>
                </div>
            </div>

            <div class="resultado-cards">
                <div class="resultado-card">
                    <div class="card-icone">↕</div>
                    <strong>${distancia.toFixed(2)} km</strong>
                    <span>Distância</span>
                </div>

                <div class="resultado-card">
                    <div class="card-icone">◷</div>
                    <strong>${horas}h ${minutos}min</strong>
                    <span>Tempo estimado</span>
                </div>
            </div>

            <div class="resultado-detalhes">
                <div class="detalhe">
                    <span>⛽</span>
                    <strong>Combustível necessário</strong>
                    <b>${litros.toFixed(2)} L</b>
                </div>

                <div class="detalhe">
                    <span>▣</span>
                    <strong>Custo estimado</strong>
                    <b>R$ ${custo.toFixed(2)}</b>
                </div>
            </div>

            <button type="button" id="btn-salvar" class="btn-salvar">
                ▣ &nbsp; Salvar viagem
            </button>
        `;

        document.getElementById('btn-salvar').addEventListener('click', async function() {

            const botao = this;
            botao.disabled = true;
            botao.textContent = 'Salvando...';

            try {
                const respostaVeiculos = await fetch(
                    'backend/api/veiculos.php?usuario_id=' + usuarioId
                );

                const dadosVeiculos = await respostaVeiculos.json();
                
                console.log(dadosVeiculos);

                if (!dadosVeiculos.status || !dadosVeiculos.veiculos.length) {
                    alert('Nenhum veículo cadastrado.');
                    botao.disabled = false;
                    botao.textContent = '▣  Salvar viagem';
                    return;
                }

                const veiculoId = dadosVeiculos.veiculos[0].id;

                const respostaSalvar = await fetch(
                    'backend/api/viagens.php',
                    {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json'
                        },
                        body: JSON.stringify({
                            usuario_id: usuarioId,
                            veiculo_id: veiculoId,
                            origem: origem,
                            destino: destino,
                            distancia_km: distancia,
                            tempo_minutos: tempoTotal,
                            combustivel: combustivel,
                            consumo_km_l: consumo,
                            preco_combustivel: precoLitro,
                            litros_necessarios: litros,
                            custo_viagem: custo
                        })
                    }
                );

                const dadosSalvar = await respostaSalvar.json();

                if (!dadosSalvar.status) {
                    alert(dadosSalvar.mensagem);
                    botao.disabled = false;
                    botao.textContent = '▣  Salvar viagem';
                    return;
                }

                botao.textContent = '✓ Viagem salva!';

            } catch (erro) {
                alert('Erro ao salvar a viagem.');
                botao.disabled = false;
                botao.textContent = '▣  Salvar viagem';
            }
        });

    } catch (erro) {
        resultado.innerHTML = '<p>Erro ao calcular a rota.</p>';
    }
});