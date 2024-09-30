<template>
    <div
        v-if="adsList.length > 0 && adsList.length != hiddenAds.length"
        class="bannerAdvertisement adbutler"
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
            :items="adsList"
            :options="options">
            <template #default="{item}">
                <div
                    :id="`placement2_${item.key}`"
                    :key="item.id"
                    target="_blank"
                    class="bannerAdvertisement__ad"
                    :class="['bannerAdvertisement__ad__' + imageSize, {hidden: hiddenAds.includes(item.key)}]"
                    v-show="!hiddenAds.includes(item.key)">
                    <h1 v-if="dontHide">{{ item.key }}</h1>
                </div>
            </template>
        </vue-horizontal-list>
        <div
            class="bannerAdvertisement__ads"
            :class="{'dontHide': dontHide}">
            <!-- :style="`width: 100%; height: 0; padding-bottom: ${paddingBottomCalc}; background-image: url('${ad && ad.file ? ad.file.url : ''}')`" -->
            <!-- :href="ad.url" -->
            <div
                v-for="(ad, index) in adsList"
                :key="index"
                :id="'placement_' + ad.key"
                target="_blank"
                class="bannerAdvertisement__ad"
                :class="'bannerAdvertisement__ad__' + imageSize"
                v-show="!hiddenAds.includes(ad.key)">
                <!-- <img :src="ad && ad.file ? ad.file.url : ''" alt="ad" @load="imageLoaded(ad)" :id="'item' + ad.key" /> -->
                <h1 v-if="dontHide">{{ ad.key }}</h1>
            </div>
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
        accountId: {
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
        },
        ads: {
            type: Array,
            default: () => []
        }
    },
    data() {
        return {
            options: {
                responsive: [
                    {end: 640, size: 2.5},
                    {start: 641, end: 767, size: 2.5},
                    {start: 768, end: 991, size: 2.5},
                    {start: 992, end: 1199, size: 3},
                    {start: 1950, end: 2249, size: 5},
                    {start: 2250, size: 6},
                    {size: 4}
                ]
            },
            hiddenAds: []
        }
    },
    computed: {
        adsList() {
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
                // let adsObj = this.$store.getters["Global/advertisementBanners"]
                // if(adsObj[this.areaId]) return adsObj[this.areaId]
                // else return []

                // https://servedbyadbutler.com/go2/;ID='+accountId+';size=1254x348;setID=' + adKey
                // https://servedbyadbutler.com/adserve/;ID='+accountId+';size=1254x348;setID=' + adKey + ';type=img'

                // .filter(ad => !this.hiddenAds.includes(ad))
                let ads = this.ads.map((ad, index) => {
                    return {
                        id: index,
                        key: ad,
                        hidden: false
                        // url: `https://servedbyadbutler.com/go2/;ID=${this.accountId};setID=${ad}`,
                        // file: {
                        //     url: `https://servedbyadbutler.com/adserve/;ID=${this.accountId};setID=${ad};type=img`
                        // }
                    }
                })

                return ads

            }
        },
        paddingBottomCalc() {
            console.log(parseInt(this.imageWidth), parseInt(this.imageWidth) / parseInt(this.imageHeight))
            return this.paddingBottom ? this.paddingBottom : `calc(100% / ${(parseInt(this.imageWidth) / parseInt(this.imageHeight))})`
        }
    },
    mounted() {
        var adb = window.AdButler || {}
        adb.ads = adb.ads || []

        this.adsList.forEach(ad => {
            adb.ads.push({
                handler: (opt) => {
                    adb.register(this.accountId, ad.key, [800, 800], `placement_${ad.key}`, opt)
                },
                opt: {
                    place: 0,
                    keywords: '',
                    domain: 'servedbyadbutler.com',
                    click: 'CLICK_MACRO_PLACEHOLDER'
                }
            })
            adb.ads.push({
                handler: (opt) => {
                    adb.register(this.accountId, ad.key, [800, 800], `placement2_${ad.key}`, opt)
                    setTimeout(() => {
                        this.checkAd(ad.key)
                    }, 2000)
                },
                opt: {
                    place: 0,
                    keywords: '',
                    domain: 'servedbyadbutler.com',
                    click: 'CLICK_MACRO_PLACEHOLDER'
                }
            })
        })
    },
    methods: {
        clicked(ad) {
            if(ad.id) {
                PageBuilder.api().bannerClick({id: ad.id})
            }
        },
        imageLoaded(item) {
            let img = document.getElementById('item' + item.key)
            if(img.naturalWidth <= 10) {
                item.hidden = true // not working
                this.hiddenAds.push(item.key)
            }
        },
        checkAd(key) {
            let img = document.querySelector(`#placement2_${key} img`)
            console.log(key, img);
            if(!img ) {
                this.hiddenAds.push(key)
            }
        }
    }
}
</script>

<style>

</style>
