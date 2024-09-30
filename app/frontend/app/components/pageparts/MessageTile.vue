<template>
    <div>
        <div class="MK-messages__wrapper active">
            <div class="logo__l">
                <img
                    :src="message.sender.avatar_url"
                    alt="">
            </div>
            <div class="MK-messages">
                <div>
                    <a
                        @click="goTo(message.sender.relative_path)"
                        @click.middle="goTo(message.sender.relative_path, true)">
                        {{ message.sender.public_display_name }}
                    </a>
                </div>
                <div class="MK-messages__bodyMessage">
                    <a
                        class="padding-r__10 fs__14"
                        @click="emit('openMessageModal', message.id)">
                        {{ message.subject }}
                    </a>
                    <span
                        class="fs__12 display__inline"
                        v-html="message.body" />
                </div>
                <p>
                    <timeago :datetime="message.updated_at" />
                </p>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        message: {
            type: Object
        }
    },
    methods: {
        emit(event, data) {
            this.$emit(event, data)
        }
    }
}
</script>

