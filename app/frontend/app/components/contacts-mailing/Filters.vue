<template>
    <div class="CM__filters">
        <div class="CM__filters__all">
            <m-dropdown
                class="CM__filters__customSelectAll"
                :custom="true"
                :close-by-self-click="true">
                <template #custom="{open}">
                    <m-checkbox
                        v-model="isSelectAllOnPage"
                        class="CM__filters__all__checkbox"
                        :icon="isSelectAllProp ? 'GlobalIcon-check' : 'GlobalIcon-Plus'"
                        @click="selectAllOnPage($event)">
                        <!-- Select All -->
                    </m-checkbox>
                    <m-icon
                        size="1rem"
                        class="CM__filters__customSelectAll__arrow"
                        :class="{active: open}">
                        GlobalIcon-angle-down
                    </m-icon>
                </template>
                <m-option
                    v-if="selected.length > 0"
                    @click="uncheckAll">
                    Uncheck All
                </m-option>
                <m-option @click="selectAll">
                    Select All
                </m-option>
            </m-dropdown>
            <div
                v-show="selected.length"
                class="CM__filters__remove"
                @click="openRemoveModal(null, false)">
                <m-icon
                    class="CM__filters__remove__icon"
                    size="0">
                    GlobalIcon-trash
                </m-icon>
                <div class="CM__filters__remove__text">
                    Remove
                </div>
            </div>
        </div>
        <div class="CM__filters__search">
            <m-input
                v-model.trim="fetchOptions.q"
                :errors="false"
                :maxlength="60"
                :pure="true"
                field-id="search"
                placeholder="Search..."
                @enter="fetch()"
                @input="fetch()">
                <template #icon>
                    <m-icon
                        v-if="fetchOptions.q.length"
                        class="CM__filters__search__cross"
                        size="0"
                        @click="clearSearch()">
                        GlobalIcon-clear
                    </m-icon>
                    <m-icon
                        class="CM__filters__search__lens"
                        size="0"
                        @click="fetch()">
                        GlobalIcon-search
                    </m-icon>
                </template>
            </m-input>
        </div>
        <m-select
            v-model="fetchOptions.statusRaw"
            :options="statusOptions"
            :without-error="true"
            :mutiselect="true"
            :disabled-with-normal-style="true"
            class="CM__filters__select"
            placeholder="Status"
            type="default"
            @change="fetch()" />
        <div class="CM__paginate mobile-top">
            <p class="CM__paginate__text">
                {{ paginationData.from }}-{{ paginationData.to }} from {{ paginationData.total }}
            </p>
            <a
                :class="{'CM__paginate__disable' : paginationData.from < paginationData.perPage + 1}"
                class="CM__paginate__arrow"
                @click="fetch({prevPage: true})">
                <m-icon
                    :class="{'CM__paginate__icon__disable' : paginationData.from < paginationData.perPage + 1}"
                    class="CM__paginate__icon"
                    size="0">
                    GlobalIcon-angle-left
                </m-icon>
            </a>
            <a
                :class="{'CM__paginate__disable' : paginationData.to == paginationData.total}"
                class="CM__paginate__arrow"
                @click="fetch({nextPage: true})">
                <m-icon
                    :class="{'CM__paginate__icon__disable' : paginationData.to == paginationData.total}"
                    class="CM__paginate__icon"
                    size="0">
                    GlobalIcon-angle-right
                </m-icon>
            </a>
        </div>
    </div>
</template>

<script>
import utils from '@helpers/utils'

export default {
    props: {
        paginationData: Object,
        statusOptions: Array,
        contacts: Array,
        selected: Array,
        isSelectAllProp: Boolean,
        canMailing: Boolean
    },
    data() {
        return {
            isSelectAllOnPage: false,
            fetchOptions: {
                q: '',
                offset: 0,
                limit: 25,
                status: [],
                statusRaw: []
            }
        }
    },
    watch: {
        value(val) {
            if (val !== this.fetchOptions) {
                this.fetchOptions = val
            }
        },
        fetchOptions: {
            handler(val) {
                // if(val.statusRaw === ["all"])
                this.$emit('input', val)
            },
            deep: true
        },
        selected: {
            handler() {
                this.checkSelected()
            },
            deep: true
        },
        isSelectAllProp(val) {
            if(val) this.isSelectAllOnPage = true
        }
    },
    mounted() {
        this.$eventHub.$on('clearSearch', () => {
            this.fetchOptions.q = ''
        })
        this.$eventHub.$on("contacts-page-update", () => {
            this.checkSelected()
        })
    },
    methods: {
        clearSearch() {
            this.$emit('clearSearch')
        },
        openRemoveModal(contact, one = true) {
            this.$emit('openRemoveModal', contact, one)
        },
        fetch: utils.debounce(function (options = {}) {
            this.$emit('fetch', options)
        }, 400),
        checkSelected() {
            this.$nextTick(() => {
                if(this.selected.some(s => this.contacts.find(c => c.id === s))) {
                    this.isSelectAllOnPage = true
                }
                else {
                    this.isSelectAllOnPage = false
                }
                if(this.selected.length === 0) {
                    this.isSelectAllOnPage = false
                }
            })
        },
        selectAll: utils.debounce(function () {
            this.fetchOptions.statusRaw = [this.statusOptions.find(so => so.value == 'all')]
            this.fetchOptions.q = ""
            this.$emit('input', this.fetchOptions)
            this.$emit('selectAll', true)
        }, 100),
        selectAllOnPage: utils.debounce(function () {
            this.$emit('selectAllOnPage', this.isSelectAllOnPage)
        }, 100),
        uncheckAll() {
            this.fetchOptions.statusRaw = [this.statusOptions.find(so => so.value == 'all')]
            this.fetchOptions.q = ""
            this.isSelectAllOnPage = false
            this.$emit('input', this.fetchOptions)
            this.$emit('selectAll', false)
        }
    }
}
</script>