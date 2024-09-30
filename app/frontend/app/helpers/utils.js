import store from '@store/store'

export default {
    removeDuplicates(arr, key) {
        arr.reverse()
        return [...new Map(arr.map(item => [item[key], item])).values()]
    },

    debounce(fn, delay) {
        var timeoutID = null
        return function () {
            clearTimeout(timeoutID)
            var args = arguments
            var that = this
            timeoutID = setTimeout(function () {
                fn.apply(that, args)
            }, delay)
        }
    },

    dateToTimeZone(date, returnMoment = false) {
        if (!date) {
            return ""
        }

        let convertedDate
        let currentUser = store.getters["Users/currentUser"]

        if (typeof date == 'string') {
            convertedDate = currentUser ? moment(date).tz(currentUser.timezone) : moment(date)
        } else if (date._isAMomentObject) {
            convertedDate = currentUser ? date.tz(currentUser.timezone) : date
        } else {
            return ""
        }

        return returnMoment ? convertedDate : convertedDate.format()
    },
}

if ((!Array.prototype.unique)) {
    Object.defineProperty(Array.prototype, 'unique', {
        enumerable: false,
        configurable: false,
        writable: false,
        value: function () {
            var a = this.concat();
            for (var i = 0; i < a.length; ++i) {
                for (var j = i + 1; j < a.length; ++j) {
                    if (a[i] === a[j])
                        a.splice(j--, 1);
                }
            }

            return a;
        }
    });
} else {
    console.log("Array.prototype.unique defined early")
}

Array.prototype.equals = function (array) {
    // if the other array is a falsy value, return
    if (!array)
        return false;

    // compare lengths - can save a lot of time
    if (this.length != array.length)
        return false;

    for (var i = 0, l = this.length; i < l; i++) {
        // Check if we have nested arrays
        if (this[i] instanceof Array && array[i] instanceof Array) {
            // recurse into the nested arrays
            if (!this[i].equals(array[i]))
                return false;
        } else if (this[i] != array[i]) {
            // Warning - two different object instances will never be equal: {x:20} != {x:20}
            return false;
        }
    }
    return true;
}
// Hide method from for-in loops
Object.defineProperty(Array.prototype, "equals", {enumerable: false});