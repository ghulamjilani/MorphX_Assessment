<template>
    <div class="cropImage">
        <div
            :class="{cropImage__cropWrapper__background: editImage}"
            :style="editImage ? `background-image: url('${editImage}')` : ''"
            class="cropImage__cropWrapper"
            @drop="setImage($event, true)"
            @dragover.prevent>
            <vue-cropper
                v-if="imgSrc"
                ref="cropper"
                :aspect-ratio="aspectRatio"
                :center="false"
                :src="imgSrc"
                :zoom-on-wheel="false"
                class="cropImage__cropper"
                @cropend="cropImageToFormData"
                @ready="cropImageToFormData"
                @zoom="cropImageToFormData" />
            <div
                v-else
                class="cropImage__dotted">
                <input
                    id="image"
                    ref="input"
                    accept="image/*"
                    class="cropImage__input"
                    name="image"
                    type="file"
                    @change="setImage($event, false)">
                <label
                    class="btn btn__main"
                    for="image">Select file to upload</label>
                <p class="cropImage__drop">
                    or drag-n-drop your image here
                </p>
            </div>
        </div>
        <div class="cropImage__options">
            <!-- <div class="cropImage__imgSize">
                <p
                    v-if="imgdata.height > 0"
                    :class="{cropImage__imgSize__error: imgdata.height > 0 && imgdata.height < 400}">
                    <span>Image size:</span> {{ imgdata.width }}x{{ imgdata.height }}px
                </p>
                <p
                    v-if="imgdata.height > 0 && imgdata.height < 400"
                    class="cropImage__imgSize__error">
                    <span>Minimum size:</span> 800x400px
                </p>
                <p>We recommend to using high resolution image.</p>
            </div> -->
            <div
                v-if="imgSrc"
                class="cropImage__control">
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__bottom marginLeftLess"
                    size="1.6rem"
                    @click="move(10, 0)">
                    GlobalIcon-angle-right
                </m-icon>
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__bottom"
                    size="1.6rem"
                    @click="move(-10, 0)">
                    GlobalIcon-angle-left
                </m-icon>
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__bottom"
                    size="1.6rem"
                    style="transform: rotateX(180deg); display: inline-block;"
                    @click="move(0, -10)">
                    GlobalIcon-angle-down
                </m-icon>
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__bottom cropImage__control__icon__zoom"
                    size="1.6rem"
                    @click="move(0, 10)">
                    GlobalIcon-angle-down
                </m-icon>

                <m-icon
                    class="cropImage__control__icon"
                    size="1.6rem"
                    @click="zoom(0.2)">
                    GlobalIcon-plus-circle
                </m-icon>
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__zoom"
                    size="1.6rem"
                    @click="zoom(-0.2)">
                    GlobalIcon-minus-circle
                </m-icon>
                <m-icon
                    class="cropImage__control__icon"
                    size="1.6rem"
                    @click="rotate(-90)">
                    GlobalIcon-rotate-angle-left
                </m-icon>
                <m-icon
                    class="cropImage__control__icon cropImage__control__icon__zoom"
                    size="1.6rem"
                    @click="rotate(90)">
                    GlobalIcon-rotate-angle-right
                </m-icon>
                <m-icon
                    size="1.6rem"
                    @click="clear">
                    GlobalIcon-clear
                </m-icon>
                <!-- <br> -->
            </div>
        </div>
    </div>
</template>

<script>
import VueCropper from 'vue-cropperjs'
import 'cropperjs/dist/cropper.css'

