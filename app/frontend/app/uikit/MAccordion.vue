<template>
    <div class="accordionMK2">
        <div
            class="accordion"
            @click="toggle">
            {{ title }}
        </div>
        <div
            v-show="open"
            class="panel">
            <p>
                <slot />
            </p>
        </div>
    </div>
</template>

<script>
/**
 * @displayName Accordion
 */
export default {
    props: {
        defaultState: {
            type: Boolean,
            default: false
        },
        title: {
            type: String,
            default: ""
        }
    },
    data() {
        return {
            open: this.defaultState
        }
    },
    methods: {
        toggle() {
            this.open = !this.open
        }
    }
}
</script>

