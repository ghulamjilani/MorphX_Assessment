<template>
    <div class="formManager__builder">
        <div
            v-for="item in formData"
            :key="item.key"
            class="formManager__row"
            :class="{ 'formManager__row__column': item.type=='raw-html' }">
            <div class="formManager__row__controls">
                <m-btn
                    v-tooltip="'move up'"
                    :reset="true"
                    type="custom"
                    @click.prevent="orderChange(item, -1)">
                    <m-icon
                        class="rotate__180"
                        size="1.2rem">
                        GlobalIcon-angle-down
                    </m-icon>
                </m-btn>
                <m-btn
                    v-tooltip="'move down'"
                    :reset="true"
                    type="pushRight"
                    @click.prevent="orderChange(item, 1)">
                    <m-icon
                        size="1.2rem">
                        GlobalIcon-angle-down
                    </m-icon>
                </m-btn>
                <m-btn
                    v-tooltip="'remove'"
                    :reset="true"
                    type="custom"
                    @click.prevent="remove(item)">
                    <m-icon
                        size="1.2rem">
                        GlobalIcon-trash
                    </m-icon>
                </m-btn>
            </div>
            <m-select
                v-model="item.type"
                class="formManager__item"
                :options="availableTypes(item)"
                label="Choose Type"
                :without-error="true"
                @change="(ch) => { typeChange(item, ch) }" />
            <m-select
                v-if="item.props.type !== undefined"
                v-model="item.props.type"
                class="formManager__item"
                :options="propsOptions.type"
                label="Input Type"
                :without-error="true" />
            <m-input
                v-if="item.props.label !== undefined"
                v-model="item.props.label"
                class="formManager__item"
                label="Label"
                :field-id="'label'"
                :errors="false" />
            <m-input
                v-if="item.props.text !== undefined"
                v-model="item.props.text"
                class="formManager__item"
                label="Title/Text"
                :field-id="'text'"
                :errors="false" />
            <m-input
                v-if="item.props.fieldName !== undefined"
                v-model="item.props.fieldName"
                class="formManager__item"
                label="Field Name"
                :errors="false"
                :field-id="'fieldName'"
                @change="(fieldName) => { nameToId(item, fieldName) }" />
            <m-checkbox
                v-if="item.props.textarea !== undefined"
                v-model="item.props.textarea"
                class="formManager__item">
                TextArea
            </m-checkbox>
            <m-checkbox
                v-if="item.props.required !== undefined"
                v-model="item.props.required"
                class="formManager__item">
                Is Required
            </m-checkbox>
            <vue-editor
                v-if="item.props.rawHtml !== undefined"
                ref="editor"
                v-model="item.props.rawHtml"
                :editor-options="editorSettings" />
        </div>
        <m-btn
            class="formManager__builder__save"
            @click.prevent="addNewRow">
            Add new row
        </m-btn>
    </div>
</template>

<script>
import {VueEditor} from "vue2-editor"
import Quill from 'quill'
import htmlEditButton from "quill-html-edit-button"
if(!Quill.imports["modules/htmlEditButton"]) Quill.register("modules/htmlEditButton", htmlEditButton)

export default {
components: {
  VueEditor
},
props: {
  form: {
    type: [Object, Array]
  },
  editing: {
    type: Boolean,
    default: false
  }
},
data() {
  return {
    formData: null,
    defaultSettings: {
      type: null,
      key: null,
      order: null,
      props: {}
    },
    defaultByType: {
      "m-input": {
        label: "",
        type: "email",
        fieldName: "email", // also id
        fieldId: "",
        // pure: true,
        // errors: false,
        // textarea: false,
        required: true
      },
      "m-btn": {
        text: "",
        action: "submit"
      },
      "m-checkbox": {
        text: "",
        required: true
        // disableForm: false
      },
      "raw-html": {
        rawHtml: ""
      }
    },
    optionsType: [
      {name: "Input", value: "m-input"},
      // {name: "Checkbox", value: "m-checkbox"},
      {name: "Submit Button", value: "m-btn"},
      {name: "Text", value: "raw-html"}
    ],
    propsOptions: {
      'type': [
        {name: "Email", value: "email"},
        // {name: "Text", value: "text"}
      ]
    },
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
                  // ["emoji"],
                  // ["image", "link"],
                  [{list: "ordered"}, {list: "bullet"}],
                  ["blockquote", "code-block"],
                  // [{ size: ["small", false, "large"] }],
                  // [{ direction: [] }],
                  // ["align"]
                  // ["clean"],
                  // [{ header: 1 }, { header: 2 }],
                  // [{ script: "sub" }, { script: "super" }],
                  [{ indent: "-1" }, { indent: "+1" }],
                  // [{ color: [] }, { background: [] }],
                  ['clean']
              ]
          },
          htmlEditButton: {
            okText: "Save"
            // syntax: true // need highlight.js
          }
        }
      },
  }
},
watch: {
  formData: {
    handler(val) {
      this.$emit("formChanged", val)
    },
    deep: true,
    immediate: true
  }
},
mounted() {
  this.formData = JSON.parse(JSON.stringify(this.form || []))
  this.checkFields()
},
methods: {
  typeChange(item, type) {
    item.props = JSON.parse(JSON.stringify(this.defaultByType[type]))
  },
  nameToId(item, name) {
    item.props.fieldId = name.replaceAll(" ", "_").toLowerCase()
  },
  addNewRow() {
    let newRow = JSON.parse(JSON.stringify(this.defaultSettings))
    newRow.key = new Date().getTime()
    newRow.order = this.formData.length
    this.formData.push(newRow)
  },
  checkFields() { // check new fields in old settings
      if(!this.formData) return

      // Object.keys(this.defaultSettings.props).forEach(key => {
      //   if(!Object.keys(this.formData.props).includes(key)) {
      //     this.formData.props[key] = this.defaultSettings.props[key]
      //   }
      // })
      // if(this.defaultByType[this.formData.type]){
      //   Object.keys(this.defaultByType[this.formData.type]).forEach(key => {
      //     if(!Object.keys(this.formData.props).includes(key)) {
      //       this.formData.props[key] = this.defaultByType[this.formData.type][key]
      //     }
      //   })
      // }
    },
    remove(item) {
      this.formData = this.formData.filter(f => f.key !== item.key)
      this.sorting()
      this.formData?.forEach((t, i) => {
        t.order = i
      })
    },
    orderChange(item, val) {
      let newOrder = item.order + val
      if(newOrder < this.formData.length && newOrder >= 0) {
        this.formData.find(e => e.order == newOrder).order = item.order
        item.order = newOrder
      }
      this.sorting()
    },
    sorting() {
      this.formData.sort((a, b) => { return a.order - b.order })
    },
    clearFields() {
      if(!this.formData) return

      this.formData = this.formData.map(fd => {
        Object.keys(fd.props).forEach(key => {
          if(!(this.defaultByType[fd.type] &&
              Object.keys(this.defaultByType[fd.type]).includes(key))) {
                delete fd.props[key]
          }
        })
        return fd
      })
    },
    availableTypes(item) {
      return this.optionsType.filter(f => {
        if(f.value === "m-input" && item.type !== "m-input") {
          return !this.formData.find(fd => fd.type === "m-input")
        }
        else if(f.value === "m-btn" && item.type !== "m-btn") {
          return !this.formData.find(fd => fd.type === "m-btn")
        }
        else {
          return true
        }
      })
    }
  }
}
</script>

<style>

</style>