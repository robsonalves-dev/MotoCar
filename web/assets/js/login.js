document.addEventListener('DOMContentLoaded', () => {
    const togglePassword = document.querySelector('#togglePassword');
    const senhaInput = document.querySelector('#senha');
    const eyeIcon = document.querySelector('#eyeIcon');

    // Alternar visibilidade da senha
    if (togglePassword && senhaInput && eyeIcon) {
        togglePassword.addEventListener('click', () => {
            const isPassword = senhaInput.getAttribute('type') === 'password';
            
            senhaInput.setAttribute('type', isPassword ? 'text' : 'password');
            
            eyeIcon.classList.toggle('fa-eye');
            eyeIcon.classList.toggle('fa-eye-slash');
        });
    }
});