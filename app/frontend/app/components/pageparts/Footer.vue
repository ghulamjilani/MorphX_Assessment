<template>
    <footer
        :class="{pushContentLeft: isMenuOpen}"
        class="footer">
        <div class="footer__top">
            <img
                v-if="!getOrganizationLogo2"
                :src="$img['footerLogo']"
                alt="logo">
            <img
                v-if="getOrganizationLogo2"
                :src="getOrganizationLogo2"
                alt="logo">
            <div class="footer__nav">
                <a
                    v-if="isHome"
                    href="/">{{ $t('footer.home') }}</a>
                <a
                    v-if="pages.support"
                    href="/support">{{ $t('footer.contact_us') }}</a>
                <a
                    v-if="pages.pricing && isPricing"
                    href="/pricing">{{ $t('footer.pricng') }}</a>
                <a
                    v-if="pages.business"
                    href="/business">{{ service_name }} {{ $t('footer.for_business') }}</a>
                <a
                    v-if="pages.influencers"
                    href="/influencers">{{ service_name }} {{
                        $t('footer.for_influencers')
                    }}</a>
                <a
                    v-if="pages.help"
                    href="/pages/help-center">{{ $t('footer.help_center') }}</a>
                <a
                    v-if="isUnite"
                    :href="`https://${getHost}/channels/unite-support-tutorials/unitelivecare`">
                    Support & Tutorials
                </a>
            </div>
        </div>
        <div class="footer__bottom">
            <div>
                <span>
                    © {{ new Date().getFullYear() }} {{ service_name }}.
                    <div
                        v-if="pages.terms_and_privacy"
                        class="termsAndPrivacy">
                        <a href="/pages/terms-of-use" target="_blank">{{ $t('footer.terms_of_use') }}</a>
                        |
                        <a href="/pages/privacy-policy" target="_blank">{{ $t('footer.privacy_police') }}</a>
                    </div>
                </span>
            </div>
            <a
                v-if="$t('views.home.banner.telegram_link') != 'views.home.banner.telegram_link'"
                v-tooltip="{ content: $device.mobile() ? '' : 'Join us on telegram', classes: ['homePage__telegram__tooltip'] }"
                class="homePage__telegram__wrapper"
                :href="$t('views.home.banner.telegram_link')"
                target="_blank">
                <span
                    class="homePage__telegram">
                    <m-icon
                        size="1.4rem">
                        GlobalIcon-telegram-vector
                    </m-icon>
                </span>
            </a>
            <!-- <nav class="hidden">
                <a>
                    <i class="GlobalIcon-twitter fs-20" />
                </a>
                <a>
                    <i class="GlobalIcon-facebook fs-20" />
                </a>
                <a>
                    <i class="GlobalIcon-google fs-20" />
                </a>
                <a>
                    <i class="GlobalIcon-linkedin fs-20" />
                </a>
            </nav> -->
        </div>
    </footer>
</template>

<script>
import eventHub from "@helpers/eventHub.js"

export default {
    data() {
        return {
            pages: {},
            service_name: "",
            isMenuOpen: false,
            organizationLogo: null
        }
    },
    computed: {
        pageOrganization() {
            return this.$store.getters["Users/pageOrganization"]
        },
        isHome() {
            let notHome = ["MainPage", "SandboxDev", "Discover"]
            return !notHome.includes(this.$route.name)
        },
        getOrganizationLogo2() {
            let blackListByPart = ["/pages"]
            if(blackListByPart.some(p => location.pathname.includes(p))) return null

            if (this.pageOrganization) return this.pageOrganization.custom_logo_url
            if (this.$route.matched.find(e => e.name === "dashboard")) return this.organizationLogo
            if (location.pathname.includes("/dashboard/") && this.organizationLogo !== '') return this.organizationLogo
            // for video pages
            let blackList = ["/", "/landing", "/pricing"]
            let blackListPart = ["/users/"]
            if (!blackList.includes(location.pathname) &&
                !blackListPart.find(e => location.pathname.includes(e)) &&
                this.organizationLogo !== '') {
                return this.organizationLogo
            }
            return null
        },
        isPricing() {
            return this.$railsConfig.global.service_subscriptions?.enabled
        },
        isUnite() {
            return this.$railsConfig.global.project_name.toLowerCase() === "unite"
        },
        getHost() {
            return this.$railsConfig?.global?.host
        }
    },
    mounted() {
        eventHub.$on("isMobileMenuSwitched", (isMenuOpen) => {
            this.isMenuOpen = isMenuOpen
        })
        this.pages = this.$railsConfig.global.pages
        this.service_name = this.$railsConfig.global.service_name
        if (window.loadedOrganizationLogo !== '') {
            this.organizationLogo = window.loadedOrganizationLogo
        }
    }
}
</script>
