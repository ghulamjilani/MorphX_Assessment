<template>
    <div
        id="mf-landing"
        class="mf__landing">
        <div class="mf__landing__banner">
            <div class="mf__landing__banner__videoBg">
                <video
                    autoplay="true"
                    loop="true"
                    muted="muted"
                    src="images/landing/background_crop.mp4"
                    type="video/mp4" />
            </div>
            <div class="mf__landing__header">
                <div>
                    <img
                        alt=""
                        src="images/landing/logo.png">
                </div>
                <div>
                    <button
                        v-show="forSignUp"
                        class="mf__landing__btn__solid start_wizard">
                        Sign Up
                    </button>
                    <button class="mf__landing__btn__bordered start_wizard_login">
                        Log In
                    </button>
                </div>
            </div>
            <div class="mf__landing__redBlock">
                <h1>Powering the next wave</h1>
                <h2>in global media, audience engagement, & commerce on one unified platform  </h2>
            </div>
            <div class="mf__landing__banner__content">
                The Enklav platform enables content creators to provide a unified audience experience across the content
                they produce, community they develop, and commerce they transact
                <div>
                    <!--          <button class="btn-red start_wizard">Ride the wave</button>-->
                    <a
                        class="btn btn__main btn__l btn__square"
                        href="https://share.hsforms.com/1yUf4iz3hRmu9oVWKUxVqQQ51y5r"
                        target="_blank">Ride the wave</a>
                </div>
            </div>
        </div>
        <div class="mf__landing__line-1">
            <div class="mf__landing__sectionWrapp">
                <div class="mf__landing__line-1__label">
                    <h2>Disruption is here. Industries are transforming.</h2>
                    Whether you are new media company, enterprise business, or global content producer (movie studios,
                    music creators, games studio) engaging your audience requires the same core elements
                </div>
                <div class="mf__landing__line-1__content">
                    <div>
                        <div class="mf__landing__redSmallBlock">
                            <img
                                alt=""
                                src="images/landing/content__line__1-1.png">
                            <div>SCALE</div>
                        </div>
                        <span>Engage your audience globally without fear of scale</span>
                    </div>
                    <div>
                        <div class="mf__landing__redSmallBlock">
                            <img
                                alt=""
                                src="images/landing/content__line__1-2.png">
                            <div>Interact</div>
                        </div>
                        <span>Create community around the content and brand to drive interactions with your audience</span>
                    </div>
                    <div>
                        <div class="mf__landing__redSmallBlock">
                            <img
                                alt=""
                                src="images/landing/content__line__1-3.png">
                            <div>Transact</div>
                        </div>
                        <span>Create frictionless transactions integrated with your content, generate greater revenues by better meeting your audience needs</span>
                    </div>
                    <div>
                        <div class="mf__landing__redSmallBlock">
                            <img
                                alt=""
                                src="images/landing/content__line__1-4.png">
                            <div>UNDERSTAND</div>
                        </div>
                        <span>Develop deep understanding and contextual analytics around all audience interactions, reactions, and transactions to create further value</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="mf__landing__line-2 mf__landing__sectionWrapp">
            <div class="mf__landing__line-2__label ">
                Features
            </div>
            <div class="mf__landing__line-2__content">
                <div>
                    <div class="mf__landing__line-2__imgBlock">
                        <img
                            alt=""
                            src="images/landing/content__line__2-1.jpg">
                        <span>Content</span>
                    </div>
                    <div class="mf__landing__line-2__textBlock">
                        <p>
                            The Enklav platform enables creators to provide a full video deployment experience to engage
                            their audience with rent, buy, pay-per view, or interactive real-time capabilities
                        </p>
                        <p>
                            <span class="text-bold">Rent / Buy:</span>
                            <br>
                            Creator branded Netflix or Amazon like experience with streaming rental or purchased
                            downloadable content formats
                        </p>
                        <p>
                            <span class="text-bold">Pay-Per-View:</span>
                            <br>
                            Global premier or recorded content launch capabilities in PPV model
                        </p>
                        <p>
                            <span class="text-bold">Interactive Real-Time:</span>
                            <br>
                            • Webinar, training, or planned live media events<br>
                            • Real-time audience interaction centered around pre-recorded content<br>
                            • Live streaming event content with audience interaction<br>
                            • Non-Censorship clause built into contract
                        </p>
                    </div>
                </div>
                <div>
                    <div class="mf__landing__line-2__imgBlock">
                        <img
                            alt=""
                            src="images/landing/content__line__2-2.jpg">
                        <span>Community</span>
                    </div>
                    <div class="mf__landing__line-2__textBlock">
                        <p>
                            Simplified community development and engagement through direct integrations with all major
                            social platforms
                        </p>
                        <p>
                            Content driven real-time audience engagement with text, posts, polling, reviews, comments,
                            email and chat capabilities
                        </p>
                        <p>
                            Fully immersive audience interaction available across all content types and mediums with
                            group, friends and follows functionality
                        </p>
                        <p>
                            Enhanced signup & content distribution through use of FB, Google, Apple, Twitter, and
                            Instagram social signup
                        </p>
                        <p>
                            Ability to create email campaigns with direct integrations to Mailchimp, Zapier, Constant
                            Contact
                        </p>
                    </div>
                </div>
                <div>
                    <div class="mf__landing__line-2__imgBlock">
                        <img
                            alt=""
                            src="images/landing/content__line__2-3.jpg">
                        <span>Commerce</span>
                    </div>
                    <div class="mf__landing__line-2__textBlock">
                        <p>
                            Creator ability to price to meet audience needs; Subscription, pay-per-view, rental,
                            purchase, or donation payment capabilities
                        </p>
                        <p>
                            Integrated instream merchandising capabilities gives creators the ability to offer special
                            buying opportunities to their audience at point of viewership
                        </p>
                        <p>Automated freemium to paid conversion capabilities</p>
                        <p>Fully integrated across leading payment gateways</p>
                        <p>Integrated payment, pricing, and transactional analytics across all audience interactions</p>
                    </div>
                </div>
            </div>
            <!-- <div class="mf__landing__line-2__footer text-center">
        <button class="btn-red start_wizard">Give them a try</button>
      </div> -->
        </div>
        <div class="mf__landing__line-3 mf__landing__sectionWrapp">
            <div class="mf__landing__line-3__label">
                Dedicated for
            </div>
            <div class="mf__landing__line-3__content">
                <div class="mf__landing__line-3__section">
                    <div
                        class="mf__landing__line-3__section__left"
                        style="background-image: url('/images/landing/content__line__3-1.jpg')" />
                    <div class="mf__landing__line-3__section__right">
                        <h5>Emerging Media Brands & Creators</h5>
                        <h6>Individual content creators are becoming the new media.</h6>
                        <div class="mf__landing__line-3__section__content">
                            <div>
                                Unify all digital experiences (content, community development, interactions, &
                                transactions) on one platform with full content
                                distribution, subscription, & monetization capabilities 
                            </div>
                            <div>
                                Better manage, direct, and analyze audience engagement pre/during/post engagement & turn
                                them into customers with
                                integrated community development & social video features
                            </div>
                            <div>
                                Full ownership of contextual data around all audience interactions, reactions, &
                                transactions
                            </div>
                            <div>
                                Generate higher margin and faster time to revenue for all digital assets
                            </div>
                            <div>
                                Instream merchandising capabilities give the ability to buy digital assets, merchandise,
                                or goods directly at time of viewership
                            </div>
                            <div>No “Brand” bleed by using FB or YouTube as your core platform</div>
                            <div>Own all your core user & audience data</div>
                            <div>
                                Greater operational efficiencies not having to work across multiple platforms
                            </div>
                            <div>Non-Censorship clause</div>
                        </div>
                    </div>
                </div>
                <div class="mf__landing__line-3__section">
                    <div
                        :style="`background-image: url('/images/landing/content__line__3-${tabBusiness === 0 ? 2 : 3}.jpg')`"
                        class="mf__landing__line-3__section__left" />
                    <div class="mf__landing__line-3__section__right">
                        <h5>Enterprise business</h5>
                        <h6>
                            Enterprise companies find themselves in the position of serving both external, & internal
                            audiences with increasing needs around the external buyer lifecycle and internally around
                            training & event services which are now primarily driven through video-based mediums.
                        </h6>
                        <div class="mf__landing__tab__nav">
                            <button
                                :class="{'active': tabBusiness === 0}"
                                class="btn__reset"
                                @click="tabBusiness = 0">
                                External to business
                            </button>
                            <button
                                :class="{'active': tabBusiness === 1}"
                                class="btn__reset"
                                @click="tabBusiness = 1">
                                Internal to business
                            </button>
                        </div>
                        <div>
                            <div
                                v-show="tabBusiness === 0"
                                class="mf__landing__tab mf__landing__line-3__section__content">
                                <div>
                                    Ability to unify all digital experiences (audience focused content, community
                                    development, interactions, & transactions) on one platform with full content
                                    distribution, subscription, & monetization capabilities
                                </div>
                                <div>
                                    Better manage, direct, and analyze audience engagement pre/during/post engagement &
                                    turn them into customers with integrated online community development & social video
                                    engagement features
                                </div>
                                <div>
                                    Create regional “channels” for geographic offices to engage and sell to their
                                    audiences (Real estate, beauty, education, etc.)
                                </div>
                                <div>
                                    Full ownership of contextual data around all audience interactions, reactions, &
                                    transactions 
                                </div>
                                <div>Generate higher margin and faster time to revenue for your products</div>
                                <div>
                                    Instream merchandising capabilities give the ability to buy digital assets,
                                    merchandise, or goods directly at time of viewership
                                </div>
                                <div>
                                    No “Brand” bleed by using FB or YouTube as your core platform
                                </div>
                                <div>
                                    Own all your core user & audience data
                                </div>
                            </div>
                            <div
                                v-show="tabBusiness === 1"
                                class="mf__landing__tab mf__landing__line-3__section__content">
                                <div>Stream content as scheduled events</div>
                                <div>
                                    Develop specific channels to deploy internal corporate content & build employee
                                    feedback around the content
                                </div>
                                <div>Build Integrated on-demand model</div>
                                <div>Online community & interactive employee engagement during livestream events</div>
                                <div>
                                    Multiuser mode: Different users can use the application on the same PC 
                                </div>
                                <div>Off-line\On-line modes: Depending on network status and server resources</div>
                                <div>Integrated analytics</div>
                                <div>
                                    Unified platform for all internal audience engagement & training 
                                </div>
                                <div>
                                    Better manage, direct, and analyze employee engagement pre/during/post training &
                                    viewership 
                                </div>
                                <div>
                                    Ability to create & own internal corporate community development / social
                                    engagement around the content and contextual analytics
                                </div>
                                <div>Instream communications focused on content at time of viewership</div>
                                <div>Ability for audience to control and manage their experience</div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="mf__landing__line-3__section">
                    <div
                        class="mf__landing__line-3__section__left"
                        style="background-image: url('/images/landing/content__line__3-4.jpg')" />
                    <div class="mf__landing__line-3__section__right">
                        <h5>Movie Premiere or Music Launch</h5>
                        <h6>
                            Movies, musical acts, & other forms of digital content are having to seek diverse ways to
                            promote & distribute their content as movie theaters, event venues, & other gathering areas
                            are shuttering their doors for good and people are consuming their content in the comforts
                            of their homes
                        </h6>
                        <div class="mf__landing__line-3__section__content">
                            <div>Stream /play movies as scheduled events in pay per view model</div>
                            <div>
                                Integrated on-demand model with rental & purchase capabilities 
                            </div>
                            <div>
                                Full DRM & encrypted streaming and downloads
                            </div>
                            <div>Online community & social video engagement features (Pre/During/Post)</div>
                            <div>Full screen: Cinema mode</div>
                            <div>
                                Multiuser mode: Different users can use the application on the same PC 
                            </div>
                            <div>
                                Protected video product: Video content is encrypted with AES-128 and licenses are
                                managed by Enklav server 
                            </div>
                            <div>Off-line\On-line modes: Depending on network status and server resources</div>
                            <div>Integrated analytics</div>
                            <div>
                                Ability to have a laptop act as a DRM protected digital content projector in
                                conjunction with EnklavTV app
                            </div>
                            <div>
                                Own & control market engagement and distribution of studio assets 
                            </div>
                            <div>
                                Generate higher margin and faster time to revenue for downloadable & rental assets
                            </div>
                            <div>Better manage, direct, and analyze consumer engagement pre/during/post viewership</div>
                            <div>
                                Branded, pre-marketed audience engagement, associated digital content, & merch sales
                                pre & post launch
                            </div>
                            <div>
                                Ability to create & own the community development/social engagement around the movie
                                brand & full analytics ownership & access 
                            </div>
                            <div>
                                Pre-sell tickets with special online actor / director online engagement as a driver
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <!-- <div class="text-center">
        <button class="btn-red">Contact Us</button>
      </div> -->
        </div>
    </div>
