import {mapActions} from 'vuex'
import Creator from '@models/Creator'

export default {
    methods: {
        ...mapActions({
            updateParams: 'UPDATE_SEARCH_PARAMS'
        }),
        getCurrentQuery() {
            if (!window.location.search) return {};
            let resultParams = {}

            decodeURI(window.location.search.slice(1))
                .replace(/"/g, '\\"')
                .replace(/&/g, ',')
                .replace(/=/g, ':')
                .split(',')
                .forEach((param) => {
                    let [key, val] = param.split(':')

                    if (key.includes('[]')) {
                        let _key = key.slice(0, -2)
                        if (resultParams[_key]) {
                            resultParams[_key].push(val)
                        } else {
                            resultParams[_key] = [val]
                        }
                    } else {
                        resultParams[key] = key.includes('q') ? decodeURIComponent(val.replace(/\+/g, '%20')) : val
                    }
                })

            const isDate = resultParams['fdt'] ? resultParams['fdt'].includes('custom-date') : null
            if (isDate) {
                resultParams['fdt'] = decodeURI(resultParams['fdt']).replace(/%3A/g, ':').replace(/\+/g, ' ').replace(/%2C/g, ',').replace(/\\/g, '');
            }

            return resultParams
        },

        prepareParams(inputParams, prefix = '') {
            let outputParams = {}
            Object.keys(inputParams).forEach((key) => {
                switch (key) {
                    case `${prefix}cra`:
                        if (inputParams[key].length) {
                            outputParams.user_id = inputParams[key].toString()
                        }
                        break;
                    case `${prefix}dra`:
                        // todo: chrck creators name for api
                        outputParams.durations = inputParams[key]
                        break;
                    case `${prefix}dta`:
                        // todo: chrck creators name for api
                        outputParams.dates = inputParams[key]
                        break;
                    case `${prefix}t`:
                        if (inputParams[key] !== 'all') {
                            outputParams.searchable_type = inputParams[key]
                        }
                        break;
                    case `${prefix}dt`:
                        if (inputParams[key].includes('custom-date')) {
                            const dateObj = JSON.parse(inputParams[key])
                            const dateFrom = dateObj.value.split(' - ')[0]
                            const dateTo = dateObj.value.split(' - ')[1]
                            var dateFromFormat = moment(dateFrom).startOf('day').toISOString()
                            var dateToFormat = moment(dateTo).endOf('day').toISOString()

                            if (this.isSearch && inputParams['ft'] === 'Session') {
                                outputParams.end_after = dateFromFormat
                                outputParams.start_before = dateToFormat
                            } else {
                                outputParams.created_after = dateFromFormat
                                outputParams.created_before = dateToFormat
                            }
                        }
                        switch (inputParams[key]) {
                            case 'all':
                                // skip
                                break;
                            case 'today':
                                if (this.type === 'Session') {
                                    outputParams.end_after = moment().toISOString()
                                    outputParams.start_before = moment().endOf('day').toISOString()
                                } else {
                                    outputParams.created_after = moment().startOf('day').toISOString()
                                    outputParams.created_before = moment().endOf('day').toISOString()
                                }
                                break;
                            case 'thisWeek':
                                if (this.type === 'Session') {
                                    outputParams.end_after = moment().toISOString()
                                    outputParams.start_before = moment().endOf('week').toISOString()
                                } else {
                                    outputParams.created_after = moment().startOf('week').toISOString()
                                    outputParams.created_before = moment().endOf('week').toISOString()
                                }
                                break;
                            case 'thisMonth':
                                if (this.type === 'Session') {
                                    outputParams.end_after = moment().toISOString()
                                    outputParams.start_before = moment().endOf('month').toISOString()
                                } else {
                                    outputParams.created_after = moment().startOf('month').toISOString()
                                    outputParams.created_before = moment().endOf('month').toISOString()
                                }
                                break;
                            case 'thisYear':
                                if (this.type === 'Session') {
                                    outputParams.end_after = moment().toISOString()
                                    outputParams.start_before = moment().endOf('year').toISOString()
                                } else {
                                    outputParams.created_after = moment().startOf('year').toISOString()
                                    outputParams.created_before = moment().endOf('year').toISOString()
                                }
                                break;
                        }
                        break;
                    case `${prefix}dr`:
                        switch (inputParams[key]) {
                            case 'all':
                                // skip
                                break;
                            case 'short':
                                outputParams.duration_from = 0
                                outputParams.duration_to = 30 * 60
                                break;
                            case 'mid':
                                outputParams.duration_from = 30 * 60
                                outputParams.duration_to = 60 * 60
                                break;
                            case 'long':
                                outputParams.duration_from = 60 * 60
                                break;
                        }
                        break;
                    case `${prefix}pr`:
                        switch (inputParams[key]) {
                            case 'all':
                                // scip
                                break;
                            case 'paid':
                                outputParams.free = false
                                break;
                            case 'free':
                                outputParams.free = true
                                break;
                        }
                        break;
                    case `${prefix}ord`:
                        switch (inputParams[key]) {
                            case 'new':
                                if (this.type === 'Session') {
                                    outputParams.order_by = 'start_at'
                                    outputParams.order = 'asc'
                                } else if (this.type === 'Video') {
                                    outputParams.order_by = 'start_at'
                                    outputParams.order = 'desc'
                                } else {
                                    outputParams.order_by = 'listed_at'
                                    outputParams.order = 'desc'
                                }
                                break;
                            case 'views_count':
                                outputParams.order_by = 'views_count'
                                break;
                            case 'rank':
                                outputParams.order_by = 'rank'
                                outputParams.order = 'desc'
                                break;
                        }
                        break;
                    case `${prefix}q`:
                        if (inputParams[key]) {
                            outputParams.query = inputParams[key]
                            if (!this.isSearch) {
                                outputParams.search_by = 'title'
                            }
                        }
                        break
                }
            })
            this.updateParams(outputParams)
            return outputParams;
        },

        clearPrams(params) {
            Object.keys(params).forEach((key) => {
                if (params[key] == 'all' || params[key] == '') {
                    delete params[key]
                }
            })
            return params
        }
    }
}