<template>
    <div class="statContainer">
        <div
            v-if="usedStoragePercentage >= 80"
            class="statContainer__banner banner margin-bottom-30">
            <div class="message bold fs-14">
                Storage is {{ usedStoragePercentage }}% full.
                Available storage {{ gb(statistics.used_storage) }}GB / {{ current_plan.storage }}GB
            </div>
            <button class="expand">
                Expand Storage
            </button>
        </div>
        <div class="statContainer__common-statistics main-content-section">
            <div class="company">
                <img
                    :src="organization.logo_url"
                    alt="Company logo"
                    class="company__logo">
                <div class="company__company_info">
                    <div class="company_name">
                        {{ organization.name }}
                    </div>
                    <div
                        v-if="true"
                        class="company_rating">
                        <div
                            :title="`${organization.rating}/5`"
                            class="display-inline-block vertical-midle"
                            rel="tipsy">
                            <ul class="starRating clearfix">
                                <li
                                    v-for="index in 5"
                                    :key="index">
                                    <div
                                        v-if="roundedRating - index >= 0"
                                        class="VideoClientIcon-starF" />
                                    <div
                                        v-else-if="roundedRating - index < 0 && roundedRating - index > -1"
                                        class="VideoClientIcon-star-half-altF" />
                                    <div
                                        v-else
                                        class="VideoClientIcon-star-emptyF" />
                                </li>
                            </ul>
                        </div>
                        <!-- TODO: Add stars -->
                        <span class="total text-color-Darkgrey">{{ organization.rating }} (from {{ organization.voted }} Ratings)</span>
                    </div>
                </div>
            </div>

            <div class="plan-info padding-bottom-25">
                <div class="plan-info__wrapper">
                    <div class="subs-item fs-16">
                        Subscription:
                        <span class="bold text-color-Darkgrey">{{ current_plan.name }}</span>
                    </div>
                    <div class="indicator-wrap">
                        <div class="indicator-wrap__indicator-text">
                            <div class="indicator-text_left fs-12 bold">
                                Disk Space {{ usedStoragePercentage }}% Full
                            </div>
                            <div class="indicator-text_right fs-12 bold">
                                Available storage: {{ gb(statistics.used_storage) }}GB / {{ current_plan.storage }}GB
                            </div>
                        </div>
                        <div class="indicator-space">
                            <div
                                :style="`width: ${usedStoragePercentage}%`"
                                class="space" />
                        </div>
                    </div>
                </div>
                <div class="plan-info__wrapper">
                    <div class="plan_subscription plan-item indicator-wrap">
                        <div class="indicator-wrap">
                            <div class="indicator-text_left fs-12 bold">
                                Live Minutes: {{ minutes(statistics.used_streaming_seconds) }}/{{
                                    current_plan.streaming_time
                                }}
                            </div>
                            <div class="indicator-space">
                                <div
                                    :style="`width: ${usedLiveMinutesPercentage}%`"
                                    class="space space-gradient" />
                            </div>
                        </div>
                    </div>
                    <div class="plan_subscription plan-item indicator-wrap margin-top-20">
                        <div class="indicator-text">
                            <div class="indicator-text_left fs-12 bold">
                                Replay Minutes: {{ minutes(statistics.used_transcoding_seconds) }}/{{
                                    current_plan.transcoding_time
                                }}
                            </div>
                        </div>
                        <div class="indicator-space">
                            <div
                                :style="`width: ${usedTranscodingMinutesPercentage}%`"
                                class="space space-gradient" />
                        </div>
                    </div>
                </div>
            </div>

            <div class="plan-details-wrapper">
                <div class="details-wrapper">
                    <i class="VideoClientIcon-film margin-right-15" />
                    <div class="wrap">
                        <div class="plan-details-item_info_main-text text-color-Darkgrey">
                            <span class="bold">{{ statistics.channels_count }}</span> Channels
                        </div>
                        <div class="plan-details-item_info_secondary-text fs-12 text-color-LightGrey">
                            <span>{{ statistics.past_sessions_count }}</span> sessions
                        </div>
                    </div>
                </div>

                <div class="details-wrapper">
                    <i class="VideoClientIcon-video1 margin-right-15" />
                    <div class="wrap">
                        <div class="plan-details-item_info_main-text text-color-Darkgrey">
                            <span class="bold">{{ statistics.past_sessions_count }}</span> Sessions
                        </div>
                        <div class="plan-details-item_info_secondary-text fs-12 text-color-LightGrey">
                            <span>{{ minutes(statistics.used_streaming_seconds) }} min.</span> streamed
                        </div>
                    </div>
                </div>

                <div class="details-wrapper">
                    <i class="VideoClientIcon-play-circle margin-right-15" />
                    <div class="wrap">
                        <div class="plan-details-item_info_main-text text-color-Darkgrey">
                            <span class="bold">{{ statistics.replays_count }}</span> Replays
                        </div>
                        <div class="plan-details-item_info_secondary-text fs-12 text-color-LightGrey">
                            <span>{{ gb(statistics.used_storage) }}GB used /</span> {{ current_plan.storage }}GB
                        </div>
                    </div>
                </div>

                <div class="details-wrapper">
                    <i class="VideoClientIcon-disc margin-right-15" />
                    <div class="wrap">
                        <div class="plan-details-item_info_main-text text-color-Darkgrey">
                            <span class="bold">{{ statistics.recording_count }}</span> Recordings
                        </div>
                        <div class="plan-details-item_info_secondary-text fs-12 text-color-LightGrey">
                            <span>{{ gb(statistics.recordings_storage) }}GB used /</span> {{ current_plan.storage }}GB
                        </div>
                    </div>
                </div>

                <div class="details-wrapper">
                    <i class="VideoClientIcon-PeopleMK2 margin-right-15" />
                    <div class="wrap">
                        <div class="plan-details-item_info_main-text text-color-Darkgrey">
                            <span class="bold">{{ statistics.creators_count }}</span> {{ $t('dictionary.creators_upper') }}
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="statistics-container_channel-list main-content-section margin-top-30">
            <div class="text-color-secondary fs-22 bold margin-bottom-30">
                Channels
            </div>
            <div class="wpoper">
                <statistics-channel
                    v-for="(channel, index) in channels"
                    :key="index"
                    :channel="channel" />
            </div>
        </div>
    </div>
