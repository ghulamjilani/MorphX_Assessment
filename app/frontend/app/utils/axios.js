import axios from "@plugins/axios.js"
import store from '@store/store'
import User from '@models/User'
// import createAuthRefreshInterceptor from 'axios-auth-refresh'
import {getCookie, setCookie} from "@utils/cookies"
import RailsConfig from '@plugins/rails_config'

window.parseJwt = (token) => {
    try {
        return JSON.parse(atob(token.split('.')[1]));
    } catch (e) {
        return null;
    }
};

// Add a request interceptor
// add jwt to request header
axios.interceptors.request.use((config) => {
    let jwt = getCookie('_unite_session_jwt');
    if (jwt && !config.headers.Authorization) {
        config.headers.Authorization = `Bearer ${jwt}`
    }
    return config
})

axios.defaults.headers.common['Content-Type'] = 'application/json';
axios.defaults.headers.common['Accept'] = 'application/json';

// SETUP REFRESH AUTH TOKEN

var updateCookiesFromJwtResponse = (res) => {
    if (res.data.response.jwt_token) {
        setCookie("_unite_session_jwt", res.data.response.jwt_token, +(parseJwt(res.data.response.jwt_token)?.exp + '000'))
        setCookie("_cable_jwt", res.data.response.jwt_token, +(parseJwt(res.data.response.jwt_token)?.exp + '000'), location.hostname)
        setCookie("_unite_session_jwt_refresh", res.data.response.jwt_token_refresh, +(parseJwt(res.data.response.jwt_token_refresh)?.exp + '000'))
        localStorage.setItem("_unite_session_jwt_refresh", res.data.response.jwt_token_refresh);
        localStorage.setItem("_unite_session_uid", parseJwt(res.data.response.jwt_token).id)
        window.eventHub.$emit("updateJwt")
    } else {
        deleteCookie("_unite_session_jwt")
        deleteCookie("_cable_jwt")
        deleteCookie('_unite_session_jwt_refresh')
        window.eventHub.$emit("updateJwt")
    }
}

var updateCurrentUserFromJwtResponse = (res) => {
    if (res.data.response.jwt_token) {
        User.api().currentUser().then(cu => {
            store.dispatch("Users/setCurrents", cu.response.data.response)
        }).catch(err => {
            console.log(err)
        })
    }
}

var updateJWT = () => {
    if (window.spaMode === "monolith") return
    let refresh = getCookie('_unite_session_jwt_refresh')
    if (!refresh) return
    axios.get("/api/v1/auth/user_tokens", {headers: {'Authorization': `Bearer ${refresh}`}}).then((res) => {
        updateCookiesFromJwtResponse(res)
        updateCurrentUserFromJwtResponse(res)
    }).catch(() => {
        store.dispatch("Users/setCurrents", null)
    })
}

window.updateCookiesFromJwtResponse = updateCookiesFromJwtResponse

var checkJWT = () => {
    let exp = parseJwt(getCookie('_unite_session_jwt'))?.exp + "000"
    let refresh = getCookie('_unite_session_jwt_refresh')
    if (+exp - new Date().getTime() <= 0 || (exp + "").includes("undefined")) {
        if (!refresh) return
        updateJWT()
    }
}

// Function that will be called to refresh authorization
const refreshAuthLogic = failedRequest => {
    if(getCookie('_unite_session_jwt_refresh')) {
        axios.get("/api/v1/auth/user_tokens", {
            headers: {
                'Authorization':
                    `Bearer ${getCookie('_unite_session_jwt_refresh')}`
                }
        }).then(res => {
            updateCookiesFromJwtResponse(res)
            updateCurrentUserFromJwtResponse(res)
        });
    }
}

// Instantiate the interceptor (you can chain it as it returns the axios instance)
// createAuthRefreshInterceptor(axios, refreshAuthLogic);

// Check JWT on fist SPA loading
checkJWT()

// check and update JWT
var check_jwt_exp = 2 * 60 * 1000
var update_jwt_if_less = 10 * 60 * 1000

if (RailsConfig.frontend.security && RailsConfig.frontend.security.jwt.check_jwt_exp) {
    check_jwt_exp = RailsConfig.frontend.security.jwt.check_jwt_exp * 60 * 1000
}
if (RailsConfig.frontend.security && RailsConfig.frontend.security.jwt.update_jwt_if_less) {
    update_jwt_if_less = RailsConfig.frontend.security.jwt.update_jwt_if_less * 60 * 1000
}

setInterval(function () {
    let token = getCookie('_unite_session_jwt');
    let tokenExp = +(parseJwt(token)?.exp) + '000';
    if (+tokenExp - new Date().getTime() < update_jwt_if_less) {
        updateJWT()
    }
}, check_jwt_exp)

export default axios;