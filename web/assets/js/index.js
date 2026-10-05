document.addEventListener('DOMContentLoaded', () => {

    document.querySelectorAll('a[href^="#"]').forEach(link => {

        link.addEventListener('click', function (event) {

            const destino = document.querySelector(this.getAttribute('href'));

            if (!destino) return;

            event.preventDefault();

            destino.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });

        });

    });

});