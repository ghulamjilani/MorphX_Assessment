$.validator.addMethod('includeLowercase', function(value, element) {
    return !!value.match(/[a-zа-я]+/);
}, 'Password must contain at least one lowercase letter');

$.validator.addMethod('includeUppercase', function(value, element) {
    return !!value.match(/[A-ZА-Я]+/);
}, 'Password must contain at least one uppercase letter');

$.validator.addMethod('includeNumber', function(value, element) {
    return !!value.match(/[0-9]+/);
}, 'Password must contain at least one numeric digit');

$.validator.addMethod('includeSpecialChar', function(value, element) {
    return !!value.match(/[!@_#%&\-\$\^\*]+/);
}, 'Password must contain at least one special character: !@_#-$%^&*');

$.validator.addMethod('strengthPassword', function(value, element) {
    if (!arguments[2])
        return true
    return $(element).data('isPasswordValid')
}, 'Inalid password');

function showPassword (selector, eyeSelector) {
    var eye = $(eyeSelector);
    var elem = $(selector);
    var type = elem.attr('type');
    if (type === 'password') {
        elem.attr('type', 'text');
        eye.addClass('off')
    } else {
        elem.attr('type', 'password');
        eye.removeClass('off')
    }
}

function addCapsListner (selector, capsSelector) {
    var capsElement = $(capsSelector);
    var element = document.querySelector(selector);
    if (element) {
        $(element).on('keypress', function (e) {
            var s = String.fromCharCode( e.which );
            if ( s.toUpperCase() === s && s.toLowerCase() !== s && !e.shiftKey ) {
                capsElement.addClass('show');
            } else{
                capsElement.removeClass('show');
            }
        });
    } else {
        $(document).on('keyup', function (e) {
            var s = String.fromCharCode( e.which );
            if ( s.toUpperCase() === s && s.toLowerCase() !== s && !e.shiftKey ) {
                capsElement.addClass('show');
            } else{
                capsElement.removeClass('show');
            }
        });
    }
}

function calculatePasswordStrength(containerEl) {
    var container = $(containerEl);
    var passwordEl = container.find('.strength-password');
    if (!passwordEl) {
        return
    }

    var password = passwordEl.val();
    if (!password) {
        container.find('.passStrength-2-Wrap').removeClass('weak acceptable strong');
        container.find('.passStrength-2-Wrap .passStrength-2-Message').css('visibility', 'hidden');
        return
    }

    var score = 0;
    var letters = {};
    var acceptableScore = 30;
    var strongScore = 80;

    var passwordStrength = 'weak'; // weak, acceptable, strong

    var lengthMore6 = password.replace(/ /g, "").length > 5;
    var includeLowercase = !!password.match(/[a-zа-я]+/);
    var includeUppercase = !!password.match(/[A-ZА-Я]+/);
    var includeNumber = !!password.match(/[0-9]+/);
    var includeSpecialChar = !!password.match(/[!@_#%&\-\$\^\*]+/);
    var lengthLess128 = password.length < 128;
    var isPasswordValid = includeLowercase &&
        includeUppercase &&
        includeNumber &&
        lengthMore6 &&
        lengthLess128;

    if (isPasswordValid) {
        score += 30;

        if (includeSpecialChar) {
            score += 10
        }

        for (var i = 0; i < password.length; i++) {
            letters[password[i]] = (letters[password[i]] || 0) + 1;
            score += 5.0 / letters[password[i]];
        }

        if (score > acceptableScore) {
            passwordStrength = 'acceptable'
        }
        if (score > strongScore) {
            passwordStrength = 'strong'
        }
    }

    score > acceptableScore ? container.find('.password-Strength-2-tooltip').hide() : container.find('.password-Strength-2-tooltip').show()
    container.find('.passStrength-2-Wrap').removeClass('weak acceptable strong').addClass(passwordStrength);
    container.find('.passStrength-2-Wrap .passStrength-2-Message').html(passwordStrength + " Password").css('visibility', 'visible');
    container.find('.strength-password').data('isPasswordValid', isPasswordValid)
    return isPasswordValid
}

$(document).ready(function () {
    if ($('#signupPopup').length > 0) {
        addCapsListner('#signupPopup .passInput', '#signupPopup .showSignupCaps, #signupPopup .showSignupMacCaps');
        $('body').on('click', '#signupPopup .showSignupPassword, #signupPopup .showSignupMacPassword', function (e) {
            showPassword('#signupPopup .passInput', '#signupPopup .showSignupPassword');
            $('.showSignupMacPassword').toggleClass('active');
        })
    }
    if ($('#loginPopup').length > 0) {
        addCapsListner('#loginPopup #userPassword', '#loginPopup .showSigninCaps, #loginPopup .showSignInMacCaps');
        $('body').on('click', '#loginPopup .showLoginPassword, #loginPopup .showSignInMacPassword', function (e) {
            showPassword('#loginPopup #userPassword', '#loginPopup .showLoginPassword');
            $('.showSignInMacPassword').toggleClass('active');
        })
    }
    if ($('body').hasClass('users-passwords-edit')) {
        addCapsListner('#user_password', '.showEditCaps, .showEditMacCaps');
        addCapsListner('#user_password_confirmation', '.showEditConfirmCaps, .showEditConfirmMacCaps');

        $('body').on('click', '.showEditPassword, .showEditMacPassword', function (e) {
            showPassword('#user_password', '.showEditPassword, .showEditMacPassword')
        }).on('click', '.showEditConfirmPassword, .showEditConfirmMacPassword', function (e) {
            showPassword('#user_password_confirmation', '.showEditConfirmPassword, .showEditConfirmMacPassword')
        });
    }
    if ($('body.profiles-edit_application, body.profiles-update_application').length > 0) {
        addCapsListner('#profile_current_password', '.showEditCurrentCaps, .showEditCurrentMacCaps');
        addCapsListner('#profile_password', '.showEditCaps, .showEditMacCaps');
        addCapsListner('#profile_password_confirmation', '.showEditConfirmCaps, .showEditConfirmMacCaps');

        $('body').on('click', '.showEditCurrentPassword, .showEditCurrentMacPassword', function (e) {
            showPassword('#profile_current_password', '.showEditCurrentPassword, .showEditCurrentMacPassword')
        }).on('click', '.showEditPassword, .showEditMacPassword', function (e) {
            showPassword('#profile_password', '.showEditPassword, .showEditMacPassword')
        }).on('click', '.showEditConfirmPassword, .showEditConfirmMacPassword', function (e) {
            showPassword('#profile_password_confirmation', '.showEditConfirmPassword, .showEditConfirmMacPassword')
        })
    }
    if($('#ad-password').length > 0){
        addCapsListner('#ad-password', '.ad-showSignupCaps, .ad-showSignupMacCaps');
        $('.ad-showSignupPassword, .ad-showSignupMacPassword').click(function (e) {
            showPassword('#ad-password', '.ad-showSignupPassword, .ad-showSignupMacPassword');
        })
    }
});