</template>

<script>
import StatisticsChannel from "@components/statistics/StatisticsChannel"
import {mapActions, mapState} from 'vuex'

export default {
    components: {StatisticsChannel},
    data() {
        return {}
    },
    computed: {
        ...mapState("Statistics", [
            'organization',
            'current_plan',
            'channels',
            'statistics'
        ]),

        usedStoragePercentage() {
            return parseInt((this.gb(this.statistics.used_storage) / this.current_plan.storage) * 100)
        },

        usedLiveMinutesPercentage() {
            return parseInt((this.statistics.used_streaming_seconds / this.current_plan.streaming_time) * 100)
        },

        usedTranscodingMinutesPercentage() {
            return parseInt((this.statistics.used_transcoding_seconds / this.current_plan.transcoding_time) * 100)
        },

        roundedRating() {
            return Math.ceil(this.organization.rating * 2) / 2
        }
    },
    async created() {
        await this.getStatistics()
    },
    methods: {
        ...mapActions("Statistics", ["getStatistics"]),

        minutes(sec) {
            return parseInt(sec / 60)
        },

        gb(b) {
            return b / 1024 ^ 3
        }
    }
}
</script>

<style lang="scss" scoped>
.statContainer {
    &__banner {
        background: #FFC20A;
        border-radius: 10px;
        padding: 20px 30px;
        display: flex;
        justify-content: space-between;
        align-items: center;

        .message {
            color: #000;
        }

        .expand {
            background: var(--btn__tetriary);
            border-radius: 15px;
            font-size: 13px;
            color: var(--tp__btn__tetriary);
            font-weight: bold;
            padding: 5px 15px;
        }

        @media all and (max-width: 640px) {
            flex-direction: column;
            .expand {
                margin-top: 15px;
            }
        }
    }

    &__common-statistics {
        padding: 30px;

        .company {
            display: flex;
            border-bottom: 1px solid var(--border__separator);
            padding-bottom: 25px;

            &__logo {
                width: 60px;
                height: 60px;
                border-radius: 10px;
                margin-right: 10px;
                border: 2px solid #FFFFFF;
            }

            &__company_info {
                display: flex;
                flex-direction: column;

                .company_name {
                    color: var(--tp__h1);
                    font-size: 22px;
                    font-weight: bold;
                }

                .company_rating {
                    .starRating {
                        letter-spacing: 0;
                    }
                }
            }

            @media all and (max-width: 640px) {
                flex-direction: column;
                align-items: center;
                border: none;
                .company_name {
                    text-align: center;
                }
            }
        }
    }

    .plan-info {
        padding-top: 20px;
        display: flex;
        justify-content: space-between;

        &__wrapper {
            display: flex;
            flex-direction: column;
            width: 41%;
            justify-content: space-between;

            .subs-item {
                background: var(--bg__secondary);
                border-radius: 5px;
                padding: 5px;
                width: max-content;
                margin-bottom: 15px;
                flex-wrap: wrap;
            }

            .indicator-wrap {
                display: flex;
                flex-direction: column;

                &__indicator-text {
                    display: flex;
                    justify-content: space-between;
                    text-transform: uppercase;
                }

                .indicator-space {
                    background: #EDEDED;
                    border-radius: 20px;
                    height: 5px;
                    margin-top: 5px;

                    .space {
                        max-width: 100%;
                        background-color: #37A67D;
                        border-radius: 20px;
                        height: inherit;
                    }

                    .space-gradient {
                        background: linear-gradient(90deg, #FFC20A 55.83%, rgba(242, 53, 53, 0.72) 95.41%);
                    }
                }
            }
        }

        @media all and (max-width: 640px) {
            flex-direction: column;
            align-items: center;
            &__wrapper {
                width: 100%;

                &:last-child {
                    margin-top: 25px;
                }
            }
        }
    }

    .plan-details-wrapper {
        display: flex;
        background: var(--bg__secondary);
        border: 1px solid var(--border__content__sections);
        padding: 30px;
        box-sizing: border-box;
        border-radius: 10px;
        justify-content: flex-start;
        flex-wrap: wrap;
        position: relative;
        @media all and (max-width: 500px) {
            flex-direction: column;
            .details-wrapper {
                width: 100%;
            }
        }

        .details-wrapper {
            display: flex;
            padding-bottom: 20px;
            padding-right: 30px;
            @media all and (min-width: 768px) and (max-width: 1199px) {
                width: 33%;
            }
        }

        i {
            font-size: 22px;
            position: relative;
            color: var(--btn__main);
        }
    }

    @media all and (max-width: 767px) {
        .wpoper {
            display: flex;
        }
        .details-wrapper {
            width: 50%;
        }
    }
    @media all and (max-width: 500px) {
        .wpoper {
            flex-direction: column;
        }
    }
}
</style>