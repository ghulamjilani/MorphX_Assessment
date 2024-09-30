<template>
    <div class="v-dropdown btn-group">
        <li
            class="v-dropdown-toggle"
            @click="toggleMenu()">
            <span v-if="selectedOption && selectedOption.value !== 'all'">
                {{ selectedOption.name }}
            </span>
            <span v-if="!selectedOption || selectedOption.value === 'all'">
                {{ placeholderText }}
            </span>
            <i class="GlobalIcon-angle-down selectArrow"
                :class="showMenu ? 'up' : 'down'" />
        </li>

        <ul
            v-if="showMenu && type === 'multi'"
            :class="type"
            class="v-dropdown-menu">
            <li
                v-if="withDatepicker"
                class="datepicker">
                <div class="picker-wrap">
                    <span class="headerNavigation">From</span>
                    <datepicker
                        v-model="dateFrom"
                        :disabled-dates="{ranges: rangeFrom}"
                        :highlighted="highlited"
                        @selected="handleDateChoose" />
                </div>
                <div class="picker-wrap">
                    <span class="headerNavigation">To</span>
                    <datepicker
                        v-model="dateTo"
                        :disabled-dates="{ ranges: rangeTo}"
                        :highlighted="highlited"
                        @selected="handleDateChoose" />
                </div>
            </li>
            <li v-if="withSearch">
                <input
                    v-model="searchQuery"
                    class="dropdownInput"
                    placeholder="Enter name..."
                    type="text"
                    @input="updateList()">
                <i
                    class="GlobalIcon-Search"
                    @click="updateListClick()" />
            </li>
            <li
                v-for="(option, idx) in options"
                :key="idx"
                :class="{'checked': isCurrentOption(option)}">
                <input
                    v-if="option.value !== 'noitems'"
                    :checked="isCurrentOption(option)"
                    class="mark-notification"
                    type="checkbox"
                    @click="pushOption(option)">
                <a
                    v-if="option.value !== 'noitems'"
                    href="javascript:void(0)"
                    @click="pushOption(option)">
                    {{ option.name }}
                </a>
                <div v-if="option.value === 'noitems'">
                    {{ option.name }}
                </div>
            </li>
        </ul>

        <ul
            v-if="showMenu && type !== 'multi'"
            class="v-dropdown-menu">
            <li
                v-if="withDatepicker"
                class="datepicker">
                <div class="picker-wrap">
                    <span>From</span>
                    <datepicker
                        v-model="dateFrom"
                        :disabled-dates="{ranges: rangeFrom}"
                        :highlighted="highlited"
                        @selected="handleDateChoose" />
                </div>
                <div class="picker-wrap">
                    <span>To</span>
                    <datepicker
                        v-model="dateTo"
                        :disabled-dates="{ ranges: rangeTo}"
                        :highlighted="highlited"
                        class="secondPicker"
                        @selected="handleDateChoose" />
                </div>
            </li>
            <li
                v-for="(option, idx) in options"
                :key="idx">
                <a
                    href="javascript:void(0)"
                    @click="updateOption(option)">
                    {{ option.name }}
                </a>
            </li>
        </ul>
    </div>
</template>

<script>
import eventHub from "@helpers/eventHub.js"
import Datepicker from 'vuejs-datepicker'
import utils from '@helpers/utils'

