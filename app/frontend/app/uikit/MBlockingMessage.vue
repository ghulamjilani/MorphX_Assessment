<template>
    <div
        v-if="currentUser && currentBlockingMessage"
        key="infinite">
        <div class="flash__container__alert flash__container__infinite flash__info flash__info">
            <div class="flash__container__infinite__header">
                <div class="flash__container__infinite__header__title">
                    {{ currentBlockingMessage.title }}
                </div>
                <div v-if="blockingMessages.length > 1">
                    <span @click="prev">&lt;</span>
                    {{ blockingMessageIndex + 1 }}/{{ blockingMessages.length }}
                    <span @click="next">&gt;</span>
                </div>
            </div>
            <div
                class="flash__container__infinite__body"
                v-html="currentBlockingMessage.html" />
        </div>
        <accept-invitation
            ref="acceptInvitation"
            :current-blocking-message="currentBlockingMessage" />
    </div>
    <div v-else />
</template>

<script>

import BlockingNotification from './../store/models/BlockingNotification'
import AcceptInvitation from '../components/modals/AcceptInvitation.vue'
import axios from "@plugins/axios.js"
import utils from '@helpers/utils'

export default {
    components: {AcceptInvitation},
    data() {
        return {
            blockingMessageIndex: 0
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        blockingMessages() {
            return BlockingNotification.all()
        },
        currentBlockingMessage() {
            return this.blockingMessages[this.blockingMessageIndex]
        }
    },
    watch: {
        currentUser(val) {
            if (val) {
                BlockingNotification.create({data: val.blocking_notifications})
            }
        },
        blockingMessages(val) {
            if (val && val.length) {
                this.$nextTick(() => {
                    this.bindListenerAccept()
                    this.bindListenerDecline()
                })
            }
        }
    },
    created() {
        this.UserChannel = initUsersChannel()
        this.UserChannel.bind(usersChannelEvents.newFlashbox, (data) => {
            BlockingNotification.create({data: data.notifications})
        })
    },
    methods: {
        bindListenerAccept() {
            document.querySelector('.flash__container__infinite__buttons__accept').addEventListener('click', (event) => {
                event.preventDefault()
                event.stopPropagation()
                this.accept(event.target.getAttribute("href"))
            })
        },
        bindListenerDecline() {
            document.querySelector('.flash__container__infinite__buttons__decline').removeEventListener('click', this.declineListenter)
            document.querySelector('.flash__container__infinite__buttons__decline').addEventListener('click', this.declineListenter)
        },
        declineListenter(event) {
            event.preventDefault()
            event.stopPropagation()
            this.decline(event.target.getAttribute("href"))
        },
        next() {
            if (this.blockingMessageIndex < this.blockingMessages.length - 1) {
                this.blockingMessageIndex++
                this.$nextTick(() => {
                    this.bindListenerAccept()
                    this.bindListenerDecline()
                })
            }
        },
        prev() {
            if (this.blockingMessageIndex > 0) {
                this.blockingMessageIndex--
                this.$nextTick(() => {
                    this.bindListenerAccept()
                    this.bindListenerDecline()
                })
            }
        },
        accept: utils.debounce(function (href) {
            if (this.currentBlockingMessage.type === "Session" && this.currentBlockingMessage.immersive_purchase_price != null && this.currentBlockingMessage.livestream_purchase_price != null) {
                this.$refs.acceptInvitation.open(this.currentBlockingMessage.id)
            } else {
                BlockingNotification.delete(this.currentBlockingMessage.id)
                this.$flash(this.$t('controllers.mark_invitation_as_accepted_success'), "success")
                this.goTo(href)
            }
        }, 200),
        decline(href) {
            axios.post(href).then((response) => {
                BlockingNotification.delete(response.data.id)
                this.$flash(this.$t('controllers.gettogethers.reject_invitation_success'), "success")
                this.blockingMessageIndex = 0
            }).catch(error => {
                if (error?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash(this.$t('frontend.app.uikit.m_blocking_message.wrong'))
                }
            })
        }
    }
}
</script>