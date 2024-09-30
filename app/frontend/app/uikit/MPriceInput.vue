<template>
    <validation-provider
        ref="provider"
        v-slot="v"
        :debounce="validationDebounce"
        :rules="rules"
        class="wrapper"
        tag="div">
        <div
            class="input__field position__relative"
            :class="{'freeActive': freeButton && !isInputActive && value == '0.00'}">
            <m-btn
                v-if="freeButton"
                class="input__field__free"
                :type="value == '0.00' ? 'main' : 'bordered'"
                size="s"
                @click="free">
                free
            </m-btn>
            <input
                :id="fieldId"
                ref="input"
                :style="customStyle"
                v-bind="$props"
                v-model="displayValue"
                :class="{
                    'input__field__errors': errored || v.errors[0],
                    'input__field__without-label': pure,
                    'input__field__without-border': borderless,
                    'input__field__number': type === 'number'
                }"
                :placeholder="pure ? placeholder : ' '"
                @blur="isInputActive = false"
                @focus="isInputActive = true">

            <!-- <div
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
            </div> -->
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
    name: "MPriceInput",
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
        max: {
            type: Number
        },
        min: {
            type: Number
        },
		/**
		 * custom style
		 */
		customStyle: {
			type:String
		},
        freeButton: {
            type: Boolean,
            default: false
        },
    },
    data() {
        return {
            model: this.value,
            isInputActive: false
        }
    },
    computed: {
        displayValue: {
            get: function() {
                if (this.isInputActive) {
                    return this.value.toString()
                } else {
                    let val = this.value
                    if(typeof val !== 'number') val = parseFloat(this.value)
                    if(isNaN(val)) {
                        val = 0
                        this.free()
                    }
                    return "$ " + val.toFixed(2).replace(/(\d)(?=(\d{3})+(?:\.\d+)?$)/g, "$1,")
                }
            },
            set: function(modifiedValue) {
                let newStr = modifiedValue.replace(/[^\d.]/g, "")
                let newValue = parseFloat(newStr)
                if(newStr.split(".")[1]?.length >= 2) {
                    newValue = parseFloat(newStr).toFixed(2)
                }
                if(newStr.length > 0 && newStr.lastIndexOf(".") == newStr.length - 1) {
                    newValue = newStr
                }
                if (isNaN(newValue)) {
                    newValue = 0
                }
                if(this.max && newValue > this.max) {
                    newValue = this.max
                }
                this.$emit('input', newValue)
            }
        }
    },
    watch: {
        // value(val) {
        //     if (val !== this.model) {
        //         this.model = val
        //     }
        // },
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
        },
        isInputActive(val) {
            if (!val) {
                this.$emit('blur')
                if(this.min > 0 && parseFloat(this.value) < this.min && (parseFloat(this.value) !== 0 || !this.freeButton )) {
                    this.$emit('input', parseFloat(this.min).toFixed(2))
                }
                else {
                    this.$emit('input', parseFloat(this.value).toFixed(2))
                }
            } else {
                this.$emit('focus')
            }
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
        free() {
            this.$emit('input', 0)
        },
        // onInput() {
        //     if (this.type === "number") {
        //         this.model = Number(this.model)
        //         if (this.min && this.model < this.min) {
        //             this.model = this.min
        //         }
        //         if (this.max && this.model > this.max) {
        //             this.model = this.max
        //         }
        //     }
        //     this.$emit('input', this.model)
        // },
        // clearInput() {
        //     if (this.password) {
        //         this.model = ''
        //     }
        // }
    }
}
</script>

<style lang="scss">
.input__field__free {
    margin-right: 1rem;
}

.freeActive {
    input {
        opacity: 0.5;
    }
}
</style>