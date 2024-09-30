<template>
    <div class="DocumentPreview">
        <m-btn
            class="DocumentPreview__mobileButton"
            @click="goTo(document.downloadUrl, true)">Open PDF in new tab</m-btn>
        <iframe
            v-if="document.fileExt === 'pdf'"
            class="DocumentPreview__preview DocumentPreview__preview__pdf"
            :src="document.downloadUrl" />
        <div
            v-if="document.fileExt !== 'pdf'"
            class="DocumentPreview__preview DocumentPreview__preview__blank">
            <p>Preview for {{ document.filename }}.{{ document.fileExt }} is unavailable</p>
        </div>
    </div>
</template>

<script>
export default {
    name: 'DocumentPreview',
    props: {
        document: {
            type: Object,
            default: () => {},
            required: true
        }
    }
}
</script>

<style lang="scss" scoped>
.DocumentPreview{
    height: 100%;
    &__preview{
        width: 100%;
        height: 100%;
        &__blank{
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            background-color: var(--bg__hover);
            p{
                text-align: center;
            }
        }
    }
}

</style>