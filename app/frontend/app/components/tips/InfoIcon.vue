<template>
    <transition name="fade">
        <div
            v-if="!hide && (checkLocaleText || checkLocaleLink)"
            class="tips__info"
            @mouseover="showTips()"
            @click="showTips()">
            <div class="tips__header">
                <m-icon
                    v-tooltip="'Click to see more info'"
                    class="tips__header__icon"
                    size="0">
                    GlobalIcon-info-square
                </m-icon>
            </div>
        </div>
    </transition>
</template>

<script>
export default {
    props: {
        type: String
    },
    data() {
        return {
            hide: false,
            objects: [
                {
                    name: 'uploads',
                    text: this.$t('components.tips.uploads.text'),
                    link: this.$t('components.tips.uploads.link')
                },
                {
                    name: 'replays',
                    text: this.$t('components.tips.replays.text'),
                    link: this.$t('components.tips.replays.link')
                },
                {
                    name: 'subscriptions',
                    text: this.$t('components.tips.subscriptions.text'),
                    link: this.$t('components.tips.subscriptions.link')
                },
                {
                    name: 'ip-cam',
                    text: this.$t('components.tips.ip-cam.text'),
                    link: this.$t('components.tips.ip-cam.link')
                },
                {
                    name: 'main-info',
                    text: this.$t('components.tips.main-info.text'),
                    link: this.$t('components.tips.main-info.link')
                },
                {
                    name: 'obs',
                    text: this.$t('components.tips.obs.text'),
                    link: this.$t('components.tips.obs.link')
                },
                {
                    name: 'recurrence',
                    text: this.$t('components.tips.recurrence.text'),
                    link: this.$t('components.tips.recurrence.link')
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
        }
    },
    mounted() {
        this.hide = localStorage.getItem(this.type)
        this.$eventHub.$on('tips-info', (type) => {
            this.hide = localStorage.getItem(this.type)
        })
    },
    methods: {
        showTips() {
            localStorage.setItem(this.type, true)
            this.hide = true
            this.$eventHub.$emit('tips-show', this.type)
        }
    }
}
</script>