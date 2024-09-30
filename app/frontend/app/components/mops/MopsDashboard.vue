<template>
    <div class="mops-dashboard">
        <div class="mops-dashboard__title">
            Opt In Manager
        </div>

        <mops-settings
            @mopsCreated="mopsCreated"
            @mopsUpdated="mopsUpdated" />
        <mops-modal :demo="true" />
        <mops-channel
            v-for="channel in channels"
            :key="channel.id"
            :channel="channel"
            :all-mops-list="mopsList"
            @removed="removed" />
    </div>
</template>

<script>
import User from "@models/User"
import OptIn from "@models/OptIn"

import MopsChannel from "./dashboard/MopsChannel.vue"
import MopsSettings from "./dashboard/MopsSettings.vue"
import MopsModal from "./MopsModal.vue"

export default {
    components: {
        MopsChannel,
        MopsSettings,
        MopsModal
    },
    data() {
        return {
            channels: [],
            mopsList: []
        }
    },
    mounted() {
        this.fetchChannels()
    },
    methods: {
        fetchChannels() {
            User.api().getUserFullChannels().then(res => {
                this.channels = res.response.data.response
                this.fetchMops()
            })
        },
        fetchMops() {
            OptIn.api().getOptInModals().then(res => {
                this.mopsList = res.response.data.response?.opt_in_modals?.map(mops => {
                    if(typeof mops.system_template.body === 'string') {
                        mops.system_template.body = JSON.parse(mops.system_template.body)
                    }
                    return mops
                })
            })
        },
        mopsCreated(mops) {
            if(typeof mops.system_template.body === 'string') {
                mops.system_template.body = JSON.parse(mops.system_template.body)
            }
            this.mopsList.push(mops)
        },
        mopsUpdated(mops) {
            let index = this.mopsList.findIndex(m => mops.id == m.id)
            if(index > -1) {
                if(typeof mops.system_template.body === 'string') {
                    mops.system_template.body = JSON.parse(mops.system_template.body)
                }
                this.mopsList[index] = mops
            }
            this.mopsList = this.mopsList.map(m => m) // immutable
        },
        removed(mops) {
            this.mopsList = this.mopsList.filter(m => m.id != mops.id)
        }
    }
}
</script>

<style>

</style>