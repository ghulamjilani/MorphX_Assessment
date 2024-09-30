<template>
    <section class="banner__section">
        <div class="banner__imgWrapper">
            <a
                class="banner__imgWrapper__img"
                href="/search?ford=new&ft=Session">
                <div class="banner__imgWrapper__img__slider first-slider">
                    <img
                        v-for="e in [1,5,9,13]"
                        :key="e"
                        :src="$img['HP__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>{{ $t('home_page.banner.discover') }}</span>
                    {{ $t('home_page.banner.live_experiences') }}
                </div>
            </a>
            <a
                class="banner__imgWrapper__img"
                href="/search?utf8=✓&ford=views_count&ft=Video">
                <div class="banner__imgWrapper__img__slider second-slider">
                    <img
                        v-for="e in [2,6,10,14]"
                        :key="e"
                        :src="$img['HP__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>{{ $t('home_page.banner.relive') }}</span>
                    {{ $t('home_page.banner.great_sessions') }}
                </div>
            </a>
            <a
                class="banner__imgWrapper__img"
                href="/search?utf8=✓&ford=rank&ft=Channel">
                <div class="banner__imgWrapper__img__slider third-slider">
                    <img
                        v-for="e in [3,7,11,15]"
                        :key="e"
                        :src="$img['HP__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>{{ $t('home_page.banner.explore') }}</span>
                    {{ $t('home_page.banner.variety_of_original_content') }}
                </div>
            </a>
            <a
                class="banner__imgWrapper__img"
                href="/search?utf8=✓&ford=rank&ft=User">
                <div class="banner__imgWrapper__img__slider fourth-slider">
                    <img
                        v-for="e in [4,8,12,16]"
                        :key="e"
                        :src="$img['HP__' + e]"
                        alt>
                </div>
                <div class="banner__text">
                    <span>{{ $t('home_page.banner.find') }}</span>
                    {{ $t('home_page.banner.your_next_favorite_teacher') }}
                </div>
            </a>
        </div>
    </section>
</template>

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
            color: var(--tp__active);
            display: inline-block;
            width: 100%;
        }

        @include media(desktop) {
            padding: 0 0.5rem 1rem 0.5rem;
            font-size: 1.2rem;
            span {
                font-size: 2.8rem;
                line-height: 2.8rem;
            }
        }
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

            &:hover {
                transform: translateY(1rem);
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