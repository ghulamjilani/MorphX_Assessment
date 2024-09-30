<template>
    <div class="MK-notification__wrapper active">
        <div class="logo__l">
            <img
                v-if="notification.sender.avatar"
                :src="notification.sender.avatar"
                alt="">
            <img
                v-if="!notification.sender.avatar"
                :src="$img['favicon']"
                alt="">
        </div>
        <div class="MK-notification">
            <a href="#">{{ notification.sender.name }}</a>
            <div
                class="MK-notification__body"
                v-html="notification.body" />
            <p>
                <timeago :datetime="notification.created_at" />
            </p>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        notification: {
            type: Object
        }
    }
}
</script>
