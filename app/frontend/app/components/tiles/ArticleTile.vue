<template>
    <m-card
        v-if="model"
        class="ArticleTile">
        <template #top>
            <div class="cardMK2__imgWrapper">
                <a :href="model.relative_path">
                    <div class="cardMK2__chips">
                        <m-chips>{{ $t('frontend.app.components.tiles.article_tile.label') }}</m-chips>
                    </div>
                    <div
                        :style="`background-image: url(${model.cover_url})`"
                        class="cardMK2__imgContainer" />
                </a>
                <moderate-tiles
                    :item="model"
                    type="Blog::Post"
                    :use-promo-weight="usePromoWeight" />
            </div>
        </template>
        <template #bottom>
            <div class="cardMK2__tile-body">
                <div
                    class="fs__16 text__bold cursor-pointer cardMK2__tile-body__title"
                    @click="goTo(model.relative_path)"
                    @click.middle="goTo(model.relative_path, true)">
                    {{ model.title }}
                </div>
                <div class="cardMK2__tileBody__bottomSection">
                    <div class="fs__14 cursor-pointer">
                        <div class="orgSection">
                            <a
                                class="orgSection__img"
                                :href="model.organization.relative_path"
                                :style="`background-image: url(${model.organization.logo_url})`" />
                            <div class="orgSection__text">
                                <p
                                    v-if="user && user.public_display_name"
                                    @click="openUserModal()">
                                    {{ $t('session_tile.by') }} {{ user.public_display_name }}
                                </p>
                                <a
                                    :href="model.organization.relative_path">
                                    {{ model.organization.name }}
                                </a>
                            </div>
                        </div>
                        <div class="dateCounts">
                            <span class="fs__14">
                                <timeago
                                    class="margin-r__10"
                                    :auto-update="30"
                                    :datetime="formattedDate" />
                                <!-- {{ formattedDate }} -->
                            </span>
                            <div class="counts">
                                <m-icon size="1.4rem">GlobalIcon-message-square</m-icon>({{ model.comments_count }})
                                <m-icon size="1.6rem">GlobalIcon-eye-2</m-icon>{{ model.views_count }}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </template>
    </m-card>
</template>

<script>

import Article from "@models/Article"

export default {
    props: ["itemId", "article", "usePromoWeight"],
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        defaultChannelPath(){
            return location.origin + this.model?.channel?.relative_path
        },
        user() {
            return this.model?.user || this.model?.presenter_user || this.model?.organizer
        },
        formattedDate() {
            let dt = this.model?.published_at
            let date = this.currentUser && this.currentUser.timezone ?
                moment(dt).tz(this.currentUser.timezone) : moment(dt)
            // let format = 'MMM D, H:mm'

            return date //.format(format)
        },
        model() {
            if(this.article) return this.article
            else return Article.query().whereId(this.itemId).first()
        }
    },
    methods: {
        openUserModal(){
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: this.user
            })
        }
    }
}
</script>