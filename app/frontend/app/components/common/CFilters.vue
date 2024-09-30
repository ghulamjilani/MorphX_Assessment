<template>
    <div
        v-click-outside="hide"
        :class="{'channelFilters__searchWrapper': show}"
        class="mChannel__tiles__filters channelFilters">
        <div
            v-if="show"
            class="closeFilters">
            <span @click="hide()">Close Filters</span>
            <i
                class="GlobalIcon-clear"
                @click="hide()" />
        </div>
        <mb-schedule
            v-if="channel.id"
            :channel_id="channel.id"
            :mb-schedule-uid="mbScheduleUid"
            placement="spa"
            scheduler-for="mbs-organization"
            sm="hidden" />
        <div class="channelFilters__input__wrapp">
            <div
                class="channelFilters__input__cover"
                @click="openFilters">
                <m-input
                    v-model="query"
                    :errors="false"
                    borderless
                    class="channelFilters__input"
                    field-id="searchField"
                    name="search"
                    placeholder="Search"
                    pure
                    type="text"
                    @enter="apply" />
                <m-checkbox
                    v-show="show"
                    v-model="descriptionIncluded"
                    class="channelFilters__input__descriptionIncluded">
                    Search with description included
                </m-checkbox>
            </div>
            <div
                v-if="!show"
                class="channelFilters__icons">
                <m-icon
                    class="channelFilters__icons__Search"
                    @click="openFilters">
                    GlobalIcon-Search
                </m-icon>
                <m-icon
                    v-if="channel && channel.live_guide_is_visible"
                    @click="setCalendarMode">
                    GlobalIcon-empty-calendar
                </m-icon>
                <m-icon @click="shareChannel">
                    GlobalIcon-share
                </m-icon>
                <m-icon
                    v-if="can_edit_channel || can_archive_channel"
                    @click="toggleOptions">
                    GlobalIcon-dots-3
                </m-icon>
                <div
                    v-show="optionsChannel"
                    class="channelFilters__icons__options__cover"
                    @click="toggleOptions" />
                <div
                    v-show="optionsChannel"
                    class="channelFilters__icons__options">
                    <a
                        v-if="can_edit_channel"
                        :href="editChannelLink"
                        target="_blank"
                        @click="optionsChannel = false">{{ $t('channel_page.edit_channel') }}</a>
                    <!-- TODO: Andrey, add redirect -->
                    <!--          <a v-if="isInvaiteCreatorAvailable" :href="editCreatorLink" @click="optionsChannel = false" target="_blank">Invite Creators</a>-->
                    <!--          <a v-else class="disabled" @click.prevent v-tooltip="'Not allowed by your Business plan'">Invite Creators</a>-->
                    <a
                        v-if="can_archive_channel"
                        @click="confirmArchive($event)">{{ $t('channel_page.archive_channel') }}</a>
                </div>
            </div>
        </div>
        <div
            v-show="!show && tags.length > 0"
            class="channelFilters__tagsList">
            <b>Results</b>
            <m-chips
                v-for="tag in tags"
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
        </div>
        <div
            v-show="show"
            class="channelFilters__classType margin-b__30">
            <div class="margin-b__25">
                <b>Session type</b>
            </div>
            <div class="channelFilters__classType__filters">
                <m-checkbox
                    :value="isAllclassTypeChecked"
                    @input="setIsClassTypeMode">
                    All
                </m-checkbox>
                <m-checkbox
                    v-for="option in options.classType"
                    :key="option.value"
                    v-model="classType"
                    :val="option.value">
                    {{ option.name }}
                </m-checkbox>
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
                <div class="channelFilters__filters__wrapper hide">
                    <b>Level</b>
                    <div class="channelFilters__filters__checkmarks">
                        <m-checkbox
                            v-for="option in options.level"
                            :key="option.value"
                            v-model="level"
                            :disabled="true"
                            :val="option.value">
                            {{ option.name }}
                        </m-checkbox>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>Duration</b>
                    <div class="channelFilters__filters__checkmarks">
                        <m-radio
                            v-for="option in options.duration"
                            :key="option.value"
                            v-model="duration"
                            :val="option.value">
                            {{ option.name }}
                        </m-radio>
                    </div>
                </div>
                <div class="channelFilters__filters__wrapper">
                    <b>{{ $t('dictionary.creator_upper') }}</b>
                    <div>
                        <m-input
                            v-model="searchMembers"
                            :errors="false"
                            borderless
                            class="channelFilters__filters__input"
                            name="searchMembers"
                            placeholder="Enter name..."
                            pure
                            type="text" />
                    </div>
                    <div class="channelFilters__filters__checkmarks">
                        <m-checkbox
                            v-for="member in filteredMembers"
                            :key="member.id"
                            v-model="choosenMembers"
                            :val="member.id">
                            {{ member.public_display_name }}
                        </m-checkbox>
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
import eventHub from "@helpers/eventHub.js"
import MbSchedule from "@components/mindbodyonline/schedule/MbSchedule"
import User from "@models/User"
import Channel from "@models/Channel"

