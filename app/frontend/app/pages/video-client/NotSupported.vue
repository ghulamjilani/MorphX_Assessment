<template>
    <m-modal
        ref="notSupported"
        class="notSupported">
        <div
            v-if="$device.os == 'ios'"
            class="notSupported__text">
            Your browser or device is not supported, please update it and use Safari
        </div>
        <div
            v-else
            class="notSupported__text">
            Your browser or device is not supported, please update it
            and use <a href="https://www.google.com/chrome"> Chrome </a>
        </div>
        <div class="notSupported__image">
            <no-post />
        </div>
    </m-modal>
</template>

<script>
import NoPost from '../../components/NoPost.vue'

export default {
    components: {NoPost},
    mounted() {
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })
    },
    methods: {
        open() {
            this.$refs.notSupported.openModal()
        },
        close() {
            this.$refs.notSupported.closeModal()
        }
    }
}
</script>
