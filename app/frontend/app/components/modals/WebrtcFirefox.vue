<template>
    <m-modal
        v-show="active"
        ref="webrtcFirefox"
        :close="false"
        class="webrtcFirefox">
        <div class="notSupported__text">
            Your browser or device is not supported, please
            use <a href="https://www.google.com/chrome"> Chrome for stable version </a>
        </div>
    </m-modal>
</template>

<script>
export default {
    props: {
        active: Boolean
    },
    data() {
        return {}
    },
    watch: {
        active(val) {
            if (val) {
                this.$refs.webrtcFirefox.openModal()
            }
        }
    },
    methods: {
        close() {
            this.$refs.webrtcFirefox.closeModal()
        }
    }
}
</script>