<template>
    <div
        v-if="ads.length > 0"
        class="bannerAdvertisement"
        :class="'bannerAdvertisement__' + imageSize">
        <div
            v-if="title"
            class="bannerAdvertisement__title">
            {{ title }}
        </div>
        <vue-horizontal-list
            class="bannerAdvertisement__horScroll"
            :class="{'dontHide': dontHide}"
            id="horScroll"
            :items="ads"
            :options="options">
            <template #default="{item}">
                <a
                    :key="item.id"
                    :href="item.url"
                    target="_blank"
                    class="bannerAdvertisement__ad"
                    :class="'bannerAdvertisement__ad__' + imageSize"
                    :style="`width: ${imageWidth}; height: ${imageHeight}; background-image: url('${item && item.file ? item.file.url : ''}')`"
                    @click="clicked(item)"
                    @click.middle.exact="clicked(item)">
                    <h1 v-if="dontHide">{{ item.key }}</h1>
                </a>
            </template>
        </vue-horizontal-list>
        <div
            class="bannerAdvertisement__ads"
            :class="{'dontHide': dontHide}">
            <a
                v-for="(ad, index) in ads"
                :key="index"
                :href="ad.url"
                target="_blank"
                class="bannerAdvertisement__ad"
                :class="'bannerAdvertisement__ad__' + imageSize"
                :style="`width: ${imageWidth}; height: ${imageHeight}; padding-bottom: ${paddingBottom}; background-image: url('${ad && ad.file ? ad.file.url : ''}')`"
                @click="clicked(ad)"
                @click.middle.exact="clicked(ad)">
                <h1 v-if="dontHide">{{ ad.key }}</h1>
            </a>
        </div>
    </div>
</template>

<script>
import PageBuilder from "@models/PageBuilder"

import VueHorizontalList from 'vue-horizontal-list'

export default {
    name: "BannerAdvertisement",
    components: {VueHorizontalList},
    props: {
        title: {
            type: String,
            default: ""
        },
        areaId: {
            type: String,
            default: ""
        },
        imageSize: {
            type: String,
            default: "full"
        },
        imageWidth: {
            type: String,
            default: ""
        },
        imageHeight: {
            type: String,
            default: ""
        },
        paddingBottom: {
            type: String,
            default: ""
        },
        dontHide: {
            type: Boolean,
            default: false
        }
    },
    data() {
        return {
            options: {
                responsive: [
                    {end: 640, size: 1.2},
                    {start: 641, end: 767, size: 2.5},
                    {start: 768, end: 991, size: 2.5},
                    {start: 992, end: 1199, size: 3},
                    {start: 1950, end: 2249, size: 5},
                    {start: 2250, size: 6},
                    {size: 4}
                ]
            }
        }
    },
    computed: {
        ads() {
            if(this.dontHide) {
                let ads = []

                if(this.imageSize == "full") ads = [{}]
                else if(this.imageSize == "medium") ads = [{}, {}, {}, {}, {}]
                else if(this.imageSize == "large") ads = [{}, {},{}]
                else if(this.imageSize == "custom") ads = [{}, {}]

                ads.forEach(ad => {
                    ad.key = this.areaId
                })

                return ads
            }
            else {
                let adsObj = this.$store.getters["Global/advertisementBanners"]
                if(adsObj[this.areaId]) return adsObj[this.areaId]
                else return []
            }
        }
    },
    methods: {
        clicked(ad) {
            if(ad.id) {
                PageBuilder.api().bannerClick({id: ad.id})
            }
        }
    }
}
</script>

<style>

</style>