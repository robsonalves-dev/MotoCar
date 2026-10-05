const pesquisa = document.getElementById('pesquisaMunicipio');
const lista = document.getElementById('listaMunicipios');
const municipioSelecionado = document.getElementById('municipioSelecionado');

pesquisa.addEventListener('input', function () {

    const texto = this.value.trim().toLowerCase();

    lista.innerHTML = '';

    if (texto === '') {
        lista.style.display = 'none';
        municipioSelecionado.value = '';
        return;
    }

    const resultados = municipios
        .filter(function (municipio) {
            return municipio.toLowerCase().includes(texto);
        })
        .slice(0, 20);

    if (resultados.length === 0) {
        lista.style.display = 'none';
        return;
    }

    resultados.forEach(function (municipio) {

        const item = document.createElement('div');

        item.className = 'municipio-item';
        item.textContent = municipio;

        item.addEventListener('click', function () {

            pesquisa.value = municipio;
            municipioSelecionado.value = municipio;
            lista.style.display = 'none';

        });

        lista.appendChild(item);
    });

    lista.style.display = 'block';
});

document.addEventListener('click', function (event) {

    if (!event.target.closest('.campo-pesquisa')) {
        lista.style.display = 'none';
    }

});