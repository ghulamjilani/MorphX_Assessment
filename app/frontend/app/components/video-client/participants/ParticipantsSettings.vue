<template>
    <div
        class="cm__tools__select"
        @click="unpinAll()">
        <div class="cm__tools__select__item cm__tools__select__item__specific">
            <div> Unpin all users</div>
        </div>
    </div>
</template>

<script>
import Room from "@models/Room"

export default {
    props: {
        roomInfo: Object
    },
    methods: {
        unpinAll() {
            this.$emit('close')
            Room.api().unpinAll({room_id: this.roomInfo.id}).then(res => {
                this.$flash('All users are unpinned', "success")
            }).catch(error => {
                if (error?.response?.data?.message) {
                    this.$flash(error.response.data.message)
                } else {
                    this.$flash('Something went wrong please try again later')
                }
            })
        }
    }
}
</script>