<template>
    <div
        v-if="active"
        class="client__header__info__exit__modal__wrapper userinroom">
        <div
            v-if="!$device.mobile() && active"
            class="channelFilters__icons__options__cover client__header__cover" />
        <div class="client__header__info__exit__modal">
            <div>
                <div class="client__header__info__exit__modal__text">
                    Your account already in room
                </div>
                <div class="client__header__info__exit__modal__buttons">
                    <m-btn
                        type="secondary"
                        @click="close">
                        Leave Session
                    </m-btn>
                    <m-btn
                        type="save"
                        @click="closeModal">
                        Ok, close other
                    </m-btn>
                </div>
            </div>
        </div>
    </div>
</template>

<script>

export default {
    name: "UserAlreadyInRoom",
    props: {
        active: Boolean
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
            window.onbeforeunload = null
            window.opener = self
            window.close()
            location.href = location.origin
        },
        closeModal() {
            this.$emit("initThis")
        }
    }
}
</script>