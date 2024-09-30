import {Model} from '@vuex-orm/core'
import organizationMembershipsTransformer from "@data_transformers/organizationMembershipsTransformer"

export default class OrganizationMemberships extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'organization_memberships'

    static fields() {
        return {
            id: this.attr(null),
            organization_id: this.number(),
            groups_members: this.attr(),
            status: this.string(),
            user: this.attr(),
            count: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            allOrganizationMemberships(params = {}) {
                return this.get(`/api/v1/user/access_management/organizations/${params.id}/organization_memberships`, {
                    params: params,
                    persistBy: 'create',
                    dataTransformer: ({data, headers}) => {
                        return organizationMembershipsTransformer.fetch({data, headers})
                    }
                })
            },
            organizationMembershipInfo(params = {}) {
                return this.get(`/api/v1/user/access_management/organizations/:organization_id/organization_memberships/${params.id}`, {params})
            },
            createOrganizationMembership(params = {}) {
                return this.post(`/api/v1/user/access_management/organizations/${params.id}/organization_memberships`, {
                    user_id: params.user_id,
                    email: params.email,
                    first_name: params.first_name,
                    last_name: params.last_name,
                    groups: params.groups
                }, {
                    dataTransformer: ({data, headers}) => {
                        return organizationMembershipsTransformer.create({data, headers})
                    }
                })
            },
            importOrganizationMembershipFromCSV(params = {}) {
                let formData = new FormData()
                formData.append("file", params.file)
                formData.append("groups", JSON.stringify(params.groups))
                return this.post(`/api/v1/user/access_management/organizations/${params.id}/organization_memberships/import_from_csv`, formData, {
                    headers: {
                        'Content-Type': 'multipart/form-data'
                    }
                }, {
                    dataTransformer: ({data, headers}) => {
                        return organizationMembershipsTransformer.create({data, headers})
                    }
                })
            },
            updateOrganizationMembershipStatus(params = {}) {
                return this.put(`/api/v1/user/organization_memberships/${params.id}`, params, {
                    dataTransformer: ({data, headers}) => {
                        return organizationMembershipsTransformer.create({data, headers})
                    }
                })
            },
            updateOrganizationMembership(params = {}) {
                return this.put(`/api/v1/user/access_management/organizations/${params.organizationId}/organization_memberships/${params.id}`, {
                    group_ids: params.group_ids
                }, {
                    dataTransformer: ({data, headers}) => {
                        return organizationMembershipsTransformer.create({data, headers})
                    }
                })
            },
            destroyOrganizationMembership(params = {}) {
                return this.delete(`/api/v1/user/access_management/organizations/:organization_id/organization_memberships/${params.id}`, {params})
            }
        }
    }
}