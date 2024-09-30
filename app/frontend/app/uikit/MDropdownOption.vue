<template>
    <m-btn
        :reset="true"
        v-bind="$attrs"
        v-on="$listeners">
        <slot />
    </m-btn>
</template>

<script>
export default {}
</script>

