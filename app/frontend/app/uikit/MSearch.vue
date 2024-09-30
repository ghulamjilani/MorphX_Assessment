<template>
    <div class="m-search">
        <m-input
            v-model="query"
            :placeholder="placeholder"
            :pure="true">
            <template #icon>
                <m-icon>GlobalIcon-search</m-icon>
                <m-icon
                    v-if="query.length"
                    @click="query = ''">
                    GlobalIcon-clear
                </m-icon>
            </template>
        </m-input>

        <div
            v-if="isShowSearchResult"
            class="dropdownMK2__menu">
            <template>
                <div
                    v-for="option in searchResutls"
                    :key="option.user.id"
                    class="dropdownMK2__item"
                    @click="updateOption(option)">
                    <slot :option="option">
                        {{ option }}
                    </slot>
                </div>
            </template>
        </div>
        <div
            v-else-if="!isShowSearchResult && query.length > 3"
            class="dropdownMK2__menu">
            <div class="dropdownMK2__item">
                There are no results
            </div>
        </div>
    </div>
</template>

<script>
import utils from '@helpers/utils'
import axios from "@plugins/axios.js"

export default {
    props: {
        searchUrl: {
            type: String,
            required: true
        },
        responsePayloadPath: {
            type: String,
            default: ''
        },
        placeholder: {
            type: String,
            default: ""
        }
    },
    data() {
        return {
            query: '',
            selectedItem: '',
            isAbleToShowSearchResult: true,
            searchResutls: []
        }
    },
    computed: {
        isShowSearchResult() {
            return this.searchResutls.length && this.isAbleToShowSearchResult && this.query
        }
    },
    watch: {
        query(val) {
            if (val.length > 2) {
                this.search()
            }
        },
        selectedItem(val) {
            this.$emit("input", val)
            this.$emit("change", val)
            this.isAbleToShowSearchResult = false
        }
    },
    methods: {
        search: utils.debounce(function () {
            this.isAbleToShowSearchResult = true
            axios.get(this.searchUrl, {
                params: {
                    query: this.query
                }
            }).then((response) => {
                this.searchResutls = this.responsePayloadPath ? this.responsePayloadPath.split('.').reduce((o, i) => o[i], response) : response.data
            })
        }, 500),
        updateOption(option) {
            this.selectedItem = option
        }
    }
}
</script>