export default {
    components: {VueCropper},
    props: {
      aspectRatio: Number,
      value: String
    },
    data() {
        return {
            imgSrc: '',
            editImage: null,
            imgdata: {
                width: 0,
                height: 0
            }
        }
    },
    mounted() {
      this.editImage = this.value
      this.setSize()
    },
    methods: {
        setImage(e, drop) {
            this.editImage = null
            e.stopPropagation()
            e.preventDefault()
            if (drop) {
                var file = e.dataTransfer.files[0]
            } else {
                var file = e.target.files[0]
            }
            if (file.type.indexOf('image/') === -1) {
                alert('Please select an image file')
                return
            }
            if (typeof FileReader === 'function') {
                var reader = new FileReader()
                reader.onload = (event) => {
                    this.imgSrc = event.target.result
                    // rebuild cropperjs with the updated source
                    this.$nextTick(() => {
                        this.$refs['cropper'].replace(event.target.result)
                        window.crop = this.$refs['cropper']

                        let img = new Image()
                        let lwidth = -1, lheight = -1
                        img.onload = (e) => {
                            if (e.path && e.path[0]) {
                                lwidth = e.path[0].width
                                lheight = e.path[0].height
                            } else if (e.target && e.target.height) {
                                lwidth = e.target.width
                                lheight = e.target.height
                            }
                            this.$refs['cropper'].setCropBoxData({height: lheight, width: lwidth})
                            setTimeout(() => {
                                this.$refs['cropper'].setCropBoxData({top: 0, left: 0})
                                this.$refs['cropper'].setCropBoxData({height: lheight, width: lwidth})
                                // if(lheight > lwidth && lheight > 400) {
                                //   this.$refs['cropper'].zoomTo(lheight/lwidth/10)
                                //   this.$refs['cropper'].moveTo(0, 0)
                                //   this.$refs['cropper'].setCropBoxData({ width: lwidth*(lheight/lwidth/10) })
                                //   this.$refs['cropper'].setCropBoxData({ top: 0, left: 0 })
                                // }
                                this.cropImageToFormData()
                            }, 300)
                        }
                        img.src = event.target.result
                    })
                }
                reader.readAsDataURL(file)
                this.keyMove()
            } else {
                alert('Sorry, FileReader API not supported')
            }
        },
        zoom(percent) {
            this.$refs.cropper.relativeZoom(percent)
            this.cropImageToFormData()
        },
        rotate(deg) {
            this.$refs.cropper.rotate(deg)
            this.cropImageToFormData()
        },
        move(offsetX, offsetY) {
            this.$refs.cropper.move(offsetX, offsetY)
            this.cropImageToFormData()
        },
        clear() {
            this.imgSrc = ''
            this.imgdata.width = 0
            this.imgdata.height = 0
            this.$emit("input", "")
            this.$emit("validate", true)
        },
        keyMove() {
            document.addEventListener("keydown", (e) => {
                switch (e.keyCode) {
                    case 37:
                        e.preventDefault()
                        this.move(-10, 0)
                        break
                    case 38:
                        e.preventDefault()
                        this.move(0, -10)
                        break
                    case 39:
                        e.preventDefault()
                        this.move(10, 0)
                        break
                    case 40:
                        e.preventDefault()
                        this.move(0, 10)
                        break
                }

            })
        },
        cropImageToFormData() {
            let val = this.$refs.cropper.getCroppedCanvas().toDataURL()

            if (!val || val === '') {
                this.imgdata.width = 0
                this.imgdata.height = 0
                this.$emit("validate", true)
            } else {
                let img = new Image()
                img.onload = (e) => {
                    if (e.path && e.path[0]) {
                        this.imgdata.width = e.path[0].width
                        this.imgdata.height = e.path[0].height
                    } else if (e.target && e.target.height) {
                        this.imgdata.width = e.target.width
                        this.imgdata.height = e.target.height
                    }
                    this.$emit("validate", this.imgdata.height == 0 || this.imgdata.height >= 400)
                }
                img.src = val
            }

            this.$emit("input", val)
        },
        changeImage(img) {
            this.editImage = img
        },
        setSize() {
            if (this.value) {
                var img = new Image()
                img.src = this.value
                img.onload = (e) => {
                    if (e.path && e.path[0]) {
                        this.imgdata.width = e.path[0].width
                        this.imgdata.height = e.path[0].height
                    } else if (e.target && e.target.height) {
                        this.imgdata.width = e.target.width
                        this.imgdata.height = e.target.height
                    }
                }
            }
        }
    }
}
</script>