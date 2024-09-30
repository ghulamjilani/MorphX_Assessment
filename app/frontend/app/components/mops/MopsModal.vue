<template>
    <div class="mops-modal">
        <m-modal
            ref="mopsShowModal"
            :backdrop="demo"
            :close="demo">
            <form-manager
                v-if="currentMops"
                :form="currentMops.system_template.body.form"
                @sendForm="$emit('sendForm')"
                @input="(data) => { $emit('input', data) }" />
        </m-modal>
    </div>
</template>

<script>
import FormManager from '@uikit/ComponentsManager/Components/FormManager.vue'

export default {
    components: {
        FormManager
    },
    props: {
        demo: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            currentMops: null
        }
    },
    mounted() {
        this.$eventHub.$on("mops-modal:show", (mops) => {
            this.currentMops = mops
            this.openModal()
        })
        this.$eventHub.$on("mops-modal:close", () => {
            this.currentMops = null
            this.closeModal()
        })
    },
    methods: {
        openModal() {
            this.$refs.mopsShowModal.openModal()
        },
        closeModal() {
            this.$refs.mopsShowModal.closeModal()
        }
    }
}
</script>

<style>

</style>