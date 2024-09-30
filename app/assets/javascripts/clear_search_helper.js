$('body').on("keyup", '.clearInput', checkInputField);
$('body').on("click", '.clearInputField', clearInputField);

function checkInputField(e) {
  let inputField = e.currentTarget;
  let clearBtn = inputField.closest('.clearableField').querySelector('.clearInputField');
  if (inputField.value == '') {
    clearBtn.classList.add("hidden");
  } else {
    clearBtn.classList.remove("hidden");
  }
}

function clearInputField(e) {
  let clearBtn = e.currentTarget;
  let inputField = clearBtn.closest('.clearableField').querySelector('.clearInput');
  inputField.value = '';
  clearBtn.classList.add('hidden');
}