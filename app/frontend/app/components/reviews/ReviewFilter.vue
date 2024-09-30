<template>
    <div
        :class="{'channelFilters__active': show}"
        class="channelFilters blogFilters">
        <div class="channelFilters__top">
            <div class="channelFilters__tagsList channelFilters__rightless">
                <b>Filters:</b>
                <m-chips
                    v-for="tag in tags"
                    v-show="tags.length > 0"
                    :key="tag.field + tag.value"
                    class="tagsMK2__tag">
                    {{ tag.name }}
                    <m-icon
                        class="tagsMK2__icon"
                        size=".8rem"
                        @click="clearParam(tag)">
                        GlobalIcon-clear
                    </m-icon>
                </m-chips>
                <m-chips
                    v-show="tags.length <= 0"
                    class="tagsMK2__tag tagsMK2__tag__iconless">
                    Default
                </m-chips>
            </div>
            <m-btn
                class=""
                type="bordered"
                @click="toggleFilters">
                {{ show ? 'Close' : 'Open' }} Filters
                <m-icon
                    class="managePost__header__filters__icon"
                    size="1rem">
                    GlobalIcon-filters
                </m-icon>
            </m-btn>
        </div>
        <div
            v-show="show"
            class="channelFilters__classType margin-b__30">
            <div class="channelFilters__classType__filters">
                <m-radio
                    v-for="option in options.classType"
                    :key="option.value"
                    v-model="classType"
                    :val="option.value">
                    {{ option.name }}
                </m-radio>
            </div>
            <div class="channelFilters__filters">
                <div class="channelFilters__filters__wrapper">
                    <b>Sort By</b>
                    <div class="channelFilters__filters__checkmarks">
                        <m-radio
                            v-for="option in options.sortBy"
                            :key="option.value"
                            v-model="sortBy"
                            :val="option.value">
                            {{ option.name }}
                        </m-radio>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>Date</b>
                    <div class="channelFilters__filters__datePicker">
                        <m-datepicker
                            v-model="date"
                            :placeholders="['From', 'To']"
                            :range="true"
                            @changed="dateChanged" />
                    </div>
                    <div class="channelFilters__filters__checkmarks">
                        <label
                            v-for="option in options.dateValue"
                            :key="option.value"
                            :class="{active: dateValue === option.value}"
                            @click="chooseDate(option.value)">{{ option.name }}</label>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>Channel</b>
                    <div>
                        <m-input
                            v-model="searchChannels"
                            :errors="false"
                            borderless
                            class="channelFilters__filters__input channelFilters__filters__review"
                            name="searchChannels"
                            placeholder="Enter channel name..."
                            pure
                            type="text" />
                    </div>
                    <!-- <div class="channelFilters__filters__checkmarks checkboxMK2 channelFilters__filters__checkmarks__all"
            @click="choosenChannels = ''">
            All
          </div> -->
                    <div class="channelFilters__filters__checkmarks">
                        <m-radio
                            v-model="choosenChannels"
                            :val="-1">
                            All
                        </m-radio>
                        <m-radio
                            v-for="channel in filteredChannels"
                            :key="channel.id"
                            v-model="choosenChannels"
                            :val="channel.id">
                            {{ channel.title }}
                        </m-radio>
                    </div>
                </div>
            </div>
        </div>
        <div
            v-show="show"
            class="channelFilters__buttons margin-t__30 text__right">
            <m-btn
                size="s"
                type="bordered"
                @click="clearSearchList">
                Reset {{ tags.length > 0 ? `(${tags.length})` : '' }}
            </m-btn>
            <m-btn
                size="s"
                type="save"
                @click="apply">
                Apply
            </m-btn>
        </div>
    </div>
</template>

<script>
import ClickOutside from 'vue-click-outside'
import Channel from "@models/Channel"

