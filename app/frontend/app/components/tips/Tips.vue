<template>
    <transition name="fade">
        <div
            v-if="enabledInConfig && open && checkLocaleText && presenter"
            :class="(sessionPage ? 'tips__sessionPage' : '') + ' tips__type__' + type"
            class="tips">
            <span
                class="GlobalIcon-clear MK2-modal__close"
                @click="closeTips()" />
            <div
                :class="{'tips__sessionPage__image' : sessionPage}"
                class="tips__image">
                <component
                    :is="type"
                    class="tips__image__svg" />
            </div>
            <div class="tips__text">
                <div
                    :class="{'tips__sessionPage__header' : sessionPage}"
                    class="tips__header">
                    <m-icon
                        class="tips__header__icon"
                        size="0">
                        GlobalIcon-info-square
                    </m-icon>
                    Tips
                </div>
                <div class="tips__body">
                    <p v-html="object.text" />
                </div>
                <div
                    v-if="checkLocaleLink"
                    :class="{'tips__sessionPage__link__wrapper' : sessionPage}">
                    <a
                        :class="{'tips__sessionPage__link' : sessionPage}"
                        :href="object.link"
                        class="tips__link"
                        target="_blank">{{ object.link }}</a>
                </div>
            </div>
        </div>
    </transition>
</template>

<script>
import Uploads from './images/Uploads'
import IpCam from './images/IpCam'
import MainInfo from './images/MainInfo'
import Obs from './images/Obs'
import Recurrence from './images/Recurrence'
import Replays from './images/Replays'
import Subscriptions from './images/Subscriptions'

export default {
    components: {
        Uploads,
        IpCam,
        MainInfo,
        Obs,
        Recurrence,
        Replays,
        Subscriptions
    },
    props: {
        type: String,
        sessionPage: {
            type: Boolean,
            default: false
        },
        dashboard: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            open: false,
            objects: [
                {
                    name: 'uploads',
                    text: this.$t('components.tips.uploads.text'),
                    link: this.$t('components.tips.uploads.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'replays',
                    text: this.$t('components.tips.replays.text'),
                    link: this.$t('components.tips.replays.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'subscriptions',
                    text: this.$t('components.tips.subscriptions.text'),
                    link: this.$t('components.tips.subscriptions.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'ip-cam',
                    text: this.$t('components.tips.ip-cam.text'),
                    link: this.$t('components.tips.ip-cam.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'main-info',
                    text: this.$t('components.tips.main-info.text'),
                    link: this.$t('components.tips.main-info.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'obs',
                    text: this.$t('components.tips.obs.text'),
                    link: this.$t('components.tips.obs.link', {host: this.$railsConfig?.global?.host})
                },
                {
                    name: 'recurrence',
                    text: this.$t('components.tips.recurrence.text'),
                    link: this.$t('components.tips.recurrence.link', {host: this.$railsConfig?.global?.host})
                }
            ]
        }
    },
    computed: {
        object() {
            return this.objects.find(ob => ob.name == this.type)
        },
        checkLocaleText() {
            return this.object.text !== 'components.tips.' + this.object.name + '.text'
        },
        checkLocaleLink() {
            return this.object.link !== 'components.tips.' + this.object.name + '.link'
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        presenter() {
            return this.currentUser?.role == 'presenter'
        },
        enabledInConfig() {
            return this.$railsConfig.frontend?.tips?.enabled
        }
    },
    mounted() {
        this.$eventHub.$on('tips-show', (type) => {
            this.open = localStorage.getItem(this.type)
        })
        this.open = localStorage.getItem(this.type)
        if (!this.sessionPage && this.checkLocaleText) {
            this.mathHeigth()
            window.addEventListener('resize', () => {
                this.mathHeigth()
            })
        }
    },
    methods: {
        closeTips() {
            localStorage.removeItem(this.type)
            this.open = localStorage.getItem(this.type)
            this.$eventHub.$emit('tips-info', (this.type))
        },
        mathHeigth() {
            let tips = document.querySelector('.tips')
            let image = document.querySelector('.tips__image__svg')
            if (tips && this.dashboard && window.innerWidth < 1050) return tips.style.height = 'auto'
            if (tips && image) tips.style.height = image.clientHeight + 'px'
        }
    }
}
</script>