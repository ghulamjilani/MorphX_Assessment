<template lang="html">
    <component
        :is="data.component"
        v-bind="data.props" />
</template>

<script>
import Channel from '@components/Channel'
import StatisticsContainer from '@components/statistics/StatisticsContainer'
import StudiosContainer from "@components/multiroom/StudiosContainer"
import VideoSourcesContainer from "@components/multiroom/VideoSourcesContainer"
import Contacts from "@components/Contacts"
import History from "../pages/History"
import NewPost from "../components/blog/NewPost"
import ManagePost from "../components/blog/ManagePost"
import BusinessPlan from "../pages/business/BusinessPlan"
import ModalForm from "./modals/CIS/ModalForm"
import DashboardFollow from "./DashboardFollow"
import Tips from '@components/tips/Tips'
import InfoIcon from '@components/tips/InfoIcon'
import Header from '@components/pageparts/Header.vue'
import Reviews from '@components/channel/Reviews.vue'
import ReviewsCommentsSection from '@components/channel/ReviewsCommentsSection.vue'
import User from '@models/User'
import ChatWrapper from '@components/pageparts/chat/ChatWrapper'
import SideBar from '@components/dashboard/SideBar'
import MopsShowController from '@components/mops/MopsShowController.vue'
import BookingUsersRow from "@components/booking/BookingUsersRow"

export default {
    name: 'CompWrapper',
    components: {
        Channel,
        StatisticsContainer,
        StudiosContainer,
        VideoSourcesContainer,
        Contacts,
        History,
        NewPost,
        ManagePost,
        BusinessPlan,
        ModalForm,
        DashboardFollow,
        Tips,
        InfoIcon,
        Header,
        Reviews,
        ReviewsCommentsSection,
        ChatWrapper,
        SideBar,
        MopsShowController,
        BookingUsersRow
    },
    data() {
        return {data: {}}
    },
    mounted() {
        this.addHeaderTopClass()
    },
    async created() {
        this.data = await JSON.parse(this.$attrs.data)
        // get current user from rails view as prop
        if (this.data?.props?.user) {
            User.insertOrUpdate({
                data: [
                    this.data.props.user
                ]
            })
        }
    },
    methods: {
        addHeaderTopClass() {
            let bodyTag = document.body
            bodyTag.classList.add('header-top')
        }
    }
}
</script>