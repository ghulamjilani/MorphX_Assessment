<template>
    <m-modal
        ref="modalGeneral"
        :class="params.className"
        :confirm="params.confirm"
        :text-confirm="params.textConfirm"
        class="GeneralModal">
        <template #header>
            <h3
                v-if="params.title"
                v-text="params.title" />
        </template>

        <template #default>
            <component
                :is="component.name"
                v-if="component"
                :params="component.params" />
            <div
                v-else
                class="body"
                v-text="params.body" />
        </template>

        <template #footer>
            <div
                v-if="params.actions"
                class="actions">
                <m-btn
                    size="s"
                    type="secondary"
                    @click="close"
                    v-text="cancelName" />
                <m-btn
                    size="s"
                    type="main"
                    @click="confirm"
                    v-text="okName" />
            </div>
        </template>
    </m-modal>
</template>

<script>
export default {
    name: 'GeneralModal',
    components: {
        DocumentsSettings: () => import('@components/documents/Settings')
    },
    data() {
        return {
            params: {},
            component: {}
        }
    },
    computed: {
        cancelName() {
            return this.params.actions?.cancel?.name || 'Cancel'
        },
        okName() {
            return this.params.actions?.ok?.name || 'Ok'
        }
    },
    mounted() {
        this.$eventHub.$on("open-modal", this.open)
        this.$eventHub.$on("close-modal", this.close)
        this.$eventHub.$on("close-modal:all", this.close)
    },
    methods: {
        open(args) {
            const {component, ...params} = args
            this.component = component
            this.params = params || {} //className, title, body
            this.$refs.modalGeneral.openModal()
        },
        close() {
            this.$refs.modalGeneral?.closeModal()
        },
        confirm() {
            if (this.params.actions?.ok?.action) this.params.actions.ok.action()
            this.close()
        }
    }
}
</script>