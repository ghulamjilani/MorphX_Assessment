<template>
    <div class="newPost">
        <div class="newPost__info">
            <m-form>
                <m-select
                    :options="options"
                    label="Channel *"
                    placeholder="Select Channel"
                    type="default" />
                <m-input label="Simple" />
                <m-input
                    v-model="title"
                    class="test"
                    field-id="title"
                    label="Post title *"
                    rules="required"
                    type="text"
                    @blur="checkTitle()" />
                <div class="newPost__info__tags">
                    <blog-tags />
                </div>
            </m-form>
        </div>
        <crop-image />
        <div class="newPost__buttons">
            <m-btn type="secondary">
                Cancel
            </m-btn>
            <m-btn type="save">
                Publish
            </m-btn>
        </div>
    </div>
</template>

<script>
import Tags from "@components/blog/Tags"
import CropImage from "@components/blog/CropImage"

export default {
    components: {'blog-tags': Tags, CropImage},
    data() {
        return {
            options: [
                {name: "Starbucks Home", value: 1},
                {name: "Guitar", value: 2},
                {name: "Yoga", value: 3}
            ],
            title: '',
            upTitle: false,
            upTags: false
        }
    },
    methods: {
        checkTitle() {
            if (!this.title.length) {
                this.upTitle = false
            }
        }
    }
}
</script>