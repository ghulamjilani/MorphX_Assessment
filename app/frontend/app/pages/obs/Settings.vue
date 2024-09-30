<template>
    <div class="RTMP__settings">
        <span
            class="GlobalIcon-clear MK2-modal__close"
            @click="closeSetting()" />
        <div class="RTMP__settings__row">
            <div class="RTMP__settings__name">
                Server:
            </div>
            <div class="RTMP__settings__value">
                {{ ffmpegservice_account.server }}
            </div>
            <div class="RTMP__settings__copy__wrapper">
                <m-btn
                    :type="'tetriary'"
                    class="RTMP__settings__copy"
                    @click="copy(ffmpegservice_account.server)">
                    Copy
                </m-btn>
            </div>
        </div>
        <div class="RTMP__settings__row">
            <div class="RTMP__settings__name">
                Port:
            </div>
            <div class="RTMP__settings__value">
                {{ ffmpegservice_account.port }}
            </div>
            <div class="RTMP__settings__copy__wrapper">
                <m-btn
                    :type="'tetriary'"
                    class="RTMP__settings__copy"
                    @click="copy(ffmpegservice_account.port)">
                    Copy
                </m-btn>
            </div>
        </div>
        <div class="RTMP__settings__row">
            <div class="RTMP__settings__name">
                Stream key:
            </div>
            <div class="RTMP__settings__value">
                {{ ffmpegservice_account.stream_name }}
            </div>
            <div class="RTMP__settings__copy__wrapper">
                <m-btn
                    :type="'tetriary'"
                    class="RTMP__settings__copy"
                    @click="copy(ffmpegservice_account.stream_name)">
                    Copy
                </m-btn>
            </div>
        </div>
        <div class="RTMP__settings__row">
            <div class="RTMP__settings__name">
                User name:
            </div>
            <div class="RTMP__settings__value">
                {{ ffmpegservice_account.username }}
            </div>
            <div class="RTMP__settings__copy__wrapper">
                <m-btn
                    :type="'tetriary'"
                    class="RTMP__settings__copy"
                    @click="copy(ffmpegservice_account.username)">
                    Copy
                </m-btn>
            </div>
        </div>
        <div class="RTMP__settings__row">
            <div class="RTMP__settings__name">
                Password:
            </div>
            <div class="RTMP__settings__value">
                {{ ffmpegservice_account.password }}
            </div>
            <div class="RTMP__settings__copy__wrapper">
                <m-btn
                    :type="'tetriary'"
                    class="RTMP__settings__copy"
                    @click="copy(ffmpegservice_account.password)">
                    Copy
                </m-btn>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        ffmpegservice_account: Object
    },
    methods: {
        copy(value) {
            this.$clipboard(value)
            this.$flash("Сopied!", "success")
        },
        closeSetting() {
            this.$eventHub.$emit('rtmp-closeSetting')
        }
    }
}
</script>