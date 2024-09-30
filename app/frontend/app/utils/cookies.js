export function getCookie(cname) {
    var name = cname + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') {
            c = c.substring(1);
        }
        if (c.indexOf(name) == 0) {
            return c.substring(name.length, c.length);
        }
    }
    return '';
}

export function setCookie(cname, cvalue, exp = new Date().getTime() + (365 * 24 * 60 * 60 * 1000), domain = null) {
    var d = new Date();
    d.setTime(exp);
    var expires = "expires=" + d.toUTCString();
    var cookieString = cname + "=" + cvalue + ";" + expires + ";path=/";
    if (domain) {
        cookieString += ';domain=' + domain;
    }
    document.cookie = cookieString;
}

export function deleteCookie(name) {
    var domain = location.host; // 'my.example.com'
    var domainParts = domain.split('.').reverse(); // 'my.example.com' -> ['com', 'example', 'my']

    setCookie(name, '', -1); // delete 'my.example.com'
    setCookie(name, '', -1, domain); // delete '.my.example.com'

    while (domainParts.length > 2) {
        domainParts.pop(); // ['com', 'example', 'my'] -> ['com', 'example']
        domain = domainParts.reverse().join('.') // ['com', 'example'] ->  'example.com'
        setCookie(name, '', -1, domain); // delete '.example.com'
    }
}