export default {
    directives: {
        ClickOutside
    },
    components: {
        MbSchedule
    },
    props: {
        members: {},
        channel: {},
        owner: {},
        organization_relative_path: String,
        subscription_features: {}
    },
    data() {
        return {
            optionsChannel: false,
            show: false,
            searchMembers: "",
            options: {
                classType: [
                    {name: 'Live', value: 'Session'},
                    {name: 'Replays', value: 'Video'},
                    {name: 'Uploads', value: 'Recording'}
                ],
                sortBy: [
                    {name: 'Most recent', value: 'new', default: true},
                    {name: 'Most viewed', value: 'views_count'},
                    {name: 'Most popular', value: 'rank'}
                ],
                level: [
                    {name: 'Beginner', value: 'Beginner'},
                    {name: 'Moderate', value: 'Moderate'},
                    {name: 'Intermediate', value: 'Intermediate'},
                    {name: 'Advanced', value: 'Advanced'},
                    {name: 'Mixed', value: 'Mixed'}
                ],
                duration: [
                    {name: 'All', value: 'all', default: true},
                    {name: '0 - 30 Minutes', value: 'short'},
                    {name: '30 - 60 Minutes', value: 'mid'},
                    {name: '> 60 Minutes', value: 'long'}
                ],
                dateValue: [
                    {name: 'All time', value: 'all', default: true},
                    {name: 'Today', value: 'today'},
                    {name: 'This week', value: 'thisWeek'},
                    {name: 'This month', value: 'thisMonth'},
                    {name: 'Past 3 months', value: 'past3Months'}
                ]
            },
            paramsOptions: {
                duration: {
                    all: {},
                    short: {from: 0, to: 30 * 60},
                    mid: {from: 30 * 60, to: 60 * 60},
                    long: {from: 60 * 60}
                }
            },
            // search data
            query: "",
            sortBy: "new",
            date: {
                start: new Date(),
                end: new Date()
            },
            dateValue: "all",
            classType: ['Session', 'Video', 'Recording'],
            level: [],
            duration: "all",
            choosenMembers: [],
            mbScheduleUid: this.uid(),
            calendarMode: 'hidden',
            accessChannelEdit: [],
            accessChannelArchive: [],
            descriptionIncluded: true
        }
    },
    computed: {
        can_edit_channel() {
            return this.currentUser?.credentialsAbility?.can_edit_channels && this.accessChannelEdit.includes(this.channel.id)
        },
        can_archive_channel() {
            return this.currentUser?.credentialsAbility?.can_archive_channels && this.accessChannelArchive.includes(this.channel.id)
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        filteredMembers() {
            return [this.owner].concat(this.members).filter(user => {
                return user.public_display_name?.toLowerCase().includes(this.searchMembers.toLowerCase())
            })
        },
        editChannelLink() {
            if (this.channel.relative_path) {
                return '/channels/' + encodeURIComponent(this.channel.relative_path.split('/')[2] + '/' + this.channel.relative_path.split('/')[3]) + '/edit'
            } else {
                return null
            }
        },
        editCreatorLink() {
            if (this.channel.relative_path) {
                return '/channels/' + encodeURIComponent(this.channel.relative_path.substring(1)) + '/edit_creators'
            } else {
                return null
            }
        },
        archiveChannelLink() {
            if (this.channel.id) {
                return '/channels/' + this.channel.id + '/archive'
            } else {
                return null
            }
        },
        tags() {
            let fieldToWatch = [
                'sortBy', 'duration', 'dateVale'
            ]
            let arraysToWatch = [
                'level'
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

            if (this.classType.length < 3) {
                this.classType.forEach(ff => {
                    let option = this.options.classType.find(f => f.value === ff)
                    if (!option.default) {
                        tagsList.push({
                            field: 'classType',
                            value: ff,
                            type: 'array',
                            objField: 'value',
                            name: option.name,
                            default: option.default
                        })
                    }
                })
            }

            this.choosenMembers.forEach(e => {
                let member = [this.owner].concat(this.members).find(m => m.id === e)
                if (member) {
                    tagsList.push(
                        {
                            field: "choosenMembers",
                            type: 'array',
                            objField: 'id',
                            value: member.id,
                            name: member.public_display_name
                        }
                    )
                }
            })

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

            return tagsList
        },
        isAllclassTypeChecked() {
            return ['Session', 'Video', 'Recording'].every(elem => this.classType.includes(elem))
        },
        isInvaiteCreatorAvailable() {
            return this.subscription_features?.can_manage_creators
        }
    },
    mounted() {
        this.accessManageChannel()
    },
    methods: {
        accessManageChannel() {
            if (!this.currentUser) return
            User.api().accessManagment({permission_code: 'edit_channel'}).then(res => {
                this.accessChannelEdit = res.response.data.response.map((c) => {
                    return c.id
                })
                User.api().accessManagment({permission_code: 'archive_channel'}).then(res => {
                    this.accessChannelArchive = res.response.data.response.map((c) => {
                        return c.id
                    })
                })
                    .catch(error => {
                        this.$flash(error.response.message)
                    })
            })
                .catch(error => {
                    this.$flash(error.response.message)
                })
        },
        confirmArchive(e) {
            this.optionsChannel = false
            if (confirm('Are you sure you want to archive the channel? This action is nonreversible')) {
                this.optionsChannel = false
                Channel.api().archive({id: this.channel.id}).then(res => {
                    this.$flash("Channel has been archived", "success")
                }).catch(error => {
                    this.$flash("Channel has been archived", "success")
                })
                // return e.preventDefault();
            }
        },
        toggleOptions() {
            this.optionsChannel = !this.optionsChannel
        },
        openFilters() {
            this.show = true
            this.$nextTick(() => {
                document.getElementById("searchField").focus()
            })
        },
        chooseDate(dateStr) {
            this.dateValue = dateStr
            setTimeout(() => { // nextTick doen't work :(
                this.dateValue = dateStr
            }, 100)

            let dateR = {start: null, end: null}

            switch (dateStr) {
                case 'all':
                    dateR.start = null
                    dateR.end = null
                    break
                case 'today':
                    dateR.start = moment().startOf('day').format()
                    dateR.end = moment().endOf('day').format()
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
            if (dateR.start === null && dateR.end === null) {
                this.date.start = null
                this.date.end = null
                return
            }
            this.date.start = new Date(dateR.start)
            this.date.end = new Date(dateR.end)
        },
        apply(showMore = {}) {
            // this.clearSearchList()

            let params = {
                channel_id: this.channel.id
            }

            switch (this.sortBy) {
                case 'new':
                    params['order_by'] = 'listed_at'
                    params['order'] = "desc"
                    break
                case 'views_count':
                    params['order_by'] = 'views_count'
                    params['order'] = "desc"
                    break
                case 'rank':
                    params['order_by'] = 'popularity'
                    params['order'] = "desc"
                    break
            }

            if (!this.descriptionIncluded) {
                params['search_by'] = "title"
            }

            if (this.query !== "")
                params['query'] = this.query
            if (this.classType.length > 0)
                params['searchable_type'] = this.classType.join(",")
            if (this.choosenMembers.length > 0)
                params['user_id'] = this.choosenMembers.join(",")
            if (this.duration !== 'all') {
                params['duration_from'] = this.paramsOptions.duration[this.duration].from
                params['duration_to'] = this.paramsOptions.duration[this.duration].to
            }
            if (this.dateValue !== 'all') {
                params['created_after'] = this.date.start
                params['created_before'] = this.date.end
            }

            this.$emit("updateSearch", params)

            this.show = false
        },
        clearSearchList() {
            this.query = ""
            this.sortBy = "new"
            this.date = {
                start: null,
                end: null
            },
                this.dateValue = "all"
            this.classType = ['Session', 'Video', 'Recording']
            this.level = []
            this.duration = "all"
            this.choosenMembers = []
            this.descriptionIncluded = true

            this.$emit("updateTilesList", [])

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
            }
            if (this.tags.length > 0) {
                this.apply()
            } else {
                this.clearSearchList()
            }
        },
        shareChannel() {
            this.$eventHub.$emit("open-modal:share", {model: this.channel, type: "Channel"})
        },
        setCalendarMode() {
            eventHub.$emit('mb-schedule-set-up-new-size-mode', {
                mbScheduleUid: this.mbScheduleUid,
                sizeMode: 'overlay'
            })
        },
        setIsClassTypeMode(val) {
            this.classType = val ? ['Session', 'Video', 'Recording'] : []
        }
    }
}
</script>