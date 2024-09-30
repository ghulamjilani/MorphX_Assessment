<template>
    <div
        :class="{ 'is-opened': isOpened }"
        class="ChannelLineTile"
        @click="$emit('showDocuments')" >
        <router-link
            :to="{path: channel.relative_path}"
            @click.stop>
            <div
                :style="channel.logo_url ? `background-image: url('${channel.image_preview_url}')` : ''"
                class="ChannelLineTile__logo"
                @click.stop />
        </router-link>
        <div class="ChannelLineTile__flex">
            <div class="ChannelLineTile__info">
                <div
                    class="ChannelLineTile__title"
                    @dblclick="openChannelInNewTab">
                    {{ channel.title }}
                </div>
                <div class="ChannelLineTile__date">
                    {{ createDate }}
                </div>
            </div>
            <div
                class="ChannelLineTile__count"
                v-if="docCount && docCount > 0">
                {{ $t('frontend.app.components.channel.line_tile.documents', {count: docCount}) }}
            </div>
            <div class="ChannelLineTile__actions">
                <m-btn
                    v-if="channel.can_manage_documents && channel.can_add_documents"
                    type="bordered"
                    @click.stop.prevent="$emit('documentsUploader')">
                    {{ $t('frontend.app.components.channel.line_tile.add_document') }} <i class="GlobalIcon-upload" />
                </m-btn>
            </div>
        </div>
        <div class="ChannelLineTile__icon">
            <i class="GlobalIcon-angle-down color__icons" />
        </div>
    </div>
</template>

<script>
import Document from "@models/Document"
export default {
    props: {
        channel: {type: Object},
        isOpened: {type: Boolean},
    },
    data() {
        return {
            docCount: 0
        }
    },
    computed: {
        createDate() {
            return moment(this.channel.created_at).format('MM.DD.YYYY')
        }
    },
    methods: {
        openChannelInNewTab() {
            window.open(this.channel.url, '_blank')
        },
        documentCount() {
            Document.api().fetch({channel_id: this.channel.id, limit:1, dashboard: "1"}).then((res) => {
                this.docCount = res.response.data.pagination.count
            })
        }
    },
    mounted() {
        this.documentCount()
        this.$eventHub.$on("documentCountUpdate", () => {
            this.documentCount()
        })
    }
}
</script>