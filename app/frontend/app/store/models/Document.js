import store from '@store/store'
import {Model} from '@vuex-orm/core'
import documentsTransformer from "@data_transformers/documentsTransformer"
import utils from '@helpers/utils'
import utils_h from '@/utils/helper'

const user_model_path = '/api/v1/user/documents'
const public_model_path = '/api/v1/public/documents'
const dynamic_model_path = () => {
    let currentUser = store.getters["Users/currentUser"]
    return currentUser ? user_model_path : public_model_path
}

export default class Document extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'documents'

    static fields() {
        return {
            id: this.attr(null),
            title: this.string(""),
            description: this.string(""),
            hidden: this.attr(false),
            file_path: this.attr(null),
            file_size: this.attr(0),
            file_extension: this.attr(null),
            sm_preview_path: this.attr(''),
            lg_preview_path: this.attr(''),
            purchase_price: this.attr(0),
            only_ppv: this.attr(false),
            only_subscription: this.attr(false),

            channel_id: this.attr(null),

            created_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z
            updated_at: this.string(value => utils.dateToTimeZone(value)) // 2020-06-30T12:00:00.000Z

            // UI data
        }
    }

    static apiConfig = {
        // headers: { 'X-Requested-With': 'XMLHttpRequest' },
        // baseURL: 'https://example.com/api/'
        dataTransformer: ({data, headers}) => {
            return documentsTransformer.single({data, headers})
        },
        actions: {
            fetch(params = {}) {
                return this.get(dynamic_model_path(), {
                    params: params,
                    dataTransformer: ({data, headers}) => {
                        return documentsTransformer.multiple({data, headers})
                    }
                })
            },
            fetchOne(params = {}) {
                return this.get(`${dynamic_model_path()}/${params.id}`)
            },
            create(params = {}) {
                return this.post(dynamic_model_path(), {document: params})
            },
            update(params = {}) {
                return this.put(`${dynamic_model_path()}/${params.id}`, params)
            },
            remove(params = {}) {
                return this.delete(`${dynamic_model_path()}/${params.id}`, {delete: params.id})
            },
            buyPPV(params = {}) {
                return this.post(`/api/v1/user/documents/${params.document_id}/buy`, params)
            }
        }
    }

    get filename(){
        return this.title || this.file_path?.split('/')?.pop()
    }

    get downloadUrl() {
        return this.file_path ? (window.location.origin + this.file_path) : null
    }

    get fileExt() {
        return this.file_extension || this.file_path?.split('.')?.pop()
    }

    get formattedCreatedAt(){
        return moment(this.created_at).format('D MMM YYYY h:mm A')
    }

    get formattedDate(){
        return moment(this.created_at).format('MM.DD.YYYY')
    }

    get formattedFileSize(){
        return utils_h.formatBytes(this.file_size, 0)
    }

}