export default {
    components: {
        Datepicker
    },
    props: {
        value: {},
        options: {
            type: [Array, Object]
        },
        withSearch: {
            type: Boolean
        },
        searchBy: [String],
        withDatepicker: {
            type: Boolean
        },
        type: '',
        placeholder: [String],
        closeOnOutsideClick: {
            type: [Boolean],
            default: true
        }
    },
    data() {
        return {
            selectedOption: null,
            optionsArray: [],
            dateRange: null,
            showMenu: false,
            modelName: '',
            searchQuery: '',
            placeholderText: "Please select an item",
            dateFrom: new Date(new Date().getTime() - (60 * 60 * 24 * 7 * 1000)),
            dateTo: new Date(new Date().getTime() - (60 * 60 * 24 * 7 * 1000))
        }
    },

    computed: {
        isCurrentOption() {
            return option => this.optionsArray.includes(option)
        },
        rangeFrom() {
            return [
                {
                    from: this.dateTo,
                    to: this.dateTo.getTime() + (600 * 600 * 240 * 70 * 10000)
                }
            ]
        },
        highlited() {
            return {
                from: this.dateFrom,
                to: this.dateTo
            }
        },
        rangeTo() {
            return [
                {
                    from: new Date().setFullYear(new Date().getFullYear() - 50),
                    to: this.dateFrom
                }
            ]
        }
    },

    watch: {
        value(val) {
            this.selectedOption = this.options.find(e => e.value === val)
            if (this.type === 'multi') {
                this.updateSelectedOptions()
                if (this.value.length === 0) {
                    this.optionsArray = []
                }
            }
            if (this.withDatepicker) {
                const dateQuery = this.value.includes('custom-date')
                if (dateQuery) {
                    const dateObj = JSON.parse(this.value)
                    const dateFrom = dateObj.value.split(' - ')[0]
                    const dateTo = dateObj.value.split(' - ')[1]
                    this.dateFrom = new Date(moment(dateFrom).format('llll'))
                    this.dateTo = new Date(moment(dateTo).format('llll'))
                }
            }
        }
    },

    mounted() {
        this.selectedOption = this.options ? this.options.find(e => e.value === this.value) : null
        this.updateSelectedOptions()
        if (this.type === 'multi') {
            this.modelName = this.options[0].type
        }
        if (this.type === 'multi' && this.selectedOption) {
            this.optionsArray.push(this.selectedOption)
        }
        if (this.placeholder) {
            this.placeholderText = this.placeholder
        }

        if (this.closeOnOutsideClick) {
            document.addEventListener("click", this.clickHandler)
        }
    },

    beforeDestroy() {
        document.removeEventListener("click", this.clickHandler)
    },

    methods: {
        updateOption(option) {
            this.selectedOption = option
            this.showMenu = false
            this.$emit("input", this.selectedOption.value)
            this.$emit("change", this.selectedOption.value)
        },

        updateSelectedOptions() {
            if (typeof this.value === 'object') {
                this.$nextTick(() => {
                    let filteredArray = []
                    this.value.forEach((option) => {
                        const item = this.options.find(e => e.id === Number(option))
                        filteredArray.push(item)
                        this.optionsArray = filteredArray
                    })
                    this.optionsArray = this.optionsArray.filter(function (e) {
                        return e
                    })
                    filteredArray = []
                })
            }
        },

        handleDateChoose(date) {
            this.$nextTick(() => {
                const dateOption = {
                    name: `${moment(this.dateFrom).format('YYYY-MM-DD')} - ${moment(this.dateTo).format('YYYY-MM-DD')}`,
                    value: `${moment(this.dateFrom).format('YYYY-MM-DD')} - ${moment(this.dateTo).format('YYYY-MM-DD')}`,
                    type: 'custom-date'
                }
                this.$emit("change", JSON.stringify(dateOption))
                this.$emit("input", JSON.stringify(dateOption))
            })
        },

        updateList: utils.debounce(function () {
            let searchQ = {type: this.modelName, query: this.searchQuery, selected: this.optionsArray}
            if (this.searchBy && this.searchQuery.length >= 2) searchQ["search_by"] = this.searchBy
            if (this.searchQuery.length >= 2 || this.searchQuery.length === 0) {
                eventHub.$emit('search-list', {data: searchQ})
            }
        }, 1500),

        updateListClick() {
            let searchQ = {type: this.modelName, query: this.searchQuery, selected: this.optionsArray}
            if (this.searchBy) {
                searchQ["search_by"] = this.searchBy
            }
            eventHub.$emit('search-list', {data: searchQ})
        },

        pushOption(option) {
            if (!this.optionsArray.includes(option) && option.type !== 'custom-date') {
                this.optionsArray.push(option)
            } else if (option.type !== 'custom-date') {
                const index = this.optionsArray.indexOf(option)
                this.optionsArray.splice(index, 1)
            }
            if (option.type === 'custom-date') {
                let dateIndex = this.optionsArray.findIndex(option => option.type === 'custom-date')
                if (dateIndex !== -1) {
                    this.optionsArray[dateIndex] = option
                } else {
                    this.optionsArray.push(option)
                }
            }
            let formatedOptions = this.optionsArray.map((item) => {
                return item.type !== 'custom-date' ? item.id : JSON.stringify(item)
            })
            this.$emit("change", formatedOptions)
            this.$emit("input", formatedOptions)
        },

        toggleMenu() {
            this.showMenu = !this.showMenu
        },

        clickHandler(event) {
            const {target} = event
            const {$el} = this
            if (!$el.contains(target)) {
                this.showMenu = false
            }
        }
    }
}
</script>

