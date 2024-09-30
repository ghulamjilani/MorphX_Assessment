<template>
    <div class="tagsMK2">
        <m-chips
            v-for="(tag, index) in tags"
            :key="index"
            class="tagsMK2__tag">
            {{ tag }}
            <m-icon
                class="tagsMK2__icon"
                size=".8rem"
                @click="removeTag(index)">
                GlobalIcon-clear
            </m-icon>
        </m-chips>
        <label
            :class="{'input__field__label': true, 'input__field__label__up' : upTags}"
            for="tags">
            Tags *
        </label>
        <div class="input__field tagsMK2__input">
            <input
                v-if="tags.length < maxTags"
                id="tags"
                v-model="text"
                :class="{'input__field__errors' : errorReq || errorLen}"
                class="tagsMK2__input input__field__without-label input__field__without-border"
                placeholder=" "
                type="text"
                @blur="addTags($event)"
                @focus="upTags = true"
                @input="inputText($event)"
                @keydown.enter="addTags($event)">
        </div>
        <div
            v-if="errorReq && tags.length === 0"
            class="input__field__bottom">
            <div class="input__field__bottom__errors">
                This field is required
            </div>
        </div>
        <div
            v-if="errorReq && tags.length < minTags && tags.length > 0"
            class="input__field__bottom">
            <div class="input__field__bottom__errors">
                Minimum tags count: {{ minTags }}
            </div>
        </div>
        <div
            v-if="errorLen"
            class="input__field__bottom">
            <div class="input__field__bottom__errors">
                Please enter at least 2 characters
            </div>
        </div>
        <div
            v-if="!errorLen && !errorReq && description !== ''"
            class="input__field__bottom">
            <div class="input__field__bottom__description">
                {{ description }}
            </div>
        </div>
    </div>
</template>

<script>
export default {
    props: {
        value: {},
        maxTags: {
            type: Number,
            default: 16
        },
        minTags: {
            type: Number,
            default: -1
        },
        min: {
            type: Number,
            default: 2
        },
        max: {
            type: Number,
            default: 80
        },
        description: {
            type: String,
            default: ''
        }
    },
    data() {
        return {
            tags: JSON.parse(JSON.stringify(this.value || [])), // deep copy
            upTags: false,
            errorReq: false,
            errorLen: false,
            text: null
        }
    },
    computed: {
        tagsValue() {
            if (!this.tags.length) {
                return this.upTags = false
            }
        }
    },
    watch: {
        tags: {
            deep: true,
            handler(val) {
                this.$emit("input", val)
                if (val.length >= this.min) this.upTags = true
            }
        },
        value(val) {
            if (val.length >= this.min) {
                this.upTags = true
                this.errorLen = false
            }
        }
    },
    mounted() {
        setTimeout(() => {
            if (this.tags.length > 0) this.upTags = true
        }, 200)
    },
    methods: {
        inputText(event) {
            var val = event.target.value.trim()
            if (val.length >= this.max) {
                this.$flash("Maximum tag length could not be more then " + this.max + " symbols.")
                this.text = this.text.slice(0, -1)
            }
            if (val.length >= this.min && val.length <= this.max) {
                this.errorLen = false
                return
            } else if (val.length > 0) {
                this.upTags = true
                this.errorReq = false
                this.errorLen = true
                return
            }
            if (!this.tags.length) {
                this.upTags = false
                this.errorLen = false
                this.errorReq = true
            } else if (val.length === 0) {
                this.errorLen = false
            }
        },
        addTags(event) {
            if (!this.tags.length && (!this.text || this.text?.length == 0)) {
                this.errorReq = true
                this.upTags = false
            }
            if (this.tags.length > 0 && this.tags.length < this.minTags && (!this.text || this.text?.length == 0)) {
                this.errorReq = true
                this.upTags = false
            }
            if (!this.errorReq && !this.errorLen && this.text?.length > 1) {
                this.tags = this.tags.concat(event.target.value.split(",").map(t => t.trim()))
                this.text = ''
            }
        },
        removeTag(index) {
            this.tags.splice(index, 1)
            if (!this.tags.length) this.upTags = false
        },
        clear() {
            this.tags = []
            this.upTags = false
        }
    }
}
</script>