export default {
    directives: {
        ClickOutside
    },
    props: {
        type: {
            type: String,
            default: 'reviews'
        }
    },
    data() {
        return {
            show: false,
            searchChannels: "",
            options: {
                classType: [
                    {name: 'All', value: 'all'},
                    {name: 'Published', value: 'true'},
                    {name: 'Hidden', value: 'false'}
                ],
                dateValue: [
                    {name: 'All time', value: 'all', default: true},
                    {name: 'Today', value: 'today'},
                    {name: 'This week', value: 'thisWeek'},
                    {name: 'This month', value: 'thisMonth'},
                    {name: 'Past 3 months', value: 'past3Months'}
                ],
                sortBy: [
                    {name: 'Newest', value: 'new', default: true},
                    {name: 'Oldest', value: 'old'}
                    // { name: 'Hight Rating', value: 'rating' },
                    // { name: 'Lowest Rating', value: 'rating_low' }
                ]
            },
            paramsOptions: {},
            sortBy: 'new',
            date: {
                start: new Date(),
                end: new Date()
            },
            dateValue: "all",
            classType: 'all',
            choosenChannels: -1,
            channels: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        },
        filteredChannels() {
            return this.channels?.filter(ch => {
                return ch.title.toLowerCase().includes(this.searchChannels.toLowerCase())
            })
        },
        tags() {
            let fieldToWatch = [
                'dateVale', 'sortBy'
            ]
            let arraysToWatch = [
                // 'level'
            ]
            let tagsList = []
            tagsList = fieldToWatch.map(field => {
                let option = this.options[field]?.find(f => f.value === this[field])
                return {
                    field: field,
                    value: this[field],
                    type: 'string',
                    name: option ? option.name : '',
                    default: option ? option.default : true
                }
            }).filter(e => !e.default)

            arraysToWatch.forEach(field => {
                this[field].forEach(ff => {
                    let option = this.options[field].find(f => f.value === ff)
                    if (!option.default) {
                        tagsList.push({
                            field: field,
                            value: ff,
                            type: 'array',
                            objField: 'value',
                            name: option.name,
                            default: option.default
                        })
                    }
                })
            })

            if (this.choosenChannels !== '' && this.choosenChannels !== -1) {
                let channel = this.channels.find(m => m.id === this.choosenChannels)
                if (channel) {
                    tagsList.push(
                        {
                            field: "choosenChannels",
                            type: 'id',
                            objField: 'id',
                            value: channel.id,
                            name: channel.title
                        }
                    )
                }
            }

            // this.choosenChannels.forEach(e => {
            //   let channel = this.channels.find(m => m.id === e)
            //   if(channel) {
            //     tagsList.push(
            //       {
            //         field: "choosenChannels",
            //         type: 'array',
            //         objField: 'id',
            //         value: channel.id,
            //         name: channel.title
            //       }
            //     )
            //   }
            // })

            if (this.dateValue !== 'all') {
                let option = this.options.dateValue.find(e => this.dateValue === e.value)
                tagsList.push(
                    {
                        field: "dateValue",
                        type: 'string',
                        value: this.dateValue,
                        name: this.dateValue === 'Custom date' ? this.dateValue : option.name
                    }
                )
            }

            if (this.classType !== 'all') {
                let option = this.options.classType.find(e => this.classType === e.value)
                tagsList.push(
                    {
                        field: "classType",
                        type: 'string',
                        value: this.classType,
                        name: option.name
                    }
                )
            }

            return tagsList
        }
    },
    watch: {
        currentUser(val) {
            this.getUserFullChannels()
        }
    },
    mounted() {
        if (this.currentOrganization) this.getUserFullChannels()
    },
    methods: {
        getUserFullChannels() {
            Channel.api().getPublicOrganization({id: this.currentOrganization.id}).then(res => {
                this.channels = res.response.data.response.organization.channels
            })
        },
        openFilters() {
            this.show = true
        },
        toggleFilters() {
            this.show = !this.show
        },
        chooseDate(dateStr) {
            this.dateValue = dateStr

            let dateR = {start: null, end: null}
            let currentUserTimezone = this.currentUser?.timezone || moment.tz.guess()

            switch (dateStr) {
                case 'all':
                    dateR.start = null
                    dateR.end = moment().tz(currentUserTimezone).endOf('day').toISOString()
                    break
                case 'today':
                    dateR.start = moment().tz(currentUserTimezone).startOf('day').toISOString()
                    dateR.end = moment().tz(currentUserTimezone).endOf('day').toISOString()
                    break
                case 'thisWeek':
                    dateR.start = moment().tz(currentUserTimezone).startOf('week').startOf('day').toISOString()
                    dateR.end = moment().tz(currentUserTimezone).endOf('week').endOf('day').toISOString()
                    break
                case 'thisMonth':
                    dateR.start = moment().tz(currentUserTimezone).startOf('month').startOf('day').toISOString()
                    dateR.end = moment().tz(currentUserTimezone).endOf('month').endOf('day').toISOString()
                    break
                case 'past3Months':
                    dateR.start = moment().tz(currentUserTimezone).subtract(3, 'month').startOf('day').toISOString()
                    dateR.end = moment().tz(currentUserTimezone).endOf('day').toISOString()
                    break
            }

            this.date.start = new Date(dateR.start)
            this.date.end = new Date(dateR.end)
        },
        apply(showMore = {}) {
            let params = {}

            switch (this.sortBy) {
                case 'new':
                    params['order_by'] = 'created_at'
                    params['order'] = "desc"
                    break
                case 'old':
                    params['order_by'] = 'created_at'
                    params['order'] = "asc"
                    break
                case 'raiting':
                    params['order_by'] = 'rating'
                    params['order'] = "desc"
                    break
                case 'raiting_low':
                    params['order_by'] = 'rating'
                    params['order'] = "asc"
                    break
            }

            if (this.classType !== "all")
                params['visible'] = this.classType
            if (this.choosenChannels !== '' && this.choosenChannels !== -1) {
                params['reviewable_id'] = this.choosenChannels//.join(",")
                params['reviewable_type'] = "Channel"
            } else {
                params['reviewable_id'] = this.currentOrganization.id
                params['reviewable_type'] = "Organization"
            }
            if (this.dateValue !== 'all') {
                params['created_at_from'] = this.date.start
                params['created_at_to'] = this.date.end
            }

            this.$emit("updateSearch", params)

            this.show = false
        },
        clearSearchList() {
            this.sortBy = "new"
            this.date = {
                start: null,
                end: null
            },
                this.dateValue = "all"
            this.classType = 'all'

            this.choosenChannels = -1

            this.$emit("updateTilesList", [])
            this.apply()

            this.show = false
        },
        dateChanged() {
            this.dateValue = "Custom date"
        },
        hide() {
            this.show = false
        },
        clearParam(tag) {
            if (tag.type === 'string') {
                let def = this.options[tag.field].find(e => e.default)
                this[tag.field] = def ? def.value : 'all'
            } else if (tag.type === 'array') {
                this[tag.field] = this[tag.field].filter(e => e !== tag.value)
            } else if (tag.type === 'id') {
                this[tag.field] = ''
            }
            if (this.tags.length > 0) {
                this.apply()
            } else {
                this.apply()
            }
        }
    }
}
</script>