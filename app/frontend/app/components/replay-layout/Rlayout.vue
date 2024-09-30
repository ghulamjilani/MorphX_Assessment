<template>
    <div class="Rlayout">
        <div class="Rlayout__title">
            Interactive Replay Layout
        </div>
        <div
            v-for="model in models"
            :key="model.id"
            class="Rlayout__tiles">
            <m-radio
                :key="model.val"
                v-model="layout"
                :val="model.val" />
            <div class="Rlayout__tile">
                <div class="Rlayout__info">
                    <div class="Rlayout__info__title">
                        {{ model.title }}
                    </div>
                    <div>
                        {{ model.text }}
                    </div>
                </div>
                <div class="Rlayout__image">
                    <img
                        :alt="model.img"
                        :src="$img[model.img]">
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    data() {
        return {
            layout: 'grid',
            models: [
                {
                    id: 1,
                    val: 'grid',
                    title: 'Grid',
                    text: 'Video: all participants Audio: all participants',
                    img: 'layout_grid'
                },
                {
                    id: 2,
                    val: 'presenter_focus',
                    title: 'Presenter Focus',
                    text: 'Video: presenter focus Audio: all participants',
                    img: 'layout_presenterFocus'
                },
                {
                    id: 3,
                    val: 'presenter_only',
                    title: 'Presenter Only',
                    text: 'Video: presenter only Audio: presenter only',
                    img: 'layout_presenterOnly'
                }
            ]
        }
    },
    watch: {
        value(val) {
            if (val !== this.layout) {
                this.layout = val
            }
        },
        layout: {
            handler(val) {
                this.$emit('input', val)
            }
        }
    }
}
</script>