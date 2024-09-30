<template>
    <div class="infoCards">
        <div class="infoCards__PageTitle">
            User Management
        </div>
        <div class="infoCards__Wrapper">
            <roles-info-card
                v-for="infocard in infoCards"
                :key="infocard.id"
                :info="infocard" />
        </div>
    </div>
</template>

<script>
import RolesInfoCard from "./RolesInfoCard"
import Groups from "@models/Groups"

export default {
    components: {RolesInfoCard},
    props: {
        allMembersCount: Number
    },
    data() {
        return {
            infoCards: [
                {
                    id: 1,
                    count: 0,
                    title: 'All Users',
                    actionTitle: 'MANAGE',
                    img: 'RS__1',
                    type: 'allUsers'
                },
                // {
                //   id: 2,
                //   count: 0,
                //   title: 'Creators',
                //   actionTitle: 'MANAGE',
                //   img: 'RS__2',
                //   type: 'creators'
                // },
                // {
                //   id: 3,
                //   count: 0,
                //   title: 'Admins',
                //   actionTitle: 'MANAGE',
                //   img: 'RS__3',
                //   type: 'admins'
                // },
                {
                    id: 4,
                    count: 0,
                    title: 'Roles',
                    actionTitle: 'MANAGE',
                    img: 'RS__4',
                    type: 'groups'
                }
            ]
        }
    },
    computed: {
        groupsCount() {
            return Groups.query().get().length
        }
    },
    watch: {
        allMembersCount: {
            handler(val) {
                if (val) {
                    let allMembersCount = this.infoCards.find(ic => ic.type == 'allUsers')
                    if (allMembersCount) {
                        allMembersCount.count = val
                    }
                }
            },
            deep: true,
            immediate: true
        },
        groupsCount: {
            handler(val) {
                if (val) {
                    let groupsInfoCard = this.infoCards.find(ic => ic.type == 'groups')
                    if (groupsInfoCard) {
                        groupsInfoCard.count = val
                    }
                }
            },
            deep: true,
            immediate: true
        }
    }
}
</script>