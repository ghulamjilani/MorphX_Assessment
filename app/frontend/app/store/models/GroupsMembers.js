import {Model} from '@vuex-orm/core'
import groupsMembersTransformer from "@data_transformers/groupsMembersTransformer"

export default class GroupsMembers extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'groups_members'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            update(params = {}) {
                return this.put(`/api/v1/user/access_management/organizations/${params.organization_id}/group_members/${params.group_id}`, {
                        channel_ids: params.channel_ids
                    },
                    {
                        dataTransformer: ({data, headers}) => {
                            return groupsMembersTransformer.updateOrganizationMemberships({data, headers})
                        }
                    }
                )
            }
        }
    }
}