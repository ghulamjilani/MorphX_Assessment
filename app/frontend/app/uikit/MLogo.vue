<template>
    <img
        :src="$img[image]"
        alt
        class="m-logo">
</template>

<script>
export default {
    props: {
        image: {}
    }
}
</script>

