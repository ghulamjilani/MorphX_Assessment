<template>
    <m-input
        :field-id="fieldId"
        :label="!pureLabel ? label : ' '"
        :password="true"
        :type="show ? 'text' : 'password'"
        class="passwordInput"
        v-bind="$attrs"
        @blur="() => { $emit('blur') }"
        @enter="() => { $emit('enter') }"
        @focus="() => { $emit('focus') }"
        @input="(event) => { $emit('input', event) }">
        <template #icon>
            <m-icon
                :name="icons[show]"
                :size="sizeIcon"
                @click="showPassword" />
        </template>
    </m-input>
</template>

<script>
export default {
    props: {
        label: {
            type: String,
            default: ''
        },
        pureLabel: {
            type: Boolean,
            default: true
        },
        sizeIcon: {
            type: String,
            default: '1.4rem'
        },
        fieldId: {
            type: String,
            default: 'input_id'
        }
    },
    data() {
        return {
            icons: {
                true: "GlobalIcon-eye",
                false:"GlobalIcon-eye-off"
            },
            show: false
        }
    },
    methods: {
        showPassword() {
            this.show = !this.show
        }
    }

}
</script>

