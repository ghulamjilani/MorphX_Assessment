import store from "@store/store"
import {Model} from '@vuex-orm/core'
import searchTransformer from "@data_transformers/searchTransformer"

export default class Search extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'search'

    static fields() {
        return {
            document: this.attr(null),
            searchable_model: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            search(params = {}, newPage = false) {
                let pagination = store.getters.getSearchPagination
                if (newPage) {
                    store.dispatch('UPDATE_SEARCH_PAGINATION')
                } else {
                    store.dispatch('RESET_SEARCH_PAGINATION')
                }
                store.dispatch('SET_SEARCH_LOADER', true)
                return this.get("/api/v1/public/search", {
                    params: {...params, ...pagination},
                    dataTransformer: ({data, headers}) => {
                        store.dispatch('SET_SEARCH_LOADER', false)
                        return searchTransformer.search({data, headers, newPage})
                    }
                })
            },
            searchApi(params = {}, newPage = false) {
                Object.keys(params).forEach(key => { if (params[key] === null) delete params[key] });
                return this.get("/api/v1/public/search", {
                    params
                })
            }
        }
    }
}