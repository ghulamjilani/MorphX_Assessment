<template>
    <validation-provider
        v-slot="v"
        rules="required">
        <div class="mTextArea__wrapper">
            <textarea
                ref="textArea"
                v-model="model"
                :class="{'mTextArea__error' : v.errors[0]}"
                :maxlength="maxlength"
                :placeholder="placeholder"
                class="mTextArea"
                @input="onInput" />
            <div class="mTextArea__bottom">
                <div
                    v-if="smile"
                    class="mTextArea__bottom__smile">
                    <m-icon
                        size="1.6rem"
                        @click="() => { $emit('smileClicked') }">
                        GlobalIcon-smile
                    </m-icon>
                </div>
                <div
                    v-if="v.errors[0]"
                    class="mTextArea__bottom__errors">
                    {{ v.errors[0] }}
                </div>
                <div
                    v-if="model && maxCounter > 0"
                    class="mTextArea__bottom__counter">
                    {{ model.length }}/{{ maxCounter }}
                </div>
            </div>
        </div>
    </validation-provider>
</template>

<script>
export default {
    props: {
        placeholder: {
            type: String,
            default: ""
        },
        maxCounter: {
            type: Number,
            default: -1
        },
        smile: {
            type: Boolean,
            default: false
        },
        errors: {
            type: Boolean,
            default: true
        },
        maxlength: {}
    },
    data() {
        return {
            model: this.value
        }
    },
    mounted() {
        this.$el.addEventListener('input', this.resizeTextarea)
    },
    beforeDestroy() {
        this.$el.removeEventListener('input', this.resizeTextarea)
    },
    methods: {
        resizeTextarea(event) {
            event.target.style.height = 'auto'
            event.target.style.height = (event.target.scrollHeight) + 'px'
        },
        onInput() {
            this.$emit('input', this.model)
        }
    }
}
</script>

