import {Model} from '@vuex-orm/core'

export default class Pagination extends Model {
    static entity = 'Pagination'

    static fields() {
        return {
            id: this.uid(),
            loading: this.boolean(false),
            total_pages: this.number(0),
            current_page: this.number(0),
            count: this.number(1),
            offset: this.number(0),
            limit: this.number(5)
        }
    }

    get areAllRecordsLoaded(){
        return (this.offset + this.limit) >= this.count
    }

    get nextPageParams(){
        let {offset, limit, total_pages} = this
        return {
            offset: total_pages === 0 ? offset : offset + limit,
            limit
        }
    }
}