<template>
    <div class="DocumentsSettings">
        <m-form
            v-if="document"
            ref="form"
            v-model="disabled"
            @onSubmit="$emit('addNewContacts')">
            <m-input
                v-model="dupModel.title"
                :maxlength="256"
                :max-counter="256"
                label="Document Name"
                name="file_name"
                field-id="file_name" />
            <m-input
                v-model="dupModel.description"
                :maxlength="1000"
                :max-counter="1000"
                label="Document Description"
                name="file_description"
                field-id="file_description"
                :textarea="true" />
            <h3>{{ $t('frontend.app.components.documents.settings.settings') }}</h3>
            <div class="cm__tools__select__item__specific">
                <label
                    @click="dupModel.visible = !dupModel.visible">
                    <i :class="'color__icons GlobalIcon-eye' + (!dupModel.visible ? '-off' : '')" />
                    {{ $t('frontend.app.components.documents.settings.visibility_label') }}
                </label>
                <m-toggle v-model="dupModel.visible" />
            </div>
            <div class="cm__tools__select__item__specific">
                <label
                    @click="dupModel.only_ppv = !dupModel.only_ppv">
                    <!-- <i :class="'color__icons GlobalIcon-eye' + (!dupModel.only_ppv ? '-off' : '')" /> -->
                    {{ $t('frontend.app.components.documents.settings.only_ppv') }}
                </label>
                <m-toggle
                    v-model="dupModel.only_ppv" />
            </div>
            <div
                class="cm__tools__select__item__specific">
                <div>Price</div>
                <m-price-input
                    v-model="dupModel.purchase_price"
                    custom-style="padding: 0; width:15rem;"
                    type="text"
                    label=""
                    :min="0.99"
                    :max="999999"
                    :errors="false"
                    :free-button="true"
                    class="margin__l-10" />
            </div>
            <div class="cm__tools__select__item__specific">
                <label
                    @click="dupModel.only_subscription = !dupModel.only_subscription">
                    <!-- <i :class="'color__icons GlobalIcon-eye' + (!dupModel.only_subscription ? '-off' : '')" /> -->
                    {{ $t('frontend.app.components.documents.settings.only_subscription') }}
                </label>
                <m-toggle v-model="dupModel.only_subscription" />
            </div>
            <!-- <div class="cm__tools__select__item__specific">
                <label
                    @click="dupModel.download = !dupModel.download">
                    <i class="color__icons GlobalIcon-download" />
                    Allow viewers to download
                </label>
                <m-toggle v-model="dupModel.download" />
            </div> -->
            <div class="margin-t__30 text__right">
                <m-btn
                    type="bordered"
                    size="s"
                    @click="closeModal">
                    {{ $t('frontend.app.components.documents.settings.cancel') }}
                </m-btn>
                <m-btn
                    type="save"
                    size="s"
                    @click="save">
                    {{ $t('frontend.app.components.documents.settings.done') }}
                </m-btn>
            </div>
        </m-form>
    </div>
</template>

<script>
import Document from "@models/Document"

export default {
    name: 'DocumentsSettings',
    props: {
        params: {
            type: Object, default: () => {
            }
        }
    },
    data() {
        return {
            disabled: false,
            dupModel: {
                title: '',
                description: '',
                visible: true,
                only_ppv: false,
                only_subscription: false,
                purchase_price: 0
            }
        }
    },
    computed: {
        document() {
            return Document.query().whereId(this.params.document_id).first()
        }
    },
    mounted() {
        this.dupModel = JSON.parse(JSON.stringify(this.document))
        // this.dupModel.title = this.document.title
        // this.dupModel.description = this.document.description
        this.dupModel.visible = !this.document.hidden
        // this.dupModel.only_ppv = this.document.only_ppv
        // this.dupModel.only_subscription = this.document.only_subscription
        // this.dupModel.purchase_price = this.document.purchase_price
        if(!this.document.purchase_price) {
            this.dupModel.purchase_price = 0
        }
    },
    methods: {
        async save() {
            const params = this.dupModel
            params.id = this.document.id
            params.hidden = !this.dupModel.visible
            await Document.api().update(params)
            this.closeModal()
        },
        closeModal() {
            this.$eventHub.$emit("close-modal")
        }
    }
}
</script>
