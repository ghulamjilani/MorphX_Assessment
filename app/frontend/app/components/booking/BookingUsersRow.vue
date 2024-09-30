<template>
    <div
        v-if="filteredUsers.length > 0"
        class="bookingUserRow"
        :class="{'sessionPage': textMode == 'session'}">
        <div class="bookingUserRow__text">
            {{ text[textMode] }}
        </div>
        <div class="bookingUserRow__avatars">
            <div
                v-for="user in filteredUsers"
                :key="user.id"
                class="bookingUserRow__avatar">
                <m-avatar
                    size="sl"
                    star-size="xxl"
                    :src="user.avatar_url"
                    :can-book="user.has_booking_slots"
                    @click="openUserModal(user)" />
                <div class="bookingUserRow__avatar__name">
                    {{ user.public_display_name ? user.public_display_name : user.display_name }}
                </div>
                <m-btn
                    type="solid"
					size="m"
                    @click="openUserModal(user, true)">
                    Book Me
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        users: {
            type: Array,
            required: true
        },
        // default, sessions
        textMode: {
            type: String,
            default: "default"
        }
    },
    data() {
        return {
            text: {
                default: "Book this creator now for a private video conference",
                session: "Book this creator now for a private video conference"
            }
        }
    },
    computed: {
        filteredUsers() {
            return this.users.filter(user => user.has_booking_slots)
        }
    },
    methods: {
        openUserModal(user, bookMe = false) {
            this.$eventHub.$emit("open-modal:userinfo", {
                notFull: true,
                model: user
            })
            if(bookMe) {
                this.$nextTick(() => {
                    this.$eventHub.$emit("toggle-booking", true)
                })
            }
        }
    }
}
</script>

<style>

</style>