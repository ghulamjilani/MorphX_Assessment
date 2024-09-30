<template>
    <validation-provider
        ref="provider"
        v-slot="v"
        :debounce="validationDebounce"
        :rules="rules"
        class="wrapper"
        tag="div">
        <div class="input__field position__relative">
            <input
                v-if="!textarea"
                :id="fieldId"
                ref="input"
                v-model="model"
                v-bind="$props"
                :class="{
                    'input__field__errors': errored || v.errors[0],
                    'input__field__without-label': pure,
                    'input__field__without-border': borderless,
                    'input__field__number': type === 'number',
                    'input__field__disabled': disabled
                }"
                :placeholder="pure ? placeholder : ' '"
                :disabled="disabled"
                :maxlength="maxlength"
                @blur="() => { $emit('blur') }"
                @click="() => { $emit('click') }"
                @focus="() => { $emit('focus') }"

                @input="onInput"
                @keypress.enter="() => { $emit('enter') }">

            <textarea
                v-else
                :id="fieldId"
                ref="input"
                v-model="model"
                v-bind="$props"
                :class="{
                    'input__field__errors': errored || v.errors[0],
                    'input__field__without-label': pure,
                    'input__field__without-border': borderless
                }"
                :placeholder="pure ? placeholder : ' '"
                :disabled="disabled"
                @blur="() => { $emit('blur') }"

                @focus="() => { $emit('focus') }"
                @input="onInput" />
            <div
                v-if="type === 'number'"
                class="input__field__angle">
                <m-icon
                    class="input__field__angle__top"
                    size="0"
                    @click="upNumber()">
                    GlobalIcon-angle-down
                </m-icon>
                <m-icon
                    size="0"
                    @click="downNumber()">
                    GlobalIcon-angle-down
                </m-icon>
            </div>
            <label
                v-if="!pure"
                :class="{'label__errors': v.errors[0]}"
                :for="fieldId"
                class="label">
                {{ label }}
            </label>
            <span class="input__field__icon">
                <slot name="icon" />
            </span>
            <div class="bottom__full">
                <slot name="passStrength" />
                <slot name="bottom" />
            </div>
            <div
                v-if="errors"
                :class="{'bottom__right': (maxCounter !== -1) && (description === '') && (!v.errors[0] || v.errors[0] === '')}"
                class="input__field__bottom">
                <div
                    v-if="description !== '' && !v.errors[0]"
                    class="input__field__bottom__description">
                    {{ description }}
                </div>
                <div
                    v-if="v.errors[0]"
                    class="input__field__bottom__errors">
                    {{ v.errors[0] }}
                </div>
                <div
                    v-if="smile"
                    class="input__field__bottom__smile">
                    <m-icon
                        size="1.6rem"
                        @click="() => { $emit('smileClicked') }">
                        GlobalIcon-smile
                    </m-icon>
                </div>
                <div
                    v-if="maxCounter > 0"
                    class="input__field__bottom__counter">
                    {{ model.length }}/{{ maxCounter }}
                </div>
            </div>
        </div>
    </validation-provider>
</template>

<script>

/**
 * Inputs
 * @example ./docs/minput.md
 * @displayName Input
 */
export default {
    name: "MInput",
    props: {
        /**
         * id for field
         */
        fieldId: {
            type: String,
            default: "input_id"
        },
        /**
         * @model
         */
        value: {
            type: [String, Number],
            default: ""
        },
        /**
         * Label text
         */
        label: {
            type: String,
            default: ""
        },
        /**
         * Pure field without label
         * @values: true, false
         * @default false
         */
        pure: {
            type: Boolean,
            default: false
        },
        /**
         * placeholder text if pure input
         */
        placeholder: {
            type: String,
            default: ""
        },
        /**
         * Borderless field without border
         * @values: true, false
         * @default false
         */
        borderless: {
            type: Boolean,
            default: false
        },
        /**
         * add errors block
         * @values: true, false
         * @default true
         */
        errors: {
            type: Boolean,
            default: true
        },
        /**
         * @values text, email, pasword, and others standart types
         * @default text
         */
        type: {
            type: String,
            default: "text"
        },
        /**
         * Max value for counter
         */
        maxCounter: {
            type: Number,
            default: -1
        },
        /**
         * Description text
         */
        description: {
            type: String,
            default: ""
        },
        /**
         * validation rules
         */
        rules: {
            type: [Object, String],
            default: ""
        },
        validationDebounce: {
            type: Number,
            default: 0
        },
        /**
         * Focus event
         */
        focus: {
            type: Function
        },
        /**
         * Focus event
         */
        blur: {
            type: Function
        },
        /**
         * Forse error
         */
        errored: {
            type: Boolean,
            default: false
        },
        /**
         * Smile
         */
        smile: {
            type: Boolean,
            default: false
        },
        /**
         * Textarea
         */
        textarea: {
            type: Boolean,
            default: false
        },
        rows: {
            type: Number,
            default: 3
        },
        password: {
            type: Boolean,
            default: false
        },
        max: {
            type: Number,
        },
        min: {
            type: Number,
        },
        disabled: {
            type: Boolean,
            default: false
        },
        maxlength: {
            type: Number,
            default: null
        }
    },
    data() {
        return {
            model: this.value
        }
    },
    watch: {
        value(val) {
            if (val !== this.model) {
                this.model = val
            }
        },
        errored: {
            handler(val) {
                if (val) {
                    this.clearInput()
                }
            },
            deep: true,
            immediate: true
        },
        errors: {
            handler(val) {
                if (val) {
                    this.clearInput()
                }
            },
            deep: true,
            immediate: true
        }
    },
    methods: {
        upNumber() {
            this.model = Number(this.model)
            if (this.model < this.max) {
                this.model += 1
            }
            this.$emit('input', this.model)
        },
        downNumber() {
            this.model = Number(this.model)
            if (this.model > this.min) {
                this.model -= 1
            }
            this.$emit('input', this.model)
        },
        onInput() {
            if (this.model && this.model !== '-' && this.type === "number") {
                this.model = Number(this.model)
                if (this.min && this.model < this.min) {
                    this.model = this.min
                }
                if (this.max && this.model > this.max) {
                    this.model = this.max
                }
            }
            this.$emit('input', this.model)
        },
        clearInput() {
            if (this.password) {
                this.model = ''
            }
        }
    }
}
</script>
