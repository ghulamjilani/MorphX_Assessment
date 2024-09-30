<template>
    <div class="formManager">
        <template v-if="editing">
            <!-- edit fields -->
            <form-builder
                v-bind="$props"
                @formChanged="val => $emit('formChanged', val)" />
        </template>
        <template v-else>
            <!-- show fields -->
            <m-form
                ref="form"
                v-model="formDisabled"
                @onSubmit="sendForm">
                <div
                    v-for="item in form"
                    :key="item.key"
                    class="formManager__itemWrapper">
                    <component
                        :is="item.type"
                        v-bind="item.props"
                        :rules="{'required': item.props.required, 'email': item.props.type === 'email'}"
                        :disabled="item.type === 'm-btn' ? formDisabled : false"
                        :field-id="item.props.fieldName"
                        @input="(val) => { inputData(item, val) }" />
                </div>
            </m-form>
        </template>
    </div>
</template>

<script>
import FormBuilder from "./FormBuilder.vue"
import RawHtml from "./RawHtml.vue";

export default {
  components: {FormBuilder, RawHtml}, // add used components
  props: {
    form: {
      type: [Object, Array]
    },
    value: {
      type: Object
    },
    editing: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      formDisabled: false,
      formData: this.value || {}
    }
  },
  watch: {
  },
  mounted() {
    if(this.$refs.form) this.$refs.form.checkObserver()
  },
  methods: {
    sendForm() {
      this.$emit("sendForm")
    },
    inputData(item, val) {
      if(item.props?.fieldName) {
        this.formData[item.props.fieldName] = val
        this.$emit("input", this.formData)
      }
    }
  }
}
</script>

<style>

</style>