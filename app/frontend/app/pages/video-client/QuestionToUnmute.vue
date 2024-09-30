<template>
    <div
        v-if="active"
        class="client__header__info__exit__modal__wrapper asktounmute">
        <div class="client__header__info__exit__modal">
            <div>
                <div
                    v-if="type === 'audio'"
                    class="client__header__info__exit__modal__text">
                    {{ $t('video_client.question_to_unmute.ask_unmute_microphone') }}
                </div>
                <div
                    v-else
                    class="client__header__info__exit__modal__text">
                    {{ $t('video_client.question_to_unmute.ask_start_video') }}
                </div>
                <div class="client__header__info__exit__modal__buttons">
                    <m-btn
                        type="secondary"
                        @click="close">
                        No
                    </m-btn>
                    <m-btn
                        type="save"
                        @click="unmute">
                        {{
                            type === 'audio' ? $t('video_client.question_to_unmute.unmute') :
                            $t('video_client.question_to_unmute.enable')
                        }}
                    </m-btn>
                </div>
            </div>
        </div>
    </div>
</template>

<script>

export default {
    name: "QuestionToUnmute",
    props: {
        active: Boolean,
        type: String
    },
    data() {
        return {}
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        isPresenter() {
            return this.roomInfo?.presenter_user?.id === this.currentUser?.id
        }
    },
    methods: {
        close() {
            this.$emit("close")
        },
        unmute() {
            this.$eventHub.$emit("tw-unmute", this.type)
            this.$emit("close")
        }
    }
}
</script>