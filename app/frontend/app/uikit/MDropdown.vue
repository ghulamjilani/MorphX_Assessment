<template>
    <div class="MK2options">
        <m-icon
            v-if="!custom"
            class="MK2options__icon"
            size="1.8rem"
            @click="toggleOptions">
            GlobalIcon-dots-3
        </m-icon>
        <div
            v-if="custom"
            class="MK2options__icon"
            @click="toggleOptions">
            <slot
                name="custom"
                :open="open" />
        </div>

        <div
            v-show="open"
            class="MK2options__options__cover"
            @click="toggleOptions" />
        <div
            v-show="open"
            class="MK2options__options"
            @click="selfClick">
            <slot />
        </div>
    </div>
</template>

<script>
export default {
    props: {
        closeBySelfClick: {
            type: Boolean,
            default: false
        },
        custom: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            open: false
        }
    },
    created() {
        this.$eventHub.$on("m-dropdown:closeAll", this.close)
    },
    methods: {
        toggleOptions() {
            this.open = !this.open
        },
        close(){
            this.open = false
        },
        selfClick() {
            if (this.closeBySelfClick){
                this.close()
            }
        }
    }
}
</script>