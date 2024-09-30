<template>
    <validation-provider
        ref="provider"
        v-slot="v"
        :rules="rules"
        class="wrapper"
        tag="div">
        <div
            v-click-outside="closeMenu"
            :class="{'dropdownMK2__with-label': (!pure && label), 'dropdownMK2__disabled': disabled}"
            class="dropdownMK2">
            <span
                v-if="label"
                class="dropdownMK2__title">{{ label }}</span>
            <div
                :class="{
                    'dropdownMK2__placeholder': !selectedOption,
                    'dropdownMK2__pure': pure,
                    'dropdownMK2__disabled': disabled
                }"
                class="dropdownMK2__toggle"
                @click="toggleMenu()">
                <div
                    v-if="withImage && image"
                    :style="{backgroundImage: `url(${image})`}"
                    class="dropdownMK2__image" />
                <span class="dropdownMK2__toggle__text fs__16">{{ text }}</span>
                <span
                    v-if="showMenu"
                    class="GlobalIcon-angle-down selectArrow up" />
                <span
                    v-else
                    class="GlobalIcon-angle-down selectArrow down" />
            </div>

            <div
                v-if="!withoutError && !pure"
                class="input__field__bottom">
                <div class="input__field__bottom__errors">
                    {{ v.errors[0] }}
                </div>
            </div>

            <div
                v-if="showMenu"
                :class="{
                    'dropdownMK2__menu__inherit': inherit
                }"
                class="dropdownMK2__menu">
                <div
                    v-if="type !== 'default'"
                    class="dropdownMK2__custom">
                    <slot />
                </div>

                <div class="dropdownMK2__menu__scroll">

                    <template v-for="(option, idx) in mountedOptions">
                        <div
                            v-if="!option.hidden"
                            :key="idx"
                            class="dropdownMK2__item"
                            @click="updateOption(option)">
                            <div
                                v-if="mutiselect"
                                class="dropdownMK2__checkbox">
                                <m-checkbox
                                    v-model="option.selected"
                                    :disabled="option.value === 'all' && option.selected"
                                    :disabled-with-normal-style="disabledWithNormalStyle"
                                    @input="updateOptionCheckbox($event, option)" />
                            </div>
                            <div
                                v-if="withImage"
                                :style="{backgroundImage: `url(${option.image})`}"
                                class="dropdownMK2__image" />
                            <!-- <span class="dropdownMK2__menu__checkbox active"></span> -->
                            <a href="javascript:void(0)">
                                {{ option.name }}
                            </a>
                        </div>
                    </template>

                    <div
                        v-if="isUpdating"
                        class="dropdownMK2__sending">
                        <div class="spinnerSlider">
                            <div class="bounceS1" />
                            <div class="bounceS2" />
                            <div class="bounceS3" />
                        </div>
                    </div>

                </div>
            </div>
        </div>
        <template v-if="withImage">
            <div
                v-for="listedOption in listedOptions"
                :key="listedOption.value"
                v-tooltip="listedOption.name"
                :style="{backgroundImage: `url(${listedOption.image})`}"
                class="dropdownMK2__multyImage" />
        </template>
    </validation-provider>
</template>

<script>
import ClickOutside from "vue-click-outside"
import eventHub from "../helpers/eventHub.js"

/**
 * @displayName Select
 * @example ./docs/mselect.md
 */
