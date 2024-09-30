<template>
    <div :class="className">
        <div
            :class="classNameImg"
            :style="backgroundImage">
            <a
                :href="shortUrl"
                class="tileMK2__img_link" />
            <!-- <m-avatar
                v-if="type == 'User'"
                size="m"
                star-size="xs"
                :src="comment.user ? comment.user.avatar_url: ''"
                :can-book="comment.user.has_booking_slots"/> -->
            <div
                :style="backgroundImageCircle"
                class="tileMK2__img__circle" />
            <div
                v-if="chips"
                class="tileMK2__chips__label">
                <m-chips v-if="type != 'Recording'">{{ displayTypes[type] }}</m-chips>
                <m-chips class="private" v-if="private">{{ $t('frontend.app.uikit.m_tile.private') }}</m-chips>
            </div>
            <div
                v-if="chips && price > 0"
                class="tileMK2__chips__dollar">
                <m-chips :buy="price" />
            </div>
        </div>
        <div class="tileMK2__body">
            <div v-if="type">
                <span class="tileMK2__light_color">{{ displayTypes[type] }}</span>
            </div>
            <div class="text__ellipsis text__ellipsis__2row">
                <span class="tileMK2__light_color">{{ displayActions[action] }}</span> <a
                    :href="shortUrl"
                    class="text__ellipsis__2row">{{ name }}</a>
            </div>
            <div>
                <span class="tileMK2__light_color">{{ time }}</span>
                <span
                    v-if="following"
                    class="tileMK2__followig_text"> {{ $t('frontend.app.uikit.m_tile.private') }}</span>
                <!-- <span v-if="purchased" class="tileMK2__purchased_text"> {{ $t('frontend.app.uikit.m_tile.purchased') }}</span> -->
            </div>
        </div>
    </div>
</template>

<script>
export default {
    // TODO: andrey, ilya move payload data to object
    name: "MTile",
    props: {
        action: String,
        name: String,
        time: String,
        type: String,
        following: Boolean,
        purchased: Boolean,
        posterUrl: {
            type: String,
            default: null
        },
        shortUrl: String,
        logoUrl: {
            type: String,
            default: null
        },
        price: {
            type: Number,
            default: 0
        },
        chips: {
            type: Boolean,
            default: false
        },
        kind: {
            type: String,
            default: null
        },
        listMode: {
            type: Boolean,
            default: false
        },
        private: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            displayTypes: {
                'Session': this.$t('frontend.app.uikit.m_tile.live'),
                'Video': this.$t('frontend.app.uikit.m_tile.replay'),
                'Recording': this.$t('frontend.app.uikit.m_tile.upload'),
                'Channel': this.$t('frontend.app.uikit.m_tile.channel'),
                'User': this.$t('frontend.app.uikit.m_tile.user'),
                'Organization': this.$t('frontend.app.uikit.m_tile.organization')
            },
            displayActions: {
                'view': this.$t('frontend.app.uikit.m_tile.viewed')
            }
        }
    },
    computed: {
        className() {
            let cl = "tileMK2"
            if (this.listMode) {
                cl += " tileMK2__listMode"
            }
            if (this.kind) {
                cl += " tileMK2__" + this.kind
            }
            return cl
        },
        classNameImg() {
            let cl = "tileMK2__img"
            if (this.logo_url) {
                cl += " tileMK2__img__border"
            }
            if (this.logo_url) {
                cl += " tileMK2__img__channel"
            }
            return cl
        },
        backgroundImage() {
            if (this.logo_url && this.type != "Channel") {
                return {backgroundImage: 'none'}
            } else {
                return {backgroundImage: `url(${this.posterUrl})`}
            }
        },
        backgroundImageCircle() {
            if (this.logo_url && this.type != "Channel") {
                return {backgroundImage: `url(${this.logo_url})`}
            } else if (this.logoUrl && this.type != "Channel") {
                return {backgroundImage: `url(${this.logoUrl})`}
            } else {
                return {backgroundImage: 'none'}
            }
        }
    }
}
</script>
