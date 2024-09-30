import {Model} from '@vuex-orm/core'

export default class Products extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'products'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            fetchLists(params = {}) {
                return this.get('/api/v1/public/shop/lists', {
                    params: params
                })
            },
            fetchProducts(params = {}) {
                return this.get('/api/v1/public/shop/products', {
                    params: params
                })
            },
        }
    }
}