<template>
    <m-modal
        ref="authModal"
        :backdrop="options.backdrop"
        :close="options.close">
        <template #header>
            <img
                :src="$img[logo_size]"
                alt="logo"
                :class="[project_name, {'default' : config_logo_size === 'default'}]">
        </template>
        <login-template
            v-if="mode === 'login'"
            :after-sign-action="afterSignAction"
            :guest="options.guest && guestEnabled"
            :sign-up-prop="sign_up"
            :social-login-prop="social_login"
            @change="onChangeTemplate"
            @close="close" />
        <signup-template
            v-if="mode === 'sign-up'"
            :after-sign-action="afterSignAction"
            :guest="options.guest && guestEnabled"
            :service-name="service_name"
            :social-login-prop="social_login"
            :default-mode="options.mode"
            @change="onChangeTemplate"
            @close="close" />
        <remember-template
            v-if="mode === 'remember'"
            @change="onChangeTemplate"
            @close="close" />
        <guest-template
            v-if="mode === 'guest'"
            :after-sign-action="afterSignAction"
            @change="onChangeTemplate"
            @close="close"
            @guestEnabled="(flag) => {guestEnabled = flag}" />
        <more-info-template
            v-if="mode === 'more-info'"
            @close="close" />
    </m-modal>
</template>

<script>
import LoginTemplate from './template/LoginTemplate'
import SignupTemplate from './template/SignupTemplate.vue'
import RememberTemplate from './template/RememberTemplate'
import GuestTemplate from './template/GuestTemplate.vue'
import MoreInfoTemplate from './template/MoreInfoTemplate.vue'

export default {
    components: {LoginTemplate, SignupTemplate, RememberTemplate, GuestTemplate, MoreInfoTemplate},
    data() {
        return {
            mode: "login", // sign-up, remember
            sign_up: null,
            social_login: null,
            service_name: "Morphx",
            project_name: "morphx",
            afterSignAction: {action: 'default'},
            options: {
                backdrop: true,
                close: true,
                guest: false
            },
            guestEnabled: false,
            config_logo_size: 'small'
        }
    },
    computed: {
        logo_size() {
            return this.config_logo_size === 'default' ? 'logo' : ('logo_' + this.config_logo_size)
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.sign_up = this.$railsConfig.global.sign_up.enabled
        this.social_login = this.$railsConfig.global.socials.log_in
        this.service_name = this.$railsConfig.global.service_name
        this.project_name = this.$railsConfig.global.project_name
        this.config_logo_size = this.$railsConfig.frontend.logo_size

        this.$eventHub.$on("open-modal:auth", (mode = "login", afterSignAction = {action: 'default'}, settings) => {
            if (afterSignAction === null) afterSignAction = {action: 'default'} // skip and set settings
            this.options = {...this.modalOptions, ...settings}
            this.afterSignAction = afterSignAction

            if(this.currentUser && this.afterSignAction.action === 'redirect-to-wizard') {
                this.close()
                location.href = location.origin + '/wizard/business'
            }

            if(mode === "more-info") {
                if(this.currentUser && (!this.currentUser.email || this.currentUser.email == "")) {
                    this.open(mode)
                }
            }
            else {
                this.open(mode)
            }
        })
        this.$eventHub.$on("close-modal:all", () => {
            this.close()
        })
        this.$eventHub.$on("close-modal:auth", () => {
            this.close()
        })
    },
    methods: {
        open(mode = "login") {
            this.mode = mode
            if (this.$refs.authModal) {
                this.$refs.authModal.openModal()
            }
        },
        close() {
            if (this.$refs.authModal) {
                this.$refs.authModal.closeModal()
            }
        },
        onChangeTemplate(mode) {
            this.mode = mode
        },
        toggleMode() {
            if (this.mode === "with-email") this.mode = "with-social"
            else this.mode = "with-email"
        }
    }
}
</script>