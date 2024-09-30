<template>
    <div class="homePage__footer">
        <img
            :src="$img['not_logged_banner']"
            alt="banner"
            class="homePage__footer__img">
        <div class="homePage__footer__wrapper">
            <div class="homePage__footer__title">
                {{ $t('views.home.footer_banner.title') }}
            </div>
            <m-btn
                :type="'tetriary'"
                class="homePage__footer__button"
                @click="openSignUp">
                {{ $t('sign_up.sign_up') }}
            </m-btn>
        </div>
    </div>
</template>

<script>
export default {
    methods: {
        openSignUp() {
            this.$eventHub.$emit("open-modal:auth", "sign-up")
        }
    }
}
</script>