<template>
    <component
        :is="tag"
        :class="className"
        :disabled="disabled"
        :type="tagType"
        :style="customStyles"
        @click="click">
        <div
            v-if="loading"
            class="spinnerSlider">
            <div class="bounceS1" />
            <div class="bounceS2" />
            <div class="bounceS3" />
        </div>
        <div class="btn__slot">
            {{ text }}
            <slot />
        </div>
    </component>
</template>

<script>
/**
 * @example ./docs/mbtn.md
 * @displayName Button
 */
export default {
    name: "MBtn",
    props: {
        /**
         * The type of the button
         * @values main, secondary, tetriary, bordered, save, cancel, subscribe
         */
        type: {
            type: String,
            default: "main"
        },
        /**
         * The size of the button
         * @values l, m, normal, s, xs
         * @default normal
         */
        size: {
            type: String,
            default: "normal"
        },
        /**
         * The square or rounded button
         * @values true, false
         */
        square: {
            type: Boolean,
            default: false
        },
        /**
         * Reset to default
         * @values true, false
         */
        reset: {
            type: Boolean,
            default: false
        },
        /**
         * Type of main tag
         * @values button, div, a, etc..
         */
        tag: {
            type: String,
            default: "button"
        },
        /**
         * Is full width
         * @values true, false
         * @default false
         */
        full: {
            default: false
        },
        /**
         * Type
         * @default ""
         */
        tagType: {
            type: String,
            default: null
        },
        /**
         * Is disabled
         */
        disabled: {
            type: Boolean,
            default: false
        },
        /**
         * Is loading
         */
        loading: {
            type: Boolean,
            default: false
        },
        /**
         * custom border Color
         */
        borderColor: {
            type: String
        },
        /**
         * custom text Color
         */
        textColor: {
            type: String
        },
        /**
         * text from props
         */
         text: {
            type: String
         }
    },
    computed: {
        className() {
            let cl = "btn btn__" + this.type
            cl += " btn__" + this.size
            if (this.square) {
                cl += " btn__square"
            }
            if (this.reset) {
                cl += " btn__reset"
            }
            if (this.full) {
                cl += " btn__full"
            }
            if (this.loading) {
                cl += " btn__loading"
            }
            return cl
        },
        customStyles() {
            let style = ""

            if(this.borderColor) style += `border-color: ${this.borderColor};`
            if(this.textColor) style += `color: ${this.textColor};`

            return style
        }
    },
    methods: {
        click(event) {
            if (!this.loading) {
                this.$emit("click", event)
            }
        }
    }
}
</script>

