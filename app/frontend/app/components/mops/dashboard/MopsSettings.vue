<template>
    <div class="mops-settings">
        <m-modal
            ref="mopsModal"
            :backdrop="false">
            <template #header>
                Opt In Modal
            </template>

            <m-form
                v-if="mops"
                class="mops-settings__form"
                @onSubmit="save">
                <m-checkbox
                    v-model="mops.active"
                    class="mb-2">
                    Active
                </m-checkbox>
                <!-- TODO: rules="required" -->
                <m-input
                    v-model="mops.title"
                    label="Title"
                    class="mb-2 mt-2"
                    :errors="false" />

                <!-- <label class="label">Description</label>
                <vue-editor
                    ref="editor"
                    v-model="mops.description"
                    class="mb-2"
                    :editor-options="editorSettings" /> -->

                <m-input
                    v-model="mops.trigger_time"
                    label="Trigger Time (in seconds)"
                    class="mb-2"
                    :errors="false" />

                <h3>Form:</h3>
                <form-manager
                    :form="mops.system_template.body.form"
                    :editing="true"
                    @formChanged="formChanged" />
            </m-form>

            <template #footer>
                <m-btn
                    class="mops-settings__buttons__show"
                    type="secondary"
                    @click="show">
                    Preview
                </m-btn>
                <m-btn
                    class="mops-settings__buttons__save"
                    @click="save">
                    Save
                </m-btn>
            </template>
        </m-modal>
    </div>
</template>

<script>
import OptIn from "@models/OptIn"

import FormManager from '@uikit/ComponentsManager/Components/FormManager.vue'

import {VueEditor} from "vue2-editor"
import Quill from 'quill'
import htmlEditButton from "quill-html-edit-button"
if(!Quill.imports["modules/htmlEditButton"]) Quill.register("modules/htmlEditButton", htmlEditButton)

export default {
    components: {
        FormManager,
        VueEditor
    },
    data() {
        return {
            defaultModel: {
                // id: -1,
                channel_uuid: -1,
                title: "",
                description: "",
                active: false,
                trigger_time: 120,
                system_template: {
                    name: "",
                    body: { form: [{"type":"raw-html","key":1674046535845,"order":0,"props":{"rawHtml":""}},{"type":"m-input","key":1674046390499,"order":1,"props":{"label":"Email","type":"email","fieldName":"email","fieldId":"","textarea":false,"required":true}},{"type":"m-btn","key":1674122515098,"order":2,"props":{"text":"Submit","action":"submit"}}] }
                }
            },
            mops: null,
            isNewMops: false,

            // --- quill editor
            editorSettings: {
                modules: {
                    toolbar: {
                        container: [
                            [{header: [1, 2, 3, 4, 5, 6, false]}],
                            [
                                {align: ""},
                                {align: "center"},
                                {align: "right"},
                                {align: "justify"}
                            ],
                            ["bold", "italic", "underline", "strike"],
                            [{list: "ordered"}, {list: "bullet"}],
                            ["blockquote", "code-block"],
                            [{ indent: "-1" }, { indent: "+1" }],
                            ['clean']
                        ]
                    }
                }
            }
        }
    },
    mounted() {
        this.$eventHub.$on("mops-settings:new", (channel) => {
            this.isNewMops = true
            this.mops = null
            this.mops = JSON.parse(JSON.stringify(this.defaultModel))
            this.mops.channel_uuid = channel.uuid
            this.mops.system_template.name = `opt_${new Date().getTime()}`
            this.openModal()
        })
        this.$eventHub.$on("mops-settings:edit", (mops) => {
            this.isNewMops = false
            this.mops = null
            this.mops = JSON.parse(JSON.stringify(mops))
            this.openModal()
        })
    },
    methods: {
        openModal() {
            this.$refs.mopsModal.openModal()
        },
        closeModal() {
            this.$refs.mopsModal.closeModal()
        },
        save() {
            this.mops.system_template_attributes = this.mops.system_template
            if(typeof this.mops.system_template_attributes.body !== 'string') {
                this.mops.system_template_attributes.body = JSON.stringify(this.mops.system_template.body)
            }
            if(this.isNewMops) {
                OptIn.api().createOptInModals(this.mops).then(res => {
                    this.$flash("Success!", "success")
                    this.$emit("mopsCreated", res.response.data.response?.opt_in_modal)
                    this.closeModal()
                })
            }
            else {
                OptIn.api().updateOptInModals(this.mops).then(res => {
                    this.$flash("Success!", "success")
                    this.$emit("mopsUpdated", res.response.data.response?.opt_in_modal)
                    this.closeModal()
                })
            }
        },
        show() {
            this.$eventHub.$emit("mops-modal:show", this.mops)
        },
        formChanged(form) {
            this.mops.system_template.body.form = form
        }
    }
}
</script>

<style>

</style>