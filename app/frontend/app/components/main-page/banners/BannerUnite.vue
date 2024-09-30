<template>
    <section class="banner">
        <div class="banner__sky"></div>
        <div ref="dawn" class="banner__dawn"></div>
        <img
            :src="$img['unite_banner']"
            alt="banner"
            class="banner__image">
        <div class="banner__fog"></div>
        <div class="banner__center">
            <h1 class="banner__title">{{ $t('frontend.app.components.main_page.banner_unite.title') }}</h1>
            <p class="banner__text">{{ $t('frontend.app.components.main_page.banner_unite.text', {service_name: $railsConfig.global.service_name}) }}</p>
            <m-btn
                v-if="!currentUser"
                class="banner__btn"
                @click="openSignUp">
                {{ $t('frontend.app.components.main_page.banner_unite.register_today') }}
            </m-btn>
        </div>
    </section>
</template>

<script>
export default {
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        setTimeout(() => {
            this.$refs['dawn'].classList.add('dawn')
        }, 1000)
    },
    methods: {
        openSignUp() {
            this.$eventHub.$emit("open-modal:auth", "sign-up")
        }
    }
}
</script>

<style lang="scss" scoped>
@import "../../../../../assets/stylesheets/mixin.scss";

.banner {
    width: 125rem;
    max-width: 96%;
    min-height: 50rem;
    @include flex(flex, center, fex-start);
    margin: 3rem auto 0 auto;
    position: relative;
    color: #fff;
    overflow: hidden;
    @include media(tablet){
        margin-top: 0;
    }
    @include media(phone){
        min-height: auto;
    }

    &__sky,
    &__dawn,
    &__image,
    &__fog {
        width: 100%;
        height: 100%;
        position: absolute;
        top: 0;
        left: 0;
    }

    &__sky {
        background:
            linear-gradient(rgb(18, 79, 161) 20%, rgba(18, 79, 161, .2) 80%),
            linear-gradient(90deg, rgba(18, 79, 161, .2), rgb(234, 132, 12));
    }

    &__dawn {
        background: linear-gradient(transparent, rgb(234, 132, 12));
        opacity: 0;
        transition: opacity 2s linear;
        &.dawn {
            opacity: 1;
        }
    }

    &__image {
        opacity: .9;
        object-fit: cover;
    }

    &__fog {
        background: linear-gradient(90deg, rgba(18, 79, 161, .4), rgba(234, 132, 12, .2));
    }

    &__center {
        width: 100%;
        position: relative;
        padding: 4rem;
        @include media(p-tablet){
            padding: 2rem;
        }
        @include media(phone){
            padding: 1rem;
        }
    }

    &__title {
        max-width: 55%;
        font-size: 4.8rem;
        font-weight: bold;
        color: #fff;
        margin: 2rem 0;
        @include media(tablet){
            font-size: 3.6rem;
        }
        @include media(phone){
            max-width: none;
        }
    }

    &__text {
        max-width: 40rem;
        font-size: 1.8rem;
        margin: 0 0 4rem 0;
        @include media(phone){
            max-width: none;
        }
    }

    &__btn {
        min-width: 14rem;
        min-height: 4rem;
        font-size: 1.4rem;
        border: none;
        background-color: #E59500;
    }
}
</style>