</template>

<script>
export default {
    name: "Landing",
    data() {
        return {
            tabBusiness: 0,
            forSignUp: false
        }
    },
    mounted() {
        let params = this.getParams()
        if (params && params.token) {
            this.forSignUp = true
            if ($('#signupPopup')) {
                window.eventHub.$emit("open-modal:auth", "sign-up")
                // $('#signupPopup').modal('show');
            }
        }
    },
    methods: {
        getParams() {
            return window.location.search.slice(1)
                .split('&')
                .reduce(function _reduce(/*Object*/ a, /*String*/ b) {
                    b = b.split('=')
                    a[b[0]] = decodeURIComponent(b[1])
                    return a
                }, {})
        }
    }
}

</script>
<style lang="scss" scoped>
@import "../../assets/styles/core/mixin";

@font-face {
    font-family: 'Chunk';
    src: url('../../assets/fonts/chunk/Chunk.otf');
    //src:url('../../assets/fonts/chunk/Chunk.otf');
    //src:url('../../assets/fonts/chunk/Chunk.ttf') format('truetype');
    font-weight: normal;
    font-style: normal;
}

.mf__landing {
    --tp__main: #fff;


    color: #fff;
    background: #05060B;

    &__sectionWrapp {
        width: 132rem;
        max-width: 90%;
        margin: 0 auto;
    }

    &__banner {
        text-align: center;
        background-image: url("https://morphx.io/images/landing/bg1.jpg");
        background-repeat: no-repeat;
        background-size: cover;
        background-position: center top;
        padding: 20rem 0 1rem;
        position: relative;
        @include media(tablet) {
            padding: 8rem 0 1rem;
        }

        &:before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 10;
            background: linear-gradient(75.82deg, rgba(0, 0, 0, 0.2) 22.4%, rgba(30, 92, 170, 0.4) 100%);
        }

        &__videoBg {
            position: absolute;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            z-index: 1;

            video {
                width: 100%;
                height: 100%;
                object-fit: cover;
            }
        }

        &__content {
            width: 90rem;
            max-width: 90%;
            margin: 0 auto 3rem;
            position: relative;
            z-index: 19;
            font-size: 2.2rem;
        }

        h1 {
            font-size: 7rem;
            padding-top: 3rem;
            padding-bottom: 0rem;
            margin-bottom: 0;
            margin-top: 0;
            @include media(tablet) {
                font-size: 8vw;
            }
        }

        h2 {
            font-size: 33px;
            max-width: 85%;
            margin: .7rem auto 0rem;
            font-family: 'Chunk';
            @include media(tablet) {
                font-size: 4vw;
            }
        }

        .btn {
            text-transform: uppercase;
            font-size: 1.6rem;
            min-width: 20rem;
            text-align: center;
            margin: 11rem 0 0;
            line-height: 5.8rem;
            background: #ff1616; /* static color for enklav landing*/
            border: 1px solid #ff1616;
        }
    }

    &__line-1 {
        background-image: url("https://morphx.io/images/landing/bg2.png");
        background-repeat: no-repeat;
        background-size: cover;
        background-position: center bottom;
        padding: 14rem 0 7rem;
        @include media(tablet) {
            padding: 5rem 0 5rem;
        }

        &__label {
            text-align: center;
            font-size: 18px;
            max-width: 99rem;
            margin: 0 auto;

            h2 {
                text-transform: uppercase;
                font-size: 33px;
                padding: 0 0 1.5rem;
                margin: 0;
                font-family: 'Chunk';
            }
        }

        &__content {
            display: flex;
            flex-direction: row;
            justify-content: space-between;
            align-content: flex-start;
            padding: 11rem 0;
            @include media(tablet) {
                flex-direction: column;
            }
            @include media(phone) {
                padding: 4rem 0 0;
            }

            & > div {
                width: 20rem;
                @include media(tablet) {
                    width: 100%;
                    padding-bottom: 4rem;
                    display: flex;
                    flex-direction: row;
                    justify-content: center;
                    align-items: center;
                }
            }

            span {
                display: inline-block;
                width: 100%;
            }
        }
    }

    &__line-2 {
        &__label {
            text-align: center;
            text-transform: uppercase;
            font-size: 30px;
            padding-bottom: 7rem;
            font-family: 'Chunk';
        }

        &__content {
            @include media(reverso-tablet) {
                display: flex;
                flex-direction: row;
                justify-content: space-between;
                align-content: flex-start;
            }

            & > div {
                background: #282A2C;
                @include media(reverso-tablet) {
                    max-width: 90%;
                    width: 40rem;
                    margin-right: 6rem;
                    &:last-child {
                        margin-right: 0
                    }
                }
                @include media(tablet) {
                    margin-bottom: 4rem;
                }
            }
        }

        &__imgBlock {
            position: relative;
            font-family: 'Chunk';

            img {
                width: 100%;
            }

            span {
                @include center(vh);
                font-size: 2.6rem;
            }
        }

        &__textBlock {
            padding: 4rem 2.8rem;

            p {
                margin-bottom: 1.8rem;
                padding-left: 2rem;
                position: relative;

                &:before {
                    content: '';
                    width: 1rem;
                    height: 1rem;
                    position: absolute;
                    left: 0;
                    top: .8rem;
                    border-radius: 100%;
                    background: var(--siteColorMain);
                }
            }

            .text-bold {
                text-decoration: underline;
                font-weight: bold;
            }
        }

        &__footer {
            padding-top: 4.5rem;

            .btn-red {
                text-transform: uppercase;
                font-size: 1.6rem;
                min-width: 20rem;
                text-align: center;
                line-height: 5.8rem;
            }
        }
    }

    &__line-3 {
        padding: 6rem 0 16rem;

        &__label {
            text-align: center;
            text-transform: uppercase;
            font-size: 30px;
            font-family: 'Chunk';
        }

        &__content {
            padding: 6rem 0 6rem;
        }

        &__section {
            display: flex;
            flex-direction: row;
            align-content: stretch;
            margin-bottom: 6rem;
            background: linear-gradient(90deg, #1A2D3F 0%, #101C27 100%);

            &__left {
                width: 40rem;
                min-width: 40rem;
                max-width: 40%;
                background-repeat: no-repeat;
                background-size: cover;
                background-position: center top;
                @include media(tablet) {
                    width: 8rem;
                    min-width: 8rem;
                }
            }

            &__right {
                padding: 6rem 6rem 5rem;
                @include media(tablet) {
                    padding: 1rem 1rem 1rem;
                }
            }

            &__content {
                div {
                    color: var(--fontColor-main-light);
                    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
                    padding: 1rem 0;
                    font-size: 1.4rem;
                    line-height: 2.1rem;
                }
            }

            h5 {
                font-size: 22px;
                line-height: 150%;
                text-transform: uppercase;
                padding-bottom: 0;
                margin-bottom: 0;
                font-family: 'Chunk';
            }

            h6 {
                font-size: 16px;
                line-height: 150%;
                margin-bottom: 2.5rem;
                padding-top: 0;
                margin-top: 0;
            }
        }

        .btn-red {
            text-transform: uppercase;
            font-size: 1.6rem;
            min-width: 20rem;
            text-align: center;
            line-height: 5.8rem;
        }
    }


    &__redBlock {
        background: rgba(255, 22, 22, .8);
        max-width: 99rem;
        margin: 0 auto 5rem;
        position: relative;
        z-index: 19;
        padding-bottom: 3rem;
        font-family: 'Chunk';
    }

    &__redSmallBlock {
        width: 20rem;
        min-width: 20rem;
        max-width: 90%;
        background: rgba(255, 22, 22, 0.8);
        position: relative;
        text-align: center;
        padding-top: 5rem;
        font-family: 'Chunk';
        @include media(reverso-tablet) {
            margin-bottom: 6rem;
        }
        @include media(tablet) {
            margin-right: 2rem;
            padding-top: 2rem;
        }

        &:before {
            content: '';
            width: 20rem;
            height: 20rem;
            background: rgba(255, 22, 22, 0.4);
            position: absolute;
            left: 1rem;
            top: 1rem;
            z-index: 1;
        }

        @include media(phone) {
            width: 14rem;
            min-width: 14rem;
            height: 14rem;
            &:before {
                width: 14rem;
                height: 14rem;
                left: .5rem;
                top: .5rem;
            }
        }

        img {
            width: 9rem;
            max-width: 90%;
            position: relative;
            z-index: 2;
            @include media(tablet) {
                max-width: 40%;
            }
        }

        div {
            position: relative;
            z-index: 2;
            padding: 2.3rem 0 0;
            font-size: 2.6rem;
            text-transform: uppercase;
            @include media(tablet) {
                padding: 1.5rem 0 0;
                font-size: 1.7rem;
            }
        }
    }

    &__tab {
        &__nav {
            border-bottom: 2px solid #434E5A;
            margin-bottom: 1rem;

            button {
                position: relative;
                bottom: -2px;
                border-bottom: 2px solid transparent;
                font-weight: bold;
                font-size: 18px;
                line-height: 150%;
                text-transform: uppercase;
                color: var(--fontColor-main-light);
                @include media(reverso-phone) {
                    margin-right: 3.8rem;
                }
                @include media(phone) {
                    width: 100%;
                }

                &.active {
                    border-bottom-color: var(--tp__active);
                    color: #FFFFFF;
                }
            }
        }
    }
}


.mf__landing__header {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 10rem;
    padding: 5rem 6rem 0 6rem;
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    z-index: 16;
    @include media(tablet) {
        display: none;
    }

    button {
        min-width: 10rem;
        height: 4rem;
        text-align: center;
        border-radius: 2px;
        border: 1px solid #fff;
        text-transform: uppercase;
        font-size: 14px;
        line-height: 3.8rem;
        margin-top: .5rem;
        margin-left: 2rem;
        @include transition();

        &:hover {
            transform: scale(1.1);
        }

        &.mf__landing__btn {
            &__solid {
                background: #fff;
                color: #000;
            }

            &__bordered {
                color: #fff;
                background: transparent;
            }
        }
    }

    img {
        height: 5rem;
    }
}


.landingPage {
    .header-search-wrapper {
        display: none;
    }

    #container.main-content {
        padding-bottom: 0;
    }

    &.header-top {
        .navbar.navbar-default.transparent {
            background: transparent;
        }
    }
}

@include media(reverso-tablet) {
    .hideDefaultHeader {
        .navbar-default {
            display: none;
        }
    }
    .hideDefaultFooter {
        .footerWrapper {
            display: none;
        }
    }
}

</style>