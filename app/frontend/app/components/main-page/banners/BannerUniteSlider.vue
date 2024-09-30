<template>
    <section class="banner__section">
        <div class="banner__imgWrapper">
            <div
                class="banner__imgWrapper__img"
                @click="scrollIntoView('most_recent')">
                <div class="banner__imgWrapper__img__slider first-slider">
                    <img
                        v-for="e in [1,2,3,4]"
                        :key="e"
                        :src="$img['US__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>Latest</span>
                    view most recent
                </div>
            </div>
            <div
                class="banner__imgWrapper__img"
                @click="scrollIntoView('live')">
                <div class="banner__imgWrapper__img__slider second-slider">
                    <img
                        v-for="e in [5,6,7,8]"
                        :key="e"
                        :src="$img['US__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>Upcoming</span>
                    plan to attend
                </div>
            </div>
            <div
                class="banner__imgWrapper__img"
                @click="scrollIntoView('trending')">
                <div class="banner__imgWrapper__img__slider third-slider">
                    <img
                        v-for="e in [9,10,11,12]"
                        :key="e"
                        :src="$img['US__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>Popular</span>
                    watch what's trending
                </div>
            </div>
            <div
                class="banner__imgWrapper__img"
                @click="scrollIntoView('channels')">
                <div class="banner__imgWrapper__img__slider fourth-slider">
                    <img
                        v-for="e in [13,14,15,16]"
                        :key="e"
                        :src="$img['US__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>Channels</span>
                    explore our creators
                </div>
            </div>
        </div>
    </section>
</template>

<script>
export default {
  methods: {
    scrollIntoView(id) {
      const yOffset = -150
      const element = document.getElementById(id)
      if(!element) return
      const y = element.getBoundingClientRect().top + window.pageYOffset + yOffset
      window.scrollTo({top: y, behavior: 'smooth'})
    }
  }
}
</script>

<style lang="scss" scoped>
@import "../../../../../assets/stylesheets/mixin.scss";

.banner {
    &__section {
        max-width: 96%;
        margin: 0 auto;
        @include flex(flex, center, center);
        @include media(desktop) {
            overflow-y: hidden;
            overflow-x: scroll;
            position: relative;
            height: 50rem;
            &::-webkit-scrollbar {
                display: none;
            }
        }
    }

    &__text {
        position: absolute;
        padding: 0 1rem 2.1rem 2rem;
        bottom: 0;
        font-size: 1.8rem;
        color: #fff;
        z-index: 19;
        font-weight: bold;

        span {
            font-size: 3.9rem;
            line-height: 4rem;
            font-weight: 900;
            color: #fff;
            display: inline-block;
            width: 100%;
        }

        // @include media(desktop) {
        //     padding: 0 0.5rem 1rem 0.5rem;
        //     font-size: 1.2rem;
        //     span {
        //         font-size: 2.8rem;
        //         line-height: 2.8rem;
        //     }
        // }
    }

    &__imgWrapper {
        display: flex;
        flex-direction: row;
        align-content: space-between;
        padding-top: 1.3rem;
        padding-bottom: 1.2rem;
        width: 128rem;
        transition: transform 0.3s ease 0s;
        @include media(desktop) {
            left: 1rem;
            position: absolute;
            will-change: transform;
        }
        @include media(phone) {
            left: 0rem;
        }

        &__img {
            width: 29rem;
            height: 50rem;
            padding: 0.1rem;
            position: relative;
            margin: 2rem 1.5rem;
            overflow: hidden;
            cursor: pointer;
            transition: .5s;
            @include media(tablet) {
                margin: 1rem;
            }

            @include media(reverso-desktop) {
                &:hover {
                    transform: translateY(1rem);
                }
            }

            &__slider {
                position: absolute;
                display: flex;
                flex-direction: column;
                width: 100%;
                top: 0;
                left: 0;
                border-radius: 1.9rem;
                transition: top 1s ease;
                will-change: top;

                img {
                    object-fit: cover;
                    width: 29rem;
                    height: 50rem;
                    filter: brightness(0.6);
                }

                animation: animatedBanner 24s ease-in-out infinite;

                &.first-slider {
                    animation-delay: 4s;
                }

                &.second-slider {
                    animation-delay: 5s;
                }

                &.third-slider {
                    animation-delay: 6s;
                }

                &.fourth-slider {
                    animation-delay: 7s;
                }
            }
        }
    }
}
</style>