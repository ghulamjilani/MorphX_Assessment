<template>
    <div class="v-filters">
        <div class="fs-l text-color-Darkgrey SF__section top">
            <span
                v-if="isSession"
                class="titles">Live</span>
            <span
                v-else-if="isVideo"
                class="titles">Replays</span>
            <span
                v-else-if="isRecording"
                class="titles">Uploads</span>
            <span v-else-if="!isSearch">Filters</span>
            <div class="title">
                <div
                    class="media-toggle-filter margin-bottom-10"
                    @click.prevent="toggle">
                    <i
                        :class="{ session: isSession }"
                        class="GlobalIcon-filters" />
                    <span>Filters</span>
                </div>
                <div class="searchWrapper">
                    <div class="filter-wrap search">
                        <input
                            v-model="query"
                            :placeholder="isSearch ? 'Search' : 'Search by title'"
                            class="inputsearch"
                            type="text"
                            @keyup.enter="apply()">
                        <i
                            v-if="query.length"
                            class="GlobalIcon-clear clearButton"
                            @click="clear()" />
                        <i
                            class="GlobalIcon-Search"
                            @click="apply()" />
                    </div>
                    <div class="resultsCounts">
                        <span v-if="isSearch">{{ resultsFound }} results found</span>
                    </div>
                </div>
                <div class="sortFilerAndViewButton">
                    <div
                        :class="{'search-sort': isSearch}"
                        class="sort-filter">
                        <template v-if="!isSession">
                            <label>Sort By</label>
                            <dropdown
                                v-model="sort"
                                :options="sortOptions"
                                class="sortByDropdown"
                                @change="sortChange" />
                        </template>
                        <!-- <a href="" @click.prevent="toggle" class="btn btn-l styled-select_withCss filter-by" :class="{ session: isSession }">-->
                        <!--   Filter By-->
                        <!--   <span></span>-->
                        <!-- </a>-->
                    </div>
                    <i
                        v-if="isSearch"
                        :class="{'two-column': isTwoColumn}"
                        class="GlobalIcon-4cube"
                        @click="toggleGridOrientation" /> <!-- swap to VideoClientIcon-list -->
                    <button
                        v-if="!isSearch"
                        :class="{ session: isSession, activity: isOpen }"
                        class="togleFilters btn btn-m btn-borderred-grey"
                        @click.prevent="toggle">
                        Filters
                        <i
                            :class="{rotated: isOpen}"
                            class="GlobalIcon-filters" />
                    </button>
                </div>
            </div>
        </div>
        <div
            v-show="isOpen"
            class="row filters SF__section toggleSection">
            <div
                :class="{ session: isSession }"
                class="closeFixed"
                @click.prevent="toggle">
                <i class="GlobalIcon-clear" />
                <span>Filters</span>
            </div>
            <div class="filter-container">
                <div
                    class="filter-wrap"
                    style="display: none">
                    <select class="btn btn-l styled-select_withCss date">
                        <option value="all">
                            <a href="#">All time</a>
                        </option>
                        <option value="today">
                            Today
                        </option>
                        <option value="thisWeek">
                            This week
                        </option>
                        <option value="thisMonth">
                            This month
                        </option>
                        <option value="thisYear">
                            This year
                        </option>
                    </select>
                </div>
                <div
                    v-if="isSearch"
                    class="filter-wrap date">
                    <dropdown
                        v-model="date"
                        :options="dateOptions"
                        :with-datepicker="true"
                        placeholder="Date"
                        @change="apply()" />
                </div>
                <div
                    v-if="!isSearch"
                    class="filter-wrap">
                    <dropdown
                        v-model="date"
                        :options="dateOptions"
                        placeholder="Date"
                        @change="apply()" />
                </div>
                <div class="filter-wrap">
                    <dropdown
                        v-model="duration"
                        :options="durationOptions"
                        placeholder="Duration"
                        @change="apply()" />
                </div>
                <div
                    v-if="!isSearch"
                    class="filter-wrap">
                    <dropdown
                        v-model="price"
                        :options="priceOptions"
                        placeholder="Price"
                        @change="apply()" />
                </div>
                <div
                    v-if="isSearch && creatorOptions.length > 0"
                    class="filter-wrap creators">
                    <dropdown
                        v-model="creatorA"
                        :options="creatorOptions"
                        :search-by="'title'"
                        :type="'multi'"
                        :with-search="true"
                        :placeholder="$t('dictionary.creators_upper')"
                        @change="apply()" />
                </div>
                <div
                    v-if="isSearch"
                    class="filter-wrap">
                    <dropdown
                        v-model="type"
                        :options="typeOptions"
                        placeholder="All results"
                        @change="typeChange()" />
                </div>
            </div>
            <button
                :class="{ session: isSession }"
                class="btn btn-m apply"
                @click="apply()"
                @click.prevent="toggle">
                Apply
            </button>
            <div class="multisearch padding-bottom-40 multyForMobile">
                <div class="multyWrapper">
                    <div
                        v-for="tag in tagsList"
                        :key="tag.value"
                        class="multi">
                        <span>{{ tag.name }}</span>
                        <i
                            class="GlobalIcon-clear"
                            @click="resetFilter(tag)" />
                    </div>
                </div>
                <div
                    v-if="tagsList.length > 0"
                    class="reset"
                    @click="resetAllFilters">
                    Reset ({{ tagsList.length }})
                </div>
            </div>
        </div>
        <div class="multisearch">
            <div class="multyWrapper">
                <div
                    v-for="tag in tagsList"
                    :key="tag.value"
                    class="multi">
                    <span>{{ tag.name }}</span>
                    <i
                        class="GlobalIcon-clear"
                        @click="resetFilter(tag)" />
                </div>
            </div>
            <div
                v-if="tagsList.length > 0"
                class="btn btn-m btn-borderred-grey reset"
                @click="resetAllFilters">
                Reset ({{ tagsList.length }})
            </div>
        </div>
    </div>
