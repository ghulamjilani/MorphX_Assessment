<template>
    <div>
        <div class="homePage__Banner">
            <div
                :class="{'homePage__scroll__active' : isScrolled, 'homePage__scroll__mobile' : isMenuOpen}"
                class="homePage__scroll">
                <scrollactive
                    ref="scrollactive_el"
                    :duration="800"
                    :offset="offsetScroll"
                    active-class="active"
                    bezier-easing-value=".5,0,.35,1"
                    class="mChannel__tiles__nav">
                    <div
                        v-if="pageTemplateBody"
                        class="homePage__scroll__div">
                        <a
                            v-for="item in pageTemplateBody"
                            v-show="item.props.show && item.props.title && item.props.title !== ''"
                            :key="item.key"
                            class="btn btn__reset scrollactive-item mChannel__tiles__nav__items"
                            :href="'#' + item.props.href">
                            {{ item.props.title }}
                        </a>
                    </div>
                    <!-- <a
                        v-if="$t('views.home.banner.telegram_link') != 'views.home.banner.telegram_link'"
                        v-tooltip="{ content: mobile ? '' : 'Join us on telegram', classes: ['homePage__telegram__tooltip'] }"
                        class="homePage__telegram__wrapper"
                        :href="$t('views.home.banner.telegram_link')"
                        target="_blank">
                        <span
                            class="homePage__telegram">
                            <m-icon
                                size="1.4rem">
                                GlobalIcon-telegram-vector
                            </m-icon>
                        </span>
                    </a> -->
                </scrollactive>
            </div>
        </div>
    </div>
</template>

<script>

export default {
    components: {},
    props: {
        group: String
    },
    data() {
        return {
            offsetScroll: 0,
            isScrolled: false,
            isMenuOpen: false,
            pageTemplate: null,
            triesToAnchor: 0,
            maxTriesToAnchor: 10
        }
    },
    computed: {
        mobile() {
            return this.$device.mobile()
        },
        pageTemplateBody() {
            return this.pageTemplate?.body?.components
        }
    },
    mounted() {
        this.pageTemplate = window.list_of_templates?.find(e => e.name === this.group)
        if(this.pageTemplate) {
            if(typeof this.pageTemplate.body === String || typeof this.pageTemplate.body == 'string') {
                this.pageTemplate.body = JSON.parse(this.pageTemplate.body)
            }
            window.pageTemplatebody = this.pageTemplate.body
            this.pageTemplate.body.components.sort((a, b) => { return a.order - b.order })
            this.pageTemplate.body.components.forEach(e => {
                e.props.show = false
                if(e.props.title) e.props.href = e.props.title.toLowerCase().replace(/ /g, '_').replace(/[^A-Z0-9]/ig, "_")
            })
        }

        // check all rows by load
        this.checkTemplates()
        // update if cabel loading or long query
        setInterval(() => { this.checkTemplates() }, 1000)

        this.offsetScrollMath()
        window.addEventListener('resize', () => {
            this.offsetScrollMath()
        })
        this.$eventHub.$on("isMobileMenuSwitched", (isMenuOpen) => {
            if (!isMenuOpen) {
                setTimeout(() => {
                    this.isMenuOpen = isMenuOpen
                }, 230)
            } else {
                this.isMenuOpen = isMenuOpen
            }

        })
        window.addEventListener('scroll', this.mobileScroll)

        this.$eventHub.$on('home-page:scroll__uploads', (value) => {
            this.uploads = value
            this.$nextTick(() => {
                this.offsetScrollMath()
            })
        })

        setTimeout(() => {
            this.moveToAnchor()
        }, 1000)
    },
    methods: {
        calculateOffsetScrollMath() {
            let el = document.querySelector('.homePage__scroll')
            if (!el) return
            this.offsetScroll = (document.querySelector('.header__container').offsetHeight + el.offsetHeight)
        },
        offsetScrollMath() {
            let el = document.querySelector('.homePage__scroll')
            if (!el) return
            this.offsetScroll = (document.querySelector('.header__container').offsetHeight + el.offsetHeight)
            if (document.querySelector('.scrollactive-nav') && document.querySelector('.scrollactive-nav').querySelector('.active')) {
                document.querySelector('.scrollactive-nav').querySelector('.active').scrollIntoViewIfNeeded()
            }
        },
        mobileScroll() {
            if (!this.offsetScroll) {
                this.offsetScrollMath()
            }
            this.isScrolled = window.scrollY > 0
            if (this.$device.mobile() && document.querySelector('.scrollactive-nav') && document.querySelector('.scrollactive-nav').querySelector('.active')) {
                document.querySelector('.scrollactive-nav').querySelector('.active').scrollIntoViewIfNeeded()
            }
        },
        checkTemplates() {
            this.pageTemplate.body.components.forEach(t => {
                if(!t.props.title || document.querySelector("#" + t.props.href.replace(/[^A-Z0-9]/ig, "_"))) {
                    t.props.show = true
                }
                else if(t.props.href) {
                     t.props.show = false
                }
            })
            this.calculateOffsetScrollMath()
        },
        moveToAnchor() {
            setTimeout(() => {
                let anchor = location.hash
                if (anchor) {
                    let el = document.querySelector(anchor)
                    if (el) {
                        this.$refs.scrollactive_el.scrollToHashElement()
                        setTimeout(() => {
                            window.scrollBy(0, 10)
                        }, 100)
                        this.triesToAnchor = this.maxTriesToAnchor
                    }
                    else {
                        if (this.triesToAnchor < this.maxTriesToAnchor) {
                            this.triesToAnchor++
                            this.moveToAnchor()
                        }
                    }
                }
            }, 500)
        }
    }
}
</script>