import {Model} from '@vuex-orm/core'

export default class Article extends Model {
    // This is the name used as module name of the Vuex Store.
    static entity = 'article'

    static fields() {
        return {
            id: this.attr(null),
            body_preview: this.attr(null),
            body: this.attr(null),
            channel: this.attr(null),
            channel_id: this.attr(null),
            comments_count: this.attr(null),
            cover_url: this.string(""),
            hide_author: this.attr(null),
            logo_url: this.string(""),
            organization: this.attr(null),
            organization_id: this.attr(null),
            published_at: this.string(""),
            relative_path: this.string(""),
            status: this.attr(null),
            title: this.attr(null),
            user: this.attr(null),
            views_count: this.attr(null),
            slug: this.attr(null),
        }
    }
}