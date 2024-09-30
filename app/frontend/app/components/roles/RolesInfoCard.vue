<template>
    <div class="infoCards__card">
        <div class="infoCards__card__body">
            <label class="fs__12 color__secondary padding-b__5">{{ info.count }} {{
                info.id != 4 ? 'Accounts' : ''
            }}</label>
            <span class="fs__14 text__bold color__h1 padding-b__10">{{ info.title }}</span>
            <span
                v-if="false"
                class="fs__12 text__bold color__active">{{ info.actionTitle }}</span>
        </div>
        <div class="infoCards__card__img">
            <img :src="$img[info.img]">
        </div>
    </div>
</template>

<script>
export default {
    props: {
        info: Object
    },
    methods: {
        filter(action) {
            this.$eventHub.$emit('groups:filter', action)
        }
    }
}
</script>