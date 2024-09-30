import {Model} from '@vuex-orm/core'
import groupsTransformer from "@data_transformers/groupsTransformer"

export default class Groups extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'groups'

    static fields() {
        return {
            id: this.attr(null),
            code: this.string(),
            description: this.string(),
            enabled: this.boolean(),
            name: this.string(),
            credentials: this.attr(),
            system: this.boolean(),
            is_for_channel: this.boolean(),
            created_at: this.string(),
            updated_at: this.string(),
            color: this.string('#000000')
        }
    }

    static apiConfig = {
        actions: {
            allGroups() {
                return this.get("/api/v1/user/access_management/groups", {
                    dataTransformer: ({data, headers}) => {
                        return groupsTransformer.fetch({data, headers})
                    }
                })
            },
            createGroup(params = {}) {
                return this.post("/api/v1/user/access_management/groups", {
                    group: {
                        name: params.name,
                        color: params.color,
                        enabled: params.enabled,
                        description: params.description,
                        credential_ids: params.credential_ids
                    }
                }, {
                    dataTransformer: ({data, headers}) => {
                        return groupsTransformer.create({data, headers})
                    }
                })
            },
            updateGroup(params = {}) {
                return this.put(`/api/v1/user/access_management/groups/${params.id}`, {
                    group: {
                        name: params.name,
                        // color:           params.color,
                        enabled: params.enabled,
                        description: params.description,
                        credential_ids: params.credential_ids
                    }
                }, {
                    dataTransformer: ({data, headers}) => {
                        return groupsTransformer.create({data, headers})
                    }
                })
            }
        }
    }

}