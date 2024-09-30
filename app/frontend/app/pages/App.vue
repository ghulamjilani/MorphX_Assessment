<template>
    <div
        :class="{'headerTop': !isScrolled, 'vc': !isStandartHeaded && !ome}"
        class="vue-app">
        <!-- <m-flash-message :blockMessage="isStandartHeaded ? true : false" ref="flash" /> -->
        <Header v-if="isStandartHeaded" />
        <header-client v-show="!isStandartHeaded && showHeaderClient" />
        <auth-modal
            v-if="!isStandartHeaded"
            class="loginSignUPForgotPassModals" />
        <router-view
            :class="{pushContentLeft: isMenuOpen}"
            class="pageComponent" />
        <Footer v-if="isStandartHeaded" />
        <!-- list of global modals -->
        <div
            v-if="showCover"
            class="pageCover"
            @click="closePageCover" />
        <custom-theme-panel v-show="showCustomization" />
        <ModalGeneral />
    </div>
</template>

<script>
import Header from "./../components/pageparts/Header"
import Footer from "./../components/pageparts/Footer"
import CustomThemePanel from "./../components/pageparts/CustomThemePanel"
import eventHub from "@helpers/eventHub.js"
import AuthModal from '@components/modals/AuthModal'
import HeaderClient from './video-client/HeaderClient.vue'
import Channel from "@models/Channel"
import ModalGeneral from '@components/modals/General'


export default {
    components: {
        Header,
        Footer,
        CustomThemePanel,
        AuthModal,
        HeaderClient,
        ModalGeneral
    },
    data() {
        return {
            isScrolled: false,
            isMenuOpen: false,
            showCover: false,
            organizationBlogChannel: null,
            organization: null,
            logo_link: '/',
            showCustomization: false,
            data_priority: {
                start_at: null,
                priority: 0,
                count: 0
            },
            showHeaderClient: false
        }
    },
    computed: {
        isStandartHeaded() {
            // let notHeaded = ["room", "SandboxDev"]
            let notHeaded = ["JoinRoom", "Room", "ome"]
            return !notHeaded.includes(this.$route.name)
        },
        ome() {
            return this.$route.name == 'ome'
        },
        currentOrganization() {
            return this.$store.getters["Users/currentOrganization"]
        }
    },
    watch: {
        currentOrganization: {
            handler(val) {
                if (val) {
                    this.getCustomCompany()
                }
            }
        }
    },
    created() {
        this.$eventHub.$on("reset-priority", () => {
            this.data_priority.count = 0
            this.data_priority.start_at = null
            this.data_priority.priority = 0
        })
        this.$eventHub.$on("check-priority", (count) => {
            this.data_priority.priority++
            this.data_priority.count += count
            if (!this.data_priority.start_at) this.data_priority.start_at = new Date().getTime()
            var time = new Date().getTime() - this.data_priority.start_at
            if (time < 1000 && this.data_priority.count >= 12) {
                this.data_priority.count = 0
                this.data_priority.start_at = null
                setTimeout(() => {
                    this.$eventHub.$emit('priority', this.data_priority.priority)
                }, 1100 - time)
            } else {
                this.$eventHub.$emit('priority', this.data_priority.priority)
            }
        })
    },
    mounted() {
        this.$eventHub.$emit("logo-channel-link", this.logo_link)
        eventHub.$on("isMobileMenuSwitched", (isMenuOpen) => {
            this.isMenuOpen = isMenuOpen
        })
        window.addEventListener('scroll', () => {
            this.isScrolled = window.scrollY > 0
        })
        this.$eventHub.$on("toggle-pageCover", (flag = undefined) => {
            if (flag === undefined) {
                this.showCover = !this.showCover
            } else {
                this.showCover = flag
            }
        })
        this.$eventHub.$on("close-modal:all", () => {
            this.showCover = false
        })

        this.$eventHub.$on("showHeaderClient", () => {
            this.showHeaderClient = true
        })

        this.organizationBlogChannel = initOrganizationBlogChannel(0)
        this.organizationBlogChannel.bind(organizationBlogChannelEvents.postLikesCountUpdated, (data) => {
            this.$eventHub.$emit(organizationBlogChannelEvents.postLikesCountUpdated, data)
        })

        // get current user
        // User.api().currentUser().then(res => {
        //   this.$store.dispatch("Users/setCurrents", res.response.data.response)
        // }).catch(err => {
        //   let refresh = getCookie('_unite_session_jwt_refresh')
        //   if(refresh) {
        //     User.api().getTokens({ refresh }).then(refreshRes => {
        //       updateCookiesFromJwtResponse(refreshRes?.response)
        //       User.api().currentUser().then(ures => {
        //         this.$store.dispatch("Users/setCurrents", ures?.response?.data?.response)
        //       })
        //     })
        //   }
        // })

        if (window.flash_messages) {
            window.flash_messages.forEach(message => {
                this.$flash(message.value, message.type)
            })
        }

        this.$eventHub.$on("open-customization", () => {
            this.showCustomization = !this.showCustomization
            if (!this.showCustomization) {
                document.body.classList.remove("customizationOpen")
            } else {
                document.body.classList.add("customizationOpen")
            }
        })
    },
    methods: {
        closePageCover() {
            this.$eventHub.$emit("close-modal:all")
            this.showCover = false
        },
        getCustomCompany() {
            Channel.api().getPublicOrganization({id: this.currentOrganization.id}).then((res) => {
                this.organization = res.response.data.response.organization
                if (this.organization.custom_css) {
                    document.querySelector("#organization_custom_css").innerHTML = `:root {
            ${this.organization.custom_css}
          }`
                } else if (document.querySelector("#organization_custom_css")) {
                    document.querySelector("#organization_custom_css").innerHTML = `:root { }`
                }
            })
        }
    }
}
</script>
