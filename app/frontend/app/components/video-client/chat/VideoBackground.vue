<template>
    <div class="virtualBackground">
        <div class="virtualBackground__header">
            <!-- <div class="cm__loader" v-show="loading">
          <div class="spinnerSlider">
          <div class="bounceS1"></div>
          <div class="bounceS2"></div>
          <div class="bounceS3"></div>
          </div>
      </div> -->
            <div class="virtualBackground__header__title">
                Virtual background gallery
            </div>
            <div
                class="virtualBackground__header__close"
                @click="close()">
                <m-icon size="1.8rem">
                    GlobalIcon-clear
                </m-icon>
            </div>
        </div>
        <div class="virtualBackground__body">
            <p
                v-if="!isVBSupported"
                class="virtualBackground__notSupported">
                Your browser is not supported!
            </p>

            <div class="virtualBackground__body__imgs">
                <div
                    v-for="(image, index) in images"
                    :key="index"
                    :class="{'active': selectedImage == image}"
                    class="virtualBackground__body__imgsItem"
                    @click="chooseImage(image)">
                    <img
                        :src="image"
                        :style="`filter: blur(${blur ? '1px' : '0' });`"
                        class="virtualBackground__image">
                    <div
                        v-if="selectedImage == image"
                        class="icon">
                        <m-icon size="1.6rem">
                            GlobalIcon-clear
                        </m-icon>
                    </div>
                </div>
            </div>
            <m-input
                v-if="canUseDebug"
                v-model="selectedImage"
                :pure="true"
                placeholder="Paste your URL for custom img"
                @input="setImage">
                <template #icon>
                    <m-icon
                        v-if="selectedImage && selectedImage.length"
                        size="1.6rem"
                        @click="removeBackground()">
                        GlobalIcon-clear
                    </m-icon>
                </template>
            </m-input>
            <!-- <m-checkbox v-model="blur" @change="toggleBlur">Blur background</m-checkbox> -->
        </div>
    </div>
</template>

<script>
import {mapGetters} from 'vuex'
import {GaussianBlurBackgroundProcessor, isSupported, VirtualBackgroundProcessor} from '@webrtcservice/video-processors'

export default {
    data() {
        return {
            virtualBackground: null,
            gaussianBlurProcessor: null,
            blur: false,
            images: [
                require("./../../../assets/images/VirtualBackground/1.png"),
                require("./../../../assets/images/VirtualBackground/2.jpeg"),
                require("./../../../assets/images/VirtualBackground/3.jpeg"),
                require("./../../../assets/images/VirtualBackground/4.png"),
                require("./../../../assets/images/VirtualBackground/5.png"),
                require("./../../../assets/images/VirtualBackground/6.jpeg"),
                require("./../../../assets/images/VirtualBackground/7.jpg"),
                require("./../../../assets/images/VirtualBackground/8.png"),
                require("./../../../assets/images/VirtualBackground/9.png"),
                require("./../../../assets/images/VirtualBackground/10.png")
                // "https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Paracas_National_Reserve%2C_Ica%2C_Peru-3April2011.jpg/1200px-Paracas_National_Reserve%2C_Ica%2C_Peru-3April2011.jpg",
                // "https://nationaltoday.com/wp-content/uploads/2019/12/christmas-1-640x514.jpg",
                // "https://media-exp1.licdn.com/dms/image/C511BAQEUGUtdp9I_Lw/company-background_10000/0/1526560332701?e=2159024400&v=beta&t=G3cvNDL4Wwq7TswbpgkqM3km-XCMAsx0-SDSGoEMwSU",
                // "https://static01.nyt.com/images/2021/05/02/business/00officespace8/00officespace8-superJumbo.jpg",
                // "https://ichef.bbci.co.uk/news/640/cpsprodpb/15E1A/production/_115962698_everest.jpg"
            ],
            selectedImage: null
        }
    },
    computed: {
        ...mapGetters("VideoClient", [
            "room",
            "roomInfo"
        ]),
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        canUseDebug() {
            return this.current_user?.can_use_debug_area
        },
        isVBSupported() {
            return isSupported
        }
    },
    methods: {
        setProcessor(processor) {
            let track = null
            this.room.localParticipant.videoTracks.forEach(tr => {
                track = tr?.track
            })
            if (!track) return
            if (track.processor) {
                track.removeProcessor(track.processor)
            }
            if (processor) {
                track.addProcessor(processor)
            }
        },
        setImage() {
            const img = new Image()
            img.crossOrigin = 'anonymous'
            img.src = this.selectedImage
            img.onload = () => {
                let backgroundImage = null
                if (!this.virtualBackground) {
                    this.virtualBackground = new VirtualBackgroundProcessor({
                        assetsPath: 'https://webrtcservice.github.io/webrtcservice-video-processors.js/examples/virtualbackground/',
                        backgroundImage: img,
                        fillType: 'Fill',
                        maskBlurRadius: this.blur ? 5 : 0
                    })
                    this.virtualBackground.loadModel().then(() => {
                        this.setProcessor(this.virtualBackground)
                    })
                } else {
                    this.virtualBackground.backgroundImage = img
                    this.virtualBackground.fitType = 'Fill'
                    this.virtualBackground.maskBlurRadius = this.blur ? 5 : 0
                    this.setProcessor(this.virtualBackground)
                }
            }
        },
        gaussianBlur() {
            if (!this.gaussianBlurProcessor) {
                this.gaussianBlurProcessor = new GaussianBlurBackgroundProcessor({
                    assetsPath,
                    maskBlurRadius,
                    blurFilterRadius
                })
                this.gaussianBlurProcessor.loadModel().then(() => {
                    this.setProcessor(this.gaussianBlurProcessor)
                })
            } else {
                this.gaussianBlurProcessor.maskBlurRadius = 5
                this.gaussianBlurProcessor.blurFilterRadius = 15
                this.setProcessor(this.gaussianBlurProcessor)
            }
        },
        removeBackground() {
            this.setProcessor(null)
            this.selectedImage = null
        },
        close() {
            this.$eventHub.$emit("tw-toggleVirtualBackground", false)
        },
        toggleBlur(e) {
            this.blur = e
            this.setImage()
            this.gaussianBlur()
        },
        chooseImage(image) {
            if (this.selectedImage == image) {
                this.removeBackground()
            } else {
                this.selectedImage = image
                this.setImage()
            }
        }
    }
}
</script>