<template>
    <div class="cardMK2__tile-body">
        <div
            class="fs__16 text__bold display-block cursor-pointer cardMK2__tile-body__title"
            href="#"
            @click="goTo(sessionsParams.relative_path)"
            @click.middle="goTo(sessionsParams.relative_path, true)">
            {{ sessionsParams.title }}
        </div>
        <div
            v-if="showOrganization"
            class="orgSection">
            <div
                class="orgSection__img"
                :style="`background-image: url(${organization.logo_url})`"
                @click="goToDefaultChannel()" />
            <div class="orgSection__text">
                <p @click="openUserModal()">
                    {{ $t('session_tile.by') }} {{ presenterUser.public_display_name }}
                </p>
                <p @click="goToDefaultChannel()">
                    {{ organization.name }}
                </p>
            </div>
        </div>
        <div
            v-else
            class="fs__14 display-block cursor-pointer"
            href="#"
            @click="goTo('/users' + presenterUser.relative_path)"
            @click.middle="goTo('/users' + presenterUser.relative_path, true)">
            By {{ presenterUser.public_display_name }}
        </div>
        <div v-if="sessionsParams.start_now">
            <span class="fs__14">Started {{ startedDate }} ago</span>
        </div>
        <div v-else>
            <span class="fs__14">Scheduled for {{ formattedDate }}</span>
        </div>
        <div
            v-if="!isOwner && (sessionsParams.join_as_participant || sessionsParams.join_as_livestreamer && sessionsParams.livestream_purchase_price > 0)"
            class="cardMK2__ratingAndViews">
            <div class="cardMK2__ratingAndViews__status cardMK2__ratingAndViews__status__marginless">
                <span
                    v-if="sessionsParams.access_as_subscriber"
                    class="statusSubscription">Subscribed</span>
                <span
                    v-else
                    class="statusPurchased">Purchased</span>
            </div>
        </div>
    </div>
</template>

<script>
import utils from '@helpers/utils'
export default {
    props: {
        video: {},
        showOrganization: Boolean
    },
    data() {
        return {
            currentTime: null
        }
    },
    computed: {
        sessionsParams() {
            return this.video?.session || this.video
        },
        organization() {
            return this.video?.organization
        },
        presenterUser() {
            return this.video?.presenter_user || this.video?.user
        },
        isOwner() {
            return this.currentUser?.id == this.presenterUser?.id
        },
        formattedDate() {
            let dt = this.sessionsParams.start_at
            let date = this.currentUser && this.currentUser.timezone ?
                moment(dt).tz(this.currentUser.timezone) : moment(dt)
            let format = ''
            format = 'ddd, '
            format += this.currentUser && this.currentUser.am_format ? 'MMM D h:mm A' : 'MMM D H:mm'

            return date.format(format)
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        startedDate() {
            let dt = this.sessionsParams.start_at
            let date = this.currentUser && this.currentUser.timezone ?
                moment(dt).tz(this.currentUser.timezone) : moment(dt)
            date = this.currentTime - date.valueOf()
            let tempTime = moment.duration(date)
            return tempTime.hours() > 0 ?  `${tempTime.hours()} h.` : `${tempTime.minutes()} min.`
        }
    },
    mounted() {
        this.currentTime = utils.dateToTimeZone(moment(), true).valueOf()
        setInterval(() => {
            this.currentTime = utils.dateToTimeZone(moment(), true).valueOf()
        }, 5000)
    },
    methods: {
        goToDefaultChannel(){
            this.goTo(location.origin + this.video.channel.relative_path)
        },
        openUserModal() {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: this.presenterUser
            })
        }
    }
}
</script>