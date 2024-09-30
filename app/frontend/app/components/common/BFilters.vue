<template>
    <div
        :class="{'channelFilters__active': show}"
        class="channelFilters blogFilters">
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
                <b>{{ modelType }} type</b>
            </div>
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
                <!-- <div class="channelFilters__filters__wrapper">
          <b>Sort By</b>
          <div class="channelFilters__filters__checkmarks">
            <m-radio v-for="option in options.sortBy" v-model="sortBy"
              :key="option.value" :val="option.value" >{{option.name}}</m-radio>
          </div>
        </div> -->
                <!-- <div class="channelFilters__filters__wrapper">
          <b>Creator</b>
          <div>
            <m-input v-model="searchMembers" name="searchMembers" pure borderless :errors="false" class="channelFilters__filters__input" placeholder="Enter name..." type="text"></m-input>
          </div>
          <div class="channelFilters__filters__checkmarks">
            <m-checkbox
              v-for="member in filteredMembers" :key="member.id"
              :val="member.id"
              v-model="choosenMembers"
            >{{member.public_display_name}}</m-checkbox>
          </div>
        </div> -->
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

export default {
    directives: {
        ClickOutside
    },
    props: {
        members: {},
        modelType: {
            type: String,
            default: "Session"
        }
    },
    data() {
        return {
            optionsChannel: false,
            show: false,
            searchMembers: "",
            options: {
                classType: [
                    {name: 'All', value: 'all'},
                    {name: 'Published', value: 'published'},
                    {name: 'Draft', value: 'draft'},
                    {name: 'Hidden', value: 'hidden'},
                    {name: 'Archived', value: 'archived'}
                ],
                dateValue: [
                    {name: 'All time', value: 'all', default: true},
                    {name: 'Today', value: 'today'},
                    {name: 'This week', value: 'thisWeek'},
                    {name: 'This month', value: 'thisMonth'},
                    {name: 'Past 3 months', value: 'past3Months'}
                ]
            },
            paramsOptions: {},
            // search data
            // query: "",
            sortBy: 'new',
            date: {
                start: new Date(),
                end: new Date()
            },
            dateValue: "all",
            classType: 'all',
            duration: "all",
            choosenMembers: []
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        filteredMembers() {
            return this.members.filter(user => {
                return user.public_display_name.toLowerCase().includes(this.searchMembers.toLowerCase())
            })
        },
        tags() {
            let fieldToWatch = [
                'dateVale'
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

            // if(this.classType.length < 3) {
            //   this.classType.forEach(ff => {
            //     let option = this.options.classType.find(f => f.value === ff)
            //     if(!option.default) {
            //       tagsList.push({
            //         field: 'classType',
            //         value: ff,
            //         type: 'array',
            //         objField: 'value',
            //         name: option.name,
            //         default: option.default
            //       })
            //     }
            //   })
            // }

            this.choosenMembers.forEach(e => {
                let member = this.members.find(m => m.id === e)
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
    methods: {
        openFilters() {
            this.show = true
        },
        toggleFilters() {
            this.show = !this.show
        },
        chooseDate(dateStr) {
            this.dateValue = dateStr

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

            this.date.start = new Date(dateR.start)
            this.date.end = new Date(dateR.end)
        },
        apply(showMore = {}) {
            // this.clearSearchList()

            let params = {}

            // switch(this.sortBy) {
            //   case 'new':
            //     params['order_by'] = 'created_at'
            //     params['order'] = "desc"
            //     break
            //   case 'views_count':
            //     params['order_by'] = 'views_count'
            //     params['order'] = "desc"
            //     break
            //   case 'rank':
            //     params['order_by'] = 'popularity'
            //     params['order'] = "desc"
            //     break
            // }

            // if(this.query!== "")
            //   params['query'] = this.query
            if (this.classType !== "all")
                params['status'] = this.classType
            if (this.choosenMembers.length > 0)
                params['user_id'] = this.choosenMembers.join(",")
            if (this.dateValue !== 'all') {
                params['created_after'] = this.date.start
                params['created_before'] = this.date.end
            }

            this.$emit("updateSearch", params)

            this.show = false
        },
        clearSearchList() {
            // this.query = ""
            this.sortBy = "new"
            this.date = {
                start: null,
                end: null
            },
                this.dateValue = "all"
            this.classType = 'all'
            // this.level = []
            // this.duration = "all"
            this.choosenMembers = []

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