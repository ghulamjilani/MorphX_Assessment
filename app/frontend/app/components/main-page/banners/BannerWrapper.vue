<template>
    <div>
        <div class="homePage__Banner">
            <component :is="bannerName" />
        </div>
    </div>
</template>

<script>
import BannerJoybee from './BannerJoybee'
import BannerUnite from './BannerUnite'
import BannerUniteVideo from './BannerUniteVideo'
import BannerUniteSlider from './BannerUniteSlider'

export default {
    components: {BannerJoybee, BannerUnite, BannerUniteVideo, BannerUniteSlider},
    props: {
        group: String
    },
    data() {
        return {

        }
    },
    computed: {
        bannerName() {
            return 'banner-' + this.homeBanner?.toLowerCase()
        },
        homeBanner() {
            return this.$railsConfig?.frontend?.home_banner ? this.$railsConfig.frontend.home_banner : "Unite"
        },
        mobile() {
            return this.$device.mobile()
        }
    }
}
</script>