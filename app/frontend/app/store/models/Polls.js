import {Model} from '@vuex-orm/core'
import {getCookie} from "@utils/cookies"

export default class Polls extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'polls'

    static fields() {
        return {
            id: this.attr(null)
        }
    }

    static apiConfig = {
        actions: {
            createTemplate(params = {}) {
                return this.post(`/api/v1/user/poll/poll_templates`, params, {})
            },
            createPoll(params = {}) {
                return this.post(`/api/v1/user/poll/poll_templates/${params.poll_template_id}/polls`, params, {})
            },
            updatePollTemplate(params = {}) {
                console.info('updatePollTemplate', params)
                return this.put(`/api/v1/user/poll/poll_templates/${params.poll_template_id}`, params, {})
            },
            deletePollTemplate(params = {}) {
                console.info('deletePollTemplate', params)
                return this.delete(`/api/v1/user/poll/poll_templates/${params.poll_template_id}`, {})
            },
            fetchPollTemplates(params = {}) {
                return this.get(`/api/v1/user/poll/poll_templates`, {params: params})
            },
            fetchPolls(params = {}) {
                return this.get(`/api/v1/user/poll/poll_templates/${params.poll_template_id}/polls`, {params: params})
            },
            vote(params = {}) {
                let options = {}
                if(getCookie('_guest_jwt')) {
                    options = {headers: {Authorization: getCookie('_guest_jwt')}}
                }
                return this.post(`/api/v1/user/poll/poll_templates/${params.poll_template_id}/polls/${params.poll_id}/vote`, params, options)
            },
            fetchPoll(params = {}) {
                return this.get(`/api/v1/public/poll/polls/${params.id}`)
            },
            stopPoll(params = {}) {
                return this.put(`/api/v1/user/poll/poll_templates/${params.poll_template_id}/polls/${params.poll_id}`, params, {})
            }
        }
    }
}