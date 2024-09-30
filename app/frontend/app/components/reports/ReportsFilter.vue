<template>
    <div class="reportFilters channelFilters blogFilters">
        <div class="channelFilters__tagsList">
            <m-icon
                class="toggle-icon"
                v-show="show"
                @click="hide">
                GlobalIcon-clear </m-icon>
            <m-icon
                class="toggle-icon"
                v-show="!show"
                @click="openFilters">
                GlobalIcon-angle-down </m-icon>
            <b>Filters</b>
            <m-chips
                v-for="tag in tags"
                :key="tag.field + tag.value"
                class="tagsMK2__tag">
                {{ tag.name }}
                <m-icon
                    v-show="!tag.default"
                    class="tagsMK2__icon"
                    size=".8rem"
                    @click="clearParam(tag)">
                    GlobalIcon-clear
                </m-icon>
            </m-chips>
        </div>
        <div
            v-show="show"
            class="channelFilters__classType margin-b__30">
            <div class="channelFilters__filters">
                <div class="channelFilters__filters__wrapper">
                    <b> {{ $t('frontend.app.components.reports.reports_filter.organizations') }} </b>
                    <div>
                        <m-input
                            v-model="organizationsListParams.name"
                            :errors="false"
                            @input="getOrganizations"
                            borderless
                            class="channelFilters__filters__input"
                            name="searchChannel"
                            placeholder="Enter name..."
                            pure
                            type="text" />

                        <div class="channelFilters__filters__checkmarks">
                            <m-checkbox
                                :value="choosenOrg.length == 0"
                                :val="[]"
                                @click="choosenOrg = []">
                                All
                            </m-checkbox>
                            <m-checkbox
                                v-for="org in organizationsList"
                                :key="org.id"
                                v-model="choosenOrg"
                                :val="org.id">
                                {{ org.name }}
                            </m-checkbox>
                        </div>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>{{ $t('frontend.app.components.reports.reports_filter.channels') }}</b>
                    <div>
                        <m-input
                            v-model="channelsListParams.name"
                            :errors="false"
                            @input="getChannels"
                            borderless
                            class="channelFilters__filters__input"
                            name="searchChannel"
                            placeholder="Enter name..."
                            pure
                            type="text" />
                    </div>
                    <div class="channelFilters__filters__checkmarks">
                        <m-checkbox
                            :value="choosenChannels.length == 0"
                            :val="[]"
                            @click="choosenChannels = []">
                            All
                        </m-checkbox>
                        <m-checkbox
                            v-for="channel in filteredChannels"
                            :key="channel.id"
                            :disabled="channel.disabled"
                            v-model="choosenChannels"
                            :val="channel.id">
                            {{ channel.title }}
                        </m-checkbox>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>{{ $t('frontend.app.components.reports.reports_filter.date') }}</b>
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
import Reports from "@models/Reports"
import utils from '@helpers/utils'

