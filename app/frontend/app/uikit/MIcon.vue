<template>
    <component
        :is="tag"
        ref="slotName"
        :class="getIconName"
        :style="size === '0' ? '' : 'font-size:' + getSize"
        @click="() => { $emit('click') }"
        @mouseleave="() => { $emit('mouseleave') }"
        @mouseover="() => { $emit('mouseover') }">
        <slot />
    </component>
</template>

<script>
/**
 * Icon
 * @example ./docs/micon.md
 */
export default {
    props: {
        /**
         * Tag
         * @default i
         */
        tag: {
            type: String,
            default: "i"
        },
        /**
         * for dynamicly change
         */
        name: {
            type: String,
            default: ""
        },
        /**
         * Size
         */
        size: {
            type: String,
            default: "normal"
        }
    },
    data() {
        return {
            iconName: "",
            sizes: {
                "l": "2rem",
                "normal": "1.4rem"
            }
        }
    },
    computed: {
        getIconName() {
            return this.name === "" ? this.iconName : this.name
        },
        getSize() {
            if (this.sizes[this.size]) return this.sizes[this.size]
            else return this.size
        }
    },
    mounted() {
        if (this.name === "") this.iconName = this.$refs.slotName.textContent
        this.$refs.slotName.textContent = ""
    }
}
</script>

