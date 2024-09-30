<template>
    <div
        v-show="active"
        class="tabMK2">
        <slot />
    </div>
</template>

<script>
export default {
    props: {
        title: {
            type: String,
            required: true
        },
		additionalClass: {
			type: String,
			required: false
		}
    },
    data() {
        return {
            in: false
        }
    },
    computed: {
        active() {
            var isActive = this.$parent.current === this
            return isActive
        }
    },
    created() {
        this.$parent.registerTab(this)
    }
}
</script>