<style lang="scss">
.v-dropdown {
    &.btn-group {
        min-width: 160px;
        height: 40px;
        position: relative;
        display: inline-block;
        vertical-align: middle;
    }

    &.btn-group a:hover {
        text-decoration: none;
    }

    .datepicker {
        .picker-wrap {
            width: 50%;

            .vdp-datepicker__calendar {
                background-color: var(--bg__dropdowns);

                header {
                    span {
                        color: var(--tp__main);

                        &:hover {
                            background: var(--bg__tooltip);
                        }
                    }

                    display: flex;
                }

                .day.selected {
                    color: var(--tp__main);
                }

                .month.selected {
                    background: var(--btn__main);
                    color: var(--tp__btn__main);
                }
            }
        }
    }

    .v-dropdown-toggle {
        position: relative;
        color: var(--tp__main);
        min-width: 170px;
        max-width: 170px;
        padding: 0 0 6px 0;
        text-transform: none;
        font-size: 16px;;
        font-weight: normal;
        border-bottom: 1px solid var(--border__form__normal);
        transition: background 0s ease-out;
        float: none;
        box-shadow: none;
        border-radius: 0;
        white-space: nowrap;
        text-overflow: ellipsis;
        overflow: hidden;

        i {
            top: calc(50% - 3px);
            transform: translateY(-50%);
            color: var(--tp__icons);
            transition: 0.2s ease;

            &.up {
                transform: translateY(-50%) rotate(-180deg);
            }
        }
    }

    .v-dropdown-toggle:hover {
        // background: #e1e1e1;
        cursor: pointer;
    }

    .v-dropdown-menu {
        position: absolute;
        top: 100%;
        left: 0;
        z-index: 100;
        float: left;
        min-width: 160px;
        max-width: 170px;
        padding: 0;
        margin: -8px 0 0;
        list-style: none;
        font-size: 14px;
        text-align: left;
        background-color: var(--bg__dropdowns);
        border-radius: 6px;
        background-clip: padding-box;
        display: block;
        border: none !important;

        //@include boxShadow__main();
        box-shadow: 0 4px 7px 0 var(--sh__main);

        .datepicker {
            display: flex;
            overflow: visible;
            padding-left: 8px;

            .day.selected, .day.selected.highlighted {
                background: var(--btn__main);
            }

            .day.highlighted {
                background: var(--btn__main);
                color: var(--tp__main);
            }
        }

        &.multi {
            li {
                display: flex;
                justify-content: flex-start;
                align-items: center;

                &.datepicker {
                    overflow: initial;
                }

                &.checked {
                    background: rgba(0, 0, 0, 0.05);
                    color: var(--tp__main);
                }

                &:hover {
                    background: rgba(0, 0, 0, 0.05);
                    color: var(--tp__main);
                }

                input {
                    margin-top: 0;
                    margin-left: 5px;
                }
            }
        }

        .GlobalIcon-Search {
            cursor: pointer;
        }
    }

    .v-dropdown-menu > li > a {
        padding: 10px 30px;
        display: block;
        clear: both;
        font-weight: normal;
        line-height: 1.6;
        color: var(--tp__main);
        white-space: nowrap;
        text-decoration: none;
    }

    .v-dropdown-menu:not(.multi) > li > a:hover {
        background: rgba(0, 0, 0, 0.05);
        color: var(--tp__active);
    }

    .v-dropdown-menu > li {
        overflow: hidden;
        width: 100%;
        position: relative;
        margin: 0;
    }

    i {
        right: 0;
        top: 3px;
        position: absolute;
    }

    li {
        list-style: none;
    }

    .picker-wrap {
        .headerNavigation {
            margin-left: 7px;
        }
    }
}
</style>
