import CU from "@mixins/currentUser.js";

export default {
    formatPrice(value, precision) {
        let val = (value / 1).toFixed(precision)
        return val.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".")
    },

    shortNumber(count, withAbbr = false, decimals = 2) {
        const COUNT_ABBRS = ['', 'K', 'M', 'B', 'T'];
        const i = 0 === count ? count : Math.floor(Math.log(count) / Math.log(1000));
        let result = parseFloat((count / Math.pow(1000, i)).toFixed(decimals));
        if (withAbbr) {
            result += `${COUNT_ABBRS[i]}`;
        }
        return result;
    },

    formattedDate(dateStr, dayName = true, timeOnly = false, setedFormat = '') {
        if (!moment(dateStr).isValid()) return '';

        let currentUser = CU.methods.currentUser()

        let date = currentUser && currentUser.timezone ? moment(dateStr).tz(currentUser.timezone) : moment(dateStr)
        let format = setedFormat

        if(format == '') {
            if (timeOnly) {
                format = currentUser && currentUser.am_format ? 'h:mm A' : 'H:mm'
            } else {
                format = dayName ? 'ddd, ' : ''
                format += currentUser && currentUser.am_format ? 'MMM D h:mm A' : 'MMM D H:mm'
            }
        }

        return date.format(format);
    },

    formattedTime(time) {
        let currentUser = CU.methods.currentUser()
        if (currentUser && currentUser.am_format) {
            var H = +time.substr(0, 2);
            var h = (H % 12) || 12;
            var ampm = H < 12 ? "AM" : "PM";
            return h + time.substr(2, 3) + ampm;
        } else {
            return time
        }
    },

    dateToformat(value, format) {
        return moment(value).format(format)
    },

    capitalize(value) {
        if (!value) return ''
        value = value.toString()
        return value.charAt(0).toUpperCase() + value.slice(1)
    },

    lowercase(value) {
        return (value || value === 0) ? value.toString().toLowerCase() : ''
    },

    timeToSession(diffInMills, hide00 = false) {
        let _24hInMills = 86400000

        if (diffInMills > _24hInMills * 2) {
            return `${Math.floor(diffInMills / _24hInMills)} days`
        } else if (diffInMills > _24hInMills) {
            let h = Math.floor(diffInMills / 1000 / 60 / 60);
            h = h < 10 ? `0${h}` : `${h}`
            return `${h}+ hrs`
        } else {
            let h = Math.floor(diffInMills / 1000 / 60 / 60);
            let m = Math.floor((diffInMills / 1000 / 60 / 60 - h) * 60);
            let s = Math.floor(((diffInMills / 1000 / 60 / 60 - h) * 60 - m) * 60);

            s = s < 10 ? `0${s}` : `${s}`
            m = m < 10 ? `0${m}` : `${m}`
            h = h < 10 ? `0${h}` : `${h}`

            return `${h}:${m}:${s}`
        }
    },

    minsToHours(val) {
        let intVal = parseInt(val)
        if (intVal) {
            return intVal / 60
        }
    }

}