<template>
    <div
        :class="{'linkPreview__manage': manage}"
        class="linkPreview">
        <a
            :href="link.url"
            target="_blank">
            <div
                :class="{'linkPreview__manage__image': manage}"
                :style="link.image_url ? `background-image: url('${link.image_url}')` : ''"
                class="linkPreview__image" />
        </a>
        <div
            :class="{'linkPreview__manage__text': manage}"
            class="linkPreview__text">
            <m-icon
                v-if="editable"
                class="linkPreview__close"
                size="1.6rem"
                @click="$emit('close', link.url)">
                GlobalIcon-clear
            </m-icon>
            <a
                :class="{'linkPreview__manage__text__title': manage}"
                :href="link.url"
                class="linkPreview__text__title"
                target="_blank">
                {{ link.title }}
            </a>
            <div class="linkPreview__text__description">
                {{ link.description }}
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        manage: Boolean,
        link: {},
        editable: {
            type: Boolean,
            default: false
        }
    },
    mounted() {
        this.checkExistLinkPreviewImg()
    },
    methods: {
        checkExistLinkPreviewImg() {
            var wrapper = document.querySelector('.linkPreview')
            if (wrapper) {
                let LinkImg = document.querySelector('.linkPreview__image')
                if (!LinkImg.hasAttribute('style')) {
                    wrapper.classList.add('NoImg')
                } else {
                    wrapper.classList.remove('NoImg')
                }
            }
        }
    }
}
</script>