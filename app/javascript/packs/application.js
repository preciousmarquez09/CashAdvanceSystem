// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

require("@rails/ujs").start()
require("turbolinks").start()
require("@rails/activestorage").start()
require("channels")
import Swal from 'sweetalert2';
window.Swal = Swal;


// Uncomment to copy all static images under ../images to the output folder and reference
// them with the image_pack_tag helper in views (e.g <%= image_pack_tag 'rails.png' %>)
// or the `imagePath` JavaScript helper below.
//
// const images = require.context('../images', true)
// const imagePath = (name) => images(name, true)

document.addEventListener('DOMContentLoaded', function () {
    function setupModalToggle() {
        const modals = document.querySelectorAll('[id$="-modal"]');

        modals.forEach(modal => {
            const modalId = modal.id;
            const openModalButtons = document.querySelectorAll(`[data-modal-toggle="${modalId}"]`);
            const closeModalButtons = document.querySelectorAll(`[data-modal-hide="${modalId}"]`);

            openModalButtons.forEach(button => {
                button.addEventListener('click', function () {
                    modal.classList.remove('hidden');
                    modal.classList.add('flex');
                    modal.setAttribute('aria-hidden', 'false');
                });
            });

            closeModalButtons.forEach(button => {
                button.addEventListener('click', function () {
                    modal.classList.add('hidden');
                    modal.classList.remove('flex');
                    modal.setAttribute('aria-hidden', 'true');
                });
            });
        });
    }

    setupModalToggle();

    if (window.Turbo) {
        document.addEventListener('turbo:load', setupModalToggle);
    } else if (window.Turbolinks) {
        document.addEventListener('turbolinks:load', setupModalToggle);
    }
});


