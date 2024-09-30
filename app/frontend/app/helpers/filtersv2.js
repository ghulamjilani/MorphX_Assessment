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

        return date.format(format)
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

    capitalize(value) {
        if (!value) return ''
        value = value.toString()
        return value.charAt(0).toUpperCase() + value.slice(1)
    },

    lowercase(value) {
        return (value || value === 0) ? value.toString().toLowerCase() : ''
    },

    timeToSession(diffInMills) {
        let _24hInMills = 86400000

        if (diffInMills > _24hInMills * 2) {
            return `${Math.floor(diffInMills / _24hInMills)} days`
        } else if (diffInMills > _24hInMills) {
            return "24+ hrs"
        } else {
            let h = Math.floor(diffInMills / 1000 / 60 / 60);
            let m = Math.floor((diffInMills / 1000 / 60 / 60 - h) * 60);
            let s = Math.floor(((diffInMills / 1000 / 60 / 60 - h) * 60 - m) * 60);

            s < 10 ? s = `0${s}` : s = `${s}`
            m < 10 ? m = `0${m}` : m = `${m}`
            h < 10 ? h = `0${h}` : h = `${h}`

            return `${h}:${m}:${s}`
        }
    },

    datetimeToSession(diffInMills, hide00 = false) {
        let _24hInMills = 86400000
        let _1hInMills = 3600000

        if (diffInMills > _24hInMills) {
            let h = Math.floor(diffInMills % _24hInMills / 1000 / 60 / 60)
            let d = `${Math.floor(diffInMills / _24hInMills)} Days`
            return d += hide00 ? ` ${h < 10 ? '0' + h : h} Hrs`.replace(' 00 Hrs', '') : ` ${h < 10 ? '0' + h : h} Hrs`

        } else if (diffInMills < _1hInMills) {
            let m = Math.floor((diffInMills / 1000 / 60 / 60) * 60);
            let s = Math.floor(((diffInMills / 1000 / 60 / 60) * 60 - m) * 60);

            s = s < 10 ? `0${s}` : `${s}`
            m = m < 10 ? `0${m}` : `${m}`

            return hide00 ? `${m} min ${s} sec`.replace(/00\s\w+\s/g, '') : `${m} min ${s} sec`
        } else {
            let h = Math.floor(diffInMills / 1000 / 60 / 60);
            let m = Math.floor((diffInMills / 1000 / 60 / 60 - h) * 60);

            m = m < 10 ? `0${m}` : `${m}`
            h = h < 10 ? `0${h}` : `${h}`

            return hide00 ? `${h} hrs ${m} min`.replace(/00\s\w+\s/g, '') : `${h} hrs ${m} min`
        }
    },
    dateTimeWithZeros(diffInMills) {
        let h = Math.floor(diffInMills / 1000 / 60 / 60);
        let m = Math.floor((diffInMills / 1000 / 60 / 60 - h) * 60);
        let s = Math.floor((diffInMills / 1000) % 60);

        m = m < 10 ? `0${m}` : `${m}`
        h = h < 10 ? `0${h}` : `${h}`
        s = s < 10 ? `0${s}` : `${s}`

        return `${h}:${m}:${s}`
    },
    formattedPrice(amountInCents, options = {}) {
        let defaultOptions = {
            html_entity: '$',
            symbol_first: true,
            dropZeroes: false,
            decimalPlaces: 2,
            thousands_separator: ","
        }
        options = {...defaultOptions, ...options}

        let amountInDollars = Number(amountInCents / 100)
        let formattedPrice = Math.round(amountInDollars * 100) / 100

        if (options.dropZeroes && (amountInDollars - Math.floor(amountInDollars)) == 0) {
            formattedPrice = formattedPrice.toFixed(0)
        } else {
            formattedPrice = formattedPrice.toFixed(options.decimalPlaces)
        }

        if(options?.thousands_separator != "") {
            formattedPrice = formattedPrice.toString().replace(/\B(?=(\d{3})+(?!\d))/g, options.thousands_separator)
        }

        if (options.symbol_first) {
            formattedPrice = options.html_entity + formattedPrice
        } else {
            formattedPrice = formattedPrice + options.html_entity
        }
        return formattedPrice
    }
}