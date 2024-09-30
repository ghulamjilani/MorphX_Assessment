<template>
    <div class="mopsShowController">
        <mops-modal
            @sendForm="sendForm"
            @input="(data) => { formData = data }" />
    </div>
</template>

<script>
/*
    #vue-optin
        = content_tag 'comp-wrapper', nil, data: { component: 'MopsShowController', props: {}}.to_json
*/
import OptIn from "@models/OptIn"

import MopsModal from './MopsModal.vue'

export default {
    components: {
        MopsModal
    },
    data() {
        return {
            mops: null,
            timer: 0,
            formData: {}
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    mounted() {
        this.fetchMops()
    },
    methods: {
        fetchMops() {
            let params = {}
            if(window.Immerss.session) {
                params["model_type"] = "Session"
                params["model_id"] = window.Immerss.session.id
            }
            if(window.Immerss.replay) {
                params["model_type"] = "Video"
                params["model_id"] = window.Immerss.replay.id
            }
            if(window.Immerss.recording) {
                params["model_type"] = "Recording"
                params["model_id"] = window.Immerss.recording.id
            }

            OptIn.api().getOptInModalByModel(params).then(res => {
                if(res.response.data.response?.opt_in_modals.length) {
                    this.mops = res.response.data.response?.opt_in_modals[0]
                    if(typeof this.mops.system_template.body === 'string') {
                        this.mops.system_template.body = JSON.parse(this.mops.system_template.body)
                    }
                    this.checkOptIn()
                }
            })
        },
        checkOptIn() {
            let mopsAnswered = false
            let answerList = localStorage.getItem("optin-answered")
            if(answerList) {
                answerList = JSON.parse(answerList)
                mopsAnswered = answerList.includes(this.mops.id)
            }

            if(!mopsAnswered) {
                this.startWhenPlayerStart()
            }
        },
        startWhenPlayerStart() {
            if(!window.player || window.player?.currentTime < 1) {
                setTimeout(() => {
                    this.startWhenPlayerStart()
                }, 1000)
            }
            else {
                setTimeout(() => {
                    if(!this.currentUser) {
                        this.$eventHub.$emit("mops-modal:show", this.mops)
                        window.player?.pause()
                        this.$nextTick(() => {
                            document.querySelector("body").classList.remove("overflow-hidden")
                        })
                        OptIn.api().trackView({id: this.mops.id})
                    }
                }, this.mops.trigger_time * 1000)
            }
        },
        sendForm() {
            OptIn.api().sendForm({
                opt_in_modal_id: this.mops.id,
                data: Object.values(this.formData).join("|") // TODO
            }).then(res => {
                let answerList = localStorage.getItem("optin-answered")
                answerList = answerList && answerList != "" ? JSON.parse(answerList) : []
                answerList.push(this.mops.id)
                localStorage.setItem("optin-answered", JSON.stringify(answerList))

                this.$flash("Form submitted successfully!", "success")
                this.$eventHub.$emit("mops-modal:close")
                window.player?.play()
            })

        }
    }
}
</script>

<style>

</style>