export default {
    directives: {
        ClickOutside
    },
    props: {
        type: {
            type: String,
            default: "default"
        },
        withoutError: {
            type: Boolean,
            default: false
        },
        /**
         * @model
         */
        value: {},
        /**
         * Dropdown options
         */
        options: {
            type: [Array, Object]
        },
        withImage: {
            type: Boolean,
            default: false
        },
        placeholder: String,
        closeOnOutsideClick: {
            type: Boolean,
            default: true
        },
        label: null,
        /**
         * TODO: add docs
         */
        pure: {
            type: Boolean,
            default: false
        },
        /**
         * TODO: add docs
         */
        inherit: {
            type: Boolean,
            default: false
        },
        rules: {
            type: String,
            default: ""
        },
        required: {
            type: Boolean,
            default: false
        },
        /**
         * UI id that is passed in events(open, etc...)
         */
        uid: {
            type: String,
            default: ""
        },
        mutiselect: {
            type: Boolean,
            default: false
        },
        disabled: {
            type: Boolean,
            default: false
        },
        disabledWithNormalStyle: {
            type: Boolean,
            default: false
        },
        dataGroup: {
            type: Number,
        },
        updateble: {
            default: false,
            value: {
                type: Boolean,
                default: false
            },
            isUpdating: {
                type: Boolean,
                default: false
            }
        }
    },
    data() {
        return {
            selectedOption: null,
            mountedOptions: [],
            showMenu: false,
            placeholderText: "Please select item"
        }
    },
    computed: {
        text() {
            if (this.mutiselect) {
                return this.selectedOptions.filter(o => o.selectText)?.map(o => o.selectText).join(", ") || this.placeholderText
            } else {
                if (this.selectedOption) {
                    return this.selectedOption.nameSelected ? this.selectedOption.nameSelected : this.selectedOption.name
                } else {
                    return this.placeholderText
                }
            }
        },
        image() {
            if (this.selectedOption) {
                return this.selectedOption.image ? this.selectedOption.image : ''
            } else {
                return null
            }
        },
        selectedOptions() {
            let selectedAll = this.mountedOptions.filter(o => o.value == 'all' && o.selected)
            return selectedAll.length ? selectedAll : this.mountedOptions.filter(o => o.selected && o.value != 'all')
        },
        listedOptions() {
            return this.selectedOptions.filter(o => !o.unlisted)
        },
        isUpdateble() {
            return this.updateble?.value
        },
        isUpdating() {
            return this.isUpdateble && this.updateble?.isUpdating
        }
    },
    watch: {
        value: {
            deep: true,
            handler(val) {
                if (this.mutiselect) {
                    if (this.mountedOptions.length) {
                        val.forEach(option => {
                            let mountedOption = this.mountedOptions.find(mo => {
                                return mo.value == option.value
                            })
                            if (mountedOption) {
                                mountedOption.selected = option.selected
                                if(option.selected == undefined) {
                                    mountedOption.selected = true
                                }
                            }
                        })
                        this.mountedOptions.forEach(mo => {
                            if (!val.find(v => {
                                return mo.value == v.value
                            }))
                            mo.selected = false
                        })
                        this.mountedOptions = this.mountedOptions.map(mo => mo)
                    }
                } else {
                    if (!this.selectedOption || val !== this.selectedOption.value) {
                        this.selectedOption = this.mountedOptions.find(e => e.value ? e.value === val : e === val)
                    }
                    if (val === null || val === -1) {
                        this.selectedOption = null
                    }
                }
            }
        },
        options: {
            deep: true,
            immediate: true,
            handler(val) {
                if(!val) return
                if (val && !val[0]) return // empty
                else if (val[0].value === undefined && val[0].name === undefined) {
                    this.mountedOptions = val.map(e => {
                        return {
                            name: e,
                            value: e
                        }
                    })
                } else {
                    this.mountedOptions = JSON.parse(JSON.stringify(val))
                }

                if (this.mutiselect && this.mountedOptions.length) {
                    this.value.forEach(option => {
                        let mountedOption = this.mountedOptions.find(mountedOption => mountedOption.value === option.value)
                        if (mountedOption) {
                            mountedOption.selected = option.selected
                        }
                    })
                    this.updateOptionIndex()
                }

                this.selectedOption = this.mountedOptions
                    ? this.mountedOptions.find(e => e.value === this.value)
                    : null
            }
        },
        showMenu(val) {
            let event
            if (val) {
                event = 'open-m-select-menu'
            } else {
                event = 'close-m-select-menu'
                if (!this.selectedOption) {
                    this.$refs.provider.validate()
                }
            }
            eventHub.$emit(event)
        }
    },
    mounted() {
        if (this.placeholder) {
            this.placeholderText = this.placeholder
        }
        if (this.closeOnOutsideClick) {
            document.addEventListener("click", this.clickHandler)
        }
        this.updateOptionIndex()
        this.$eventHub.$on('m-selec-update', (data) => {
            if (data == this.dataGroup) {
                this.selectAll()
            }
        })

        this.$nextTick(() => {
            let selectAll = this.mountedOptions.find(mo => mo.value === "all")
            if(selectAll && !this.mountedOptions.find(mo => mo.selected)) {
                selectAll.selected = true
            }
        })
    },
    beforeDestroy() {
        document.removeEventListener("click", this.clickHandler)
    },
    methods: {
        updateOptionIndex() {
            if (this.mutiselect) {
                this.updateSelectAllOpton()
            }
        },
        updateOption(option) {
            if (this.mutiselect) {
                if (option.excluded) {
                    this.isUpdateble ? this.unSelectAll() : this.selectExcluded()
                } else {
                    if(option.value === "all" && option.selected) return

                    option.selected = !option.selected
                    let selectAll = this.mountedOptions.find(mo => mo.value === "all")
                    if(selectAll && selectAll.selected) {
                        if(option.value !== "all" && option.selected) {
                            selectAll.selected = false
                        }
                    }
                    if(!this.mountedOptions.find(mo => mo.selected)) {
                        selectAll.selected = true
                    }
                    this.unselectExcluded()
                    this.updateSelectAllOpton()
                }

                // this.$refs.provider.validate(true)
                this.$emit("input", this.selectedOptions)
                this.$emit("change", this.selectedOptions)
            } else {
                this.selectedOption = option
                this.showMenu = false
                this.$refs.provider.validate(true)
                this.$emit("input", this.selectedOption.value)
                this.$emit("change", this.selectedOption.value)
            }
        },
        updateOptionCheckbox(event, option) {
            this.updateOption(option)
        },
        toggleMenu() {
            if (!this.disabled) {
                this.showMenu = !this.showMenu
            }
        },
        closeMenu() {
            this.showMenu = false
        },
        clickHandler(event) {
            const {target} = event
            const {$el} = this
            if (!$el.contains(target)) {
                this.showMenu = false
            }
        },
        selectAll() {
            this.mountedOptions = this.mountedOptions.map((mo) => {
                if (mo.value == 'all') {
                    mo.selected = true
                }
                else {
                    mo.selected = false
                }
                return mo
            })
        },
        selectExcluded() {
            this.mountedOptions = this.mountedOptions.map((mo) => {
                if (mo.value == 'all' || mo.excluded) {
                    mo.selected = true
                }
                else {
                    mo.selected = false
                }
                return mo
            })
        },
        unSelectAll() {
            this.mountedOptions = this.mountedOptions.map((mo) => {
                mo.selected = false
                return mo
            })
        },
        unselectExcluded() {
            this.mountedOptions = this.mountedOptions.map((mo) => {
                if (mo.excluded) {
                    mo.selected = false
                }
                return mo
            })
        },
        updateSelectAllOpton() {
            if (this.selectedOptions.length == this.mountedOptions.length - 1) {
                this.selectExcluded()
            }
        }
    }
}
</script>
