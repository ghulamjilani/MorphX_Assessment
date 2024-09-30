<template>
    <!-- customizableBanner -->
    <div
        :style="{'background-image': backgroundImage !== '' && backgroundVideoLink == '' ? 'url(' + backgroundImage + ')' : ''}"
        class="customizableBanner">
        <div
            v-if="backgroundVideoLink && backgroundVideoLink !== ''"
            class="videoBanner">
            <video
                ref="video"
                autoplay="true"
                loop="true"
                muted="muted"
                playsinline
                :src="backgroundVideoLink"
                type="video/mp4" />
        </div>
        <div
            v-if="backgroundVideoLink && backgroundVideoLink !== ''"
            class="videoBanner__toggleSound">
            <m-icon
                size="2rem"
                :name="muted ? 'GlobalIcon-Sound-off':'GlobalIcon-Sound-on'"
                @click="toggleSound" />
        </div>
        <!-- <img
            :src="$img['not_logged_banner']"
            alt="banner"
            class="homePage__footer__img"> -->
        <!-- <div class="homePage__footer__wrapper"> -->
        <div
            class="customizableBanner__text"
            v-html="rawHtml" />
        <m-btn
            v-if="!hideButton"
            :type="buttonType"
            class="customizableBanner__button"
            @click="buttonClick">
            {{ buttonText }}
        </m-btn>
        <!-- </div> -->
    </div>
</template>

<script>
export default {
    props: {
        img: {
            type: Object,
            // default: () => {return this.$img['not_logged_banner']}
        },
        rawHtml: {
            type: String,
            default: ""
        },
        buttonText: {
            type: String,
            default: ""
        },
        buttonType: {
            type: String,
            default: "tetriary"
        },
        buttonAction: {
            type: String,
            default: "signUp"
        },
        buttonLink: {
            type: String,
            default: ""
        },
        backgroundImage: {
            type: String,
            default: ""
        },
        backgroundVideoLink: {
            type: String,
            default: ""
        }
    },
    data() {
        return {
            muted: true
        }
    },
    computed: {
        hideButton() {
            return this.buttonText === "" ||
                this.buttonType === 'buttonless' ||
                (this.buttonAction === 'link' && this.buttonLink === '')
        }
    },
    methods: {
        buttonClick() {
            switch (this.buttonAction) {
                case "signUp":
                    this.$eventHub.$emit("open-modal:auth", "sign-up")
                    break;

                case "login":
                    this.$eventHub.$emit("open-modal:auth", "login")
                    break;

                case "link":
                    if(this.buttonLink !== '') {
                        this.goTo(this.buttonLink, true)
                    }
                    break;

                default:
                    break;
            }
        },
        toggleSound() {
            this.muted = !this.muted
            if(this.$refs.video) {
                this.$refs.video.muted = this.muted
            }
        }
    }
}
</script>