export default {
    directives: {
        ClickOutside
    },
    data() {
        return {
            show: false,
            options: {
                dateValue: [
                    {name: 'All time', value: 'all'},
                    {name: 'Today', value: 'today'},
                    {name: 'This week', value: 'thisWeek'},
                    {name: 'This month', value: 'thisMonth', default: true},
                    {name: 'Past 3 months', value: 'past3Months'}
                ]
            },
            paramsOptions: {},
            date: {
                start: new Date(),
                end: new Date()
            },
            dateValue: "thisMonth",
            choosenChannels: [],
            searchChannel: "",
            choosenOrg: [],
            channelsList: [],
            channelsListParams: {
                limit: 20,
                offset: 0,
                name: "",
                organization_ids: []
            },
            organizationsList: [],
            organizationsListParams: {
                limit: 20,
                offset: 0,
                name: ""
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        filteredChannels() {
            return this.channelsList
            // .filter(channel => {
            //     return this.searchChannel == "" ? true :
            //         channel.title.toLowerCase().includes(this.searchChannel.toLowerCase())
            // })
            // .map(channel => {
            //     channel.disabled = this.choosenOrg.length == 0 ? false : !this.choosenOrg.includes(channel.organization_id)
            //     if(channel.disabled) this.choosenChannels = this.choosenChannels.filter(e => e!= channel.id)
            //     return channel
            // })
        },
        tags() {
            let fieldToWatch = [
                'dateVale'
            ]
            let arraysToWatch = []
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

            // if (this.dateValue !== 'all2') {
                let option = this.options.dateValue.find(e => this.dateValue === e.value)
                console.log("option, !!!!!!", option);
                tagsList.push(
                    {
                        field: "dateValue",
                        type: 'string',
                        value: this.dateValue,
                        name: this.dateValue === 'Custom date' ? this.dateValue : option.name,
                        default: option?.default
                    }
                )
            // }

            if(this.choosenOrg.length == 0) {
                tagsList.push(
                    {
                        field: "choosenOrg",
                        type: 'string',
                        value: "all",
                        name: "All organizations",
                        default: true
                    })
            }
            else {
                this.choosenOrg.forEach(e => {
                    let org = this.organizationsList.find(m => m.id === e)
                    if (org) {
                        tagsList.push(
                            {
                                field: "choosenOrg",
                                type: 'array',
                                objField: 'id',
                                value: org.id,
                                name: org.name,
                                default: false
                            }
                        )
                    }
                })
            }


            if(this.choosenChannels.length == 0) {
                tagsList.push(
                    {
                        field: "choosenChannels",
                        type: 'string',
                        value: "all",
                        name: "All channels",
                        default: true
                    })
            }
            else {
                this.choosenChannels.forEach(e => {
                    let channel = this.channelsList.find(m => m.id === e)
                    if (channel) {
                        tagsList.push(
                            {
                                field: "choosenChannels",
                                type: 'array',
                                objField: 'id',
                                value: channel.id,
                                name: channel.title,
                                default: false
                            }
                        )
                    }
                })
            }

            return tagsList
        }
    },
    watch: {
        choosenOrg(val) {
            this.channelsListParams.organization_ids = val
            this.getChannels()
        }
    },
    mounted(){
        this.getOrganizations()
        this.getChannels()
        this.chooseDate(this.dateValue)
        this.apply()
	},
    methods: {
        openFilters() {
            this.show = true
        },
        toggleFilters() {
            this.show = !this.show
        },
        chooseDate(dateStr) {
            this.dateValue = dateStr
            setTimeout(() => {
                this.dateValue = dateStr
            }, 100)

            let dateR = {start: null, end: null}

            switch (dateStr) {
                case 'all':
                    dateR.start = null
                    dateR.end = null
                    break
                case 'today':
                    dateR.start = moment().tz("Europe/London").startOf('day').toISOString()
                    dateR.end = moment().tz("Europe/London").endOf('day').toISOString()
                    break
                case 'thisWeek':
                    dateR.start = moment().tz("Europe/London").startOf('week').startOf('day').toISOString()
                    dateR.end = moment().tz("Europe/London").endOf('week').endOf('day').toISOString()
                    break
                case 'thisMonth':
                    dateR.start = moment().tz("Europe/London").startOf('month').startOf('day').toISOString()
                    dateR.end = moment().tz("Europe/London").endOf('month').endOf('day').toISOString()
                    break
                case 'past3Months':
                    dateR.start = moment().tz("Europe/London").subtract(3, 'month').startOf('day').toISOString()
                    dateR.end = moment().tz("Europe/London").endOf('day').toISOString()
                    break
            }

            this.date.start = dateR.start ? new Date(dateR.start) : null
            this.date.end = dateR.end ? new Date(dateR.end) : null
        },
        apply() {
            let params = {}

            if (this.dateValue !== 'all') {
                params['date_from'] = this.date.start
                params['date_to'] = this.date.end
            }

            params['channel_ids'] = this.choosenChannels
            params['organization_ids'] = this.choosenOrg

            this.$emit("updateSearch", params)

            this.hide()
        },
        clearSearchList() {
            this.date = {
                start: null,
                end: null
            },
            this.dateValue = this.options.dateValue.find(e => e.default).value
            setTimeout(() => {
                this.dateValue = this.options.dateValue.find(e => e.default).value
            }, 100)

            this.choosenChannels = []
            this.choosenOrg = []

            this.$emit("updateTilesList", [])
            this.apply()

            this.hide()
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
                if(tag.field == "dateValue") this.chooseDate(def.value)
            } else if (tag.type === 'array') {
                this[tag.field] = this[tag.field].filter(e => e !== tag.value)
            }

            this.apply()
        },
        getOrganizations: utils.debounce(function () {
            Reports.api().getOrganizations(this.organizationsListParams).then(res => {
				this.organizationsList = res.response.data.response
			})
        }, 500),
        getChannels: utils.debounce(function () {
            Reports.api().getChannels(this.channelsListParams).then(res => {
				this.channelsList = res.response.data.response
			})
        }, 500)
    }
}
</script>