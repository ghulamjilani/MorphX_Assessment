import {Model} from '@vuex-orm/core'
import contactsTransformer from "@data_transformers/contactsTransformer"
import utils from '@helpers/utils'

export default class Contact extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'contacts'

    static fields() {
        return {
            id: this.attr(null),
            status: this.string(""),
            email: this.string(""),
            name: this.string(""),

            for_user_id: this.attr(null),
            contact_user_id: this.attr(null),
            created_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z
            updated_at: this.string(value => utils.dateToTimeZone(value)), // 2020-06-30T12:00:00.000Z

            // UI data
            isEdit: this.boolean(false),
            isSelected: this.boolean(false)
        }
    }

    static apiConfig = {
        actions: {
            fetch(params = {}) {
                return this.get("/api/v1/user/contacts", {
                    params: params,
                    persistBy: 'create',
                    dataTransformer: ({data, headers}) => {
                        return contactsTransformer.multiple({data, headers})
                    }
                })
            },

            fetchOnlyData(params = {}) {
                return this.get("/api/v1/user/contacts", {
                    params: params,
                    // persistBy: 'create',
                    dataTransformer: ({data, headers}) => {
                        return contactsTransformer.empty({data, headers})
                    }
                })
            },

            fetchCSV(params = {}) {
                return this.post("/api/v1/user/contacts/export_to_csv", {ids: params.ids})
            },

            create(params = {}) {
                return this.post("/api/v1/user/contacts", {
                    email: params.email,
                    public_display_name: params.first_name + ' ' + params.last_name
                }, {
                    dataTransformer: ({data, headers}) => {
                        return contactsTransformer.single({data, headers})
                    }
                })
            },

            importFromCSV(params = {}) {
                let formData = new FormData()
                formData.append("file", params.file)
                return this.post("/api/v1/user/contacts/import_from_csv", formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    },
                    dataTransformer: ({data, headers}) => {
                        return contactsTransformer.single({data, headers})
                    }
                })
            },

            update(params = {}) {
                return this.put(`/api/v1/user/contacts/${params.id}`, params,
                    {
                        dataTransformer: ({data, headers}) => {
                            return contactsTransformer.single({data, headers})
                        }
                    })
            },

            remove(params = {}) {
                return this.delete('/api/v1/user/contacts', {
                    data: {
                        ids: params.ids
                    },
                    persistBy: 'create',
                    dataTransformer: ({data, headers}) => {
                        return contactsTransformer.multiple({data, headers})
                    }
                })
            }
        }
    }
}