</template>

<script>
import query from "@mixins/query.js"
import multiModels from "@mixins/multiModels.js"
import eventHub from "@helpers/eventHub.js"
import helper from "@helpers/utils.js"
import Creator from '@models/Creator'
import dropdown from "@components/common/Dropdown"
import {mapActions, mapGetters} from 'vuex'

export default {
    components: {dropdown},
    mixins: [query, multiModels],
    props: ["forModel", "channel_id"],
    data() {
        return {
            resultsFound: 0,
            sort: "new",
            price: "all",
            duration: "all",
            date: "all",
            dateA: [],
            durationA: [],
            creatorA: [],
            type: 'all',
            query: "",
            tagsList: [],
            creatorOptions: [],
            isOpen: false,
            typeOptions: [
                {name: 'All results', value: 'all'},
                {name: 'Replays', value: 'Video'},
                {name: 'Lives', value: 'Session'},
                {name: 'Uploads', value: 'Recording'},
                {name: 'Channels', value: 'Channel'},
                {name: this.$t('frontend.app.components.channel.blog.community'), value: 'Blog::Post'},
                {name: this.$t('dictionary.creators_upper'), value: 'User'}
            ],
            dateOptions: [
                {name: "All Time", value: "all"},
                {name: "Today", value: "today"},
                {name: "This week", value: "thisWeek"},
                {name: "This month", value: "thisMonth"},
                {name: "This Year", value: "thisYear"}
            ],
            durationOptions: [
                {name: "All", value: "all"},
                {name: "0 - 30 min", value: "short"},
                {name: "30 - 60 min", value: "mid"},
                {name: "1+ hours", value: "long"}
            ],
            priceOptions: [
                {name: "All", value: "all"},
                {name: "Paid", value: "paid"},
                {name: "Free", value: "free"}
            ],
            sortOptions: [
                {name: "Newest", value: "new"},
                {name: "Most Viewed", value: "views_count"}
                // { name: "Most Relevant", value: "rank" }, if isSearch
            ]
        }
    },
    computed: {
        ...mapGetters({
            isTwoColumn: 'isSearchInTwoColumn'
        }),
        filterParams() {
            let fp = {}
            fp[`${this.prefix}ord`] = this.sort
            fp[`${this.prefix}pr`] = this.price
            fp[`${this.prefix}dr`] = this.duration
            fp[`${this.prefix}dra`] = this.durationA
            fp[`${this.prefix}dt`] = this.date
            fp[`${this.prefix}dta`] = this.dateA
            fp[`${this.prefix}q`] = this.query
            fp[`${this.prefix}cra`] = this.creatorA
            fp[`${this.prefix}t`] = this.type
            return fp
        },
        encodedParams() {
            let ep = {}
            ep[`${this.prefix}ord`] = 'sort'
            ep[`${this.prefix}pr`] = 'price'
            ep[`${this.prefix}dr`] = 'duration'
            ep[`${this.prefix}dra`] = 'durationA'
            ep[`${this.prefix}dt`] = 'date'
            ep[`${this.prefix}dta`] = 'dateA'
            ep[`${this.prefix}q`] = 'query'
            ep[`${this.prefix}cra`] = 'creatorA'
            ep[`${this.prefix}t`] = 'type'
            return ep
        }
    },
    methods: {
        ...mapActions({
            clearSearchList: 'CLEAR_SEARCH_LIST',
            toggleGridOrientation: 'TOGGLE_SEARCH_GRID_ORIENTATION'
        }),
        toggle() {
            this.isOpen = !this.isOpen
        },
        sortChange() {
            eventHub.$emit("sortChange", {data: {sort: this.sort}, type: this.forModel})
            this.apply()
        },
        typeChange() {
            if ('Channel' === this.type || 'User' === this.type) {
                this.resetDate()
                this.resetDuration()
            }
            this.apply()
        },
        clear() {
            this.query = ''
        },
        param(urlParams) {
            return Object.keys(urlParams).map(function(p) {
                return encodeURIComponent(p) + '=' + encodeURIComponent(urlParams[p])
            }).join('&')
        },
        apply(showMore = {}) {
            this.$nextTick(async () => {
                if (this.forModel === 'search') {
                    await this.clearSearchList()
                }
                let params = Object.assign({}, showMore, this.defaultParams, this.prepareParams(this.filterParams, this.prefix))
                this.updateTagsList()

                eventHub.$emit("loadingChange", {data: {loading: true, showMore: showMore}, type: this.forModel})
                this.model.api().search(params).then(() => {
                    eventHub.$emit("loadingChange", {
                        data: {loading: false, showMore: showMore},
                        type: this.forModel
                    })
                })
                eventHub.$emit("applyFilter", {data: {}, type: this.forModel})

                let urlParams = Object.assign({}, this.$route.query, this.filterParams)
                urlParams = this.clearPrams(urlParams)
                window.history.pushState(null, null, `?${this.param(urlParams)}`)
            })
        },
        updateTagsList() {
            let fieldToWatch = [
                'sort', 'price', 'duration', 'date', 'type', 'creatorA', 'dateA', 'durationA'
            ]
            this.tagsList = fieldToWatch.filter((field) => {
                if (
                    (field === 'sort' && this[field] === 'rank' && this.isSearch) ||
                    (field === 'sort' && this[field] === 'new' && !this.isSearch) ||
                    this[field] === 'all' ||
                    typeof this[field] === 'object' ||
                    this[field].includes('custom-date')
                ) {
                    return false
                } else {
                    return true
                }
            }).map(field => {
                return {
                    field: field,
                    value: this[field],
                    name: this[field + 'Options'].find(f => f.value === this[field]).name
                }
            })
            if (this.date.includes('custom-date')) {
                const date = JSON.parse(this.date)
                let additionalTags = []
                additionalTags.push({
                    field: 'date',
                    value: date.name,
                    name: date.name
                })
                this.tagsList = [...this.tagsList, ...additionalTags]
            }
            const multiFieldName = fieldToWatch.filter((field) => {
                return typeof this[field] === 'object'
            })
            if (multiFieldName) {
                let additionalTags = []
                multiFieldName.forEach((name) => {
                    this[name].length ?
                        this[name].forEach(item => {
                                additionalTags.push({
                                    field: name,
                                    value: this[name.slice(0, -1) + 'Options'].find(f => f.id === Number(item))?.id,
                                    name: this[name.slice(0, -1) + 'Options'].find(f => f.id === Number(item))?.name
                                })
                            }
                        )
                        : null
                })
                this.tagsList = [...this.tagsList, ...additionalTags]
            }
        },
        resetFilter(tag) {
            if (typeof this[tag.field] !== 'object') {
                if (tag.field === 'sort') {
                    this[tag.field] = this.isSearch ? 'rank' : 'new'
                } else {
                    this[tag.field] = 'all'
                }
                this.apply()
            } else {
                const index = this.tagsList.indexOf(tag)
                this.tagsList.splice(index, 1)
                this[tag.field] = this[tag.field].filter(item => !item.toString().includes(tag.value))
                this.apply()
            }
        },
        resetAllFilters() {
            this.sort = this.isSearch ? 'rank' : 'new'
            this.price = "all"
            this.duration = "all"
            this.date = "all"
            this.type = "all"
            this.creatorA = []
            this.durationA = []
            this.dateA = []
            this.apply()
        },
        resetDate() {
            this.date = "all"
            this.dateA = []
        },
        resetDuration() {
            this.duration = "all"
            this.durationA = []
        }
    },
    mounted() {
        eventHub.$on("searchResponse", ({type, data}) => {
            if (type === this.forModel && data.response.hasOwnProperty('documents')) {
                this.resultsFound = data.pagination?.count
            }
        })
    },
    async created() {
        if (this.isSearch) {
            this.sortOptions.push({name: "Most Relevant", value: "rank"})
            this.sort = 'rank'
        }
        Object.entries(this.$route.query).forEach(([key, value]) => {
            let paramName = this.encodedParams[key]
            if(paramName && ['durationA', 'dateA', 'creatorA'].includes(paramName)) {
                this[paramName] = value.split(',').map( Number )
            }
            else if (paramName){
                this[paramName] = value
            }
        })
        if (this.isSearch) {
            await Creator.api().search({user_id: this.creatorA.toString(), without_create: true})
            await Creator.api().search({without_create: true})
            const selectedUsers = Creator.findIn(this.creatorA)
            const allUsers = Creator.all()
            const filteredArray = helper.removeDuplicates([...selectedUsers, ...allUsers], 'id').reverse()
            this.creatorOptions = [...new Set([...selectedUsers, ...filteredArray])]
        }

        // todo: Andrey refactor
        setTimeout(() => {
            this.sortChange()
        }, 1000)

        eventHub.$on('search-list', ({data}) => {
            const classes = {
                'Creator': Creator
            }
            let queryData = {query: data.query}
            if (data.search_by) queryData["search_by"] = data.search_by
            classes[data.type].api().search(queryData).then((r) => {
                let items = classes[data.type].all()
                let noItems = {
                    name: 'No creators',
                    value: 'noitems'
                }
                this[`${data.type.toLowerCase()}Options`] = items.length ? items : [noItems]
                const array = [...data.selected, ...this[`${data.type.toLowerCase()}Options`]]
                // todo: remove kostil
                this[`${data.type.toLowerCase()}Options`] = [...new Set(array)]
                this.creatorOptions = [...new Map(this.creatorOptions.map(item => [item['id'], item])).values()]
                this.creatorA = [].concat(this.creatorA)
            })
        })
        eventHub.$on("showMore", ({type, data}) => {
            if (type === this.forModel) {
                this.apply(data)
            }
        })
    }
}
</script>
