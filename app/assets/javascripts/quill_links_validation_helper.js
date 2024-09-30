function validateLinks(element){
    var RegExp = /^((ftp|http|https):\/\/)?(www\.)?([A-Za-zА-Яа-я0-9]{1}[A-Za-zА-Яа-я0-9\-]*\.?)*\.{1}[A-Za-zА-Яа-я0-9-]{2,8}(\/([\w#!:.?+=&%@!\-\/])*)?/;
    if(RegExp.test(element.target.value)) {
        element.target.nextElementSibling.classList.remove('disabled');
        element.target.classList.remove('error');
        document.querySelector('.ql-tooltip').classList.remove('error');
    } else {
        element.target.nextElementSibling.classList.add('disabled');
        document.querySelector('.ql-tooltip').classList.add('error');
        element.target.classList.add('error');
    }
}

function clearLinks(element){
    setTimeout(() => {
        if(element.target.parentElement.classList.contains('ql-hidden')){
            element.target.value = '';
            element.target.nextElementSibling.classList.remove('disabled');
            element.target.classList.remove('error');
            document.querySelector('.ql-tooltip').classList.remove('error');
        }
    }, 200)
}