<template>
    <div class="v-channel">
        <mb-schedule
            v-if="showCalendar"
            :channel_id="channel_id"
            scheduler-for="mbs-organization" />

        <div
            v-if="showSessions"
            id="streamsArea"
            class="ch-p_C_tiles">
            <div class="fs-l text-color-Darkgrey">
                <filters
                    :channel_id="channel_id"
                    for-model="session" />
            </div>
            <tiles-collection
                :channel_id="channel_id"
                class="streams margin-right-0 flex-wrapp"
                for-model="session" />
            <show-more
                :channel_id="channel_id"
                for-model="session" />
        </div>

        <div
            id="videosArea"
            class="ch-p_C_tiles padding-bottom-30">
            <template v-if="showVideos">
                <div class="fs-l text-color-Darkgrey">
                    <filters
                        :channel_id="channel_id"
                        for-model="video" />
                </div>
                <tiles-collection
                    :channel_id="channel_id"
                    class="replays_wrapp margin-right-0 flex-wrapp"
                    for-model="video" />
                <show-more
                    :channel_id="channel_id"
                    for-model="video" />
            </template>

            <template v-if="showRecordings">
                <filters
                    :channel_id="channel_id"
                    for-model="recording" />
                <tiles-collection
                    :channel_id="channel_id"
                    class="recordings_wrapp margin-right-0 flex-wrapp"
                    for-model="recording" />
                <show-more
                    :channel_id="channel_id"
                    for-model="recording" />
            </template>
        </div>
    </div>
</template>

<script>
import TilesCollection from "@components/TilesCollection"
import Filters from "@components/Filters"
import ShowMore from "@components/ShowMore"
import MbSchedule from "@components/mindbodyonline/schedule/MbSchedule"

export default {
    components: {TilesCollection, Filters, ShowMore, MbSchedule},
    props: ["channel_id", "showSessions", "showVideos", "showRecordings", "showCalendar"]
}
</script>

<style lang="scss">
@import "../../../assets/stylesheets/mixin.scss";

.v-channel {
    #streamsArea {
        .show_more {
            margin-top: -7rem;
            @include media(phone) {
                margin-top: -4rem;
            }
        }

        .spinnerSliderVue {
            margin-top: -7rem;
            @include media(phone) {
                margin-top: -2.8rem;
            }
        }
    }

    #videosArea {
        .show_more {
            margin-top: -4rem;
            @include media(phone) {
                margin-top: 0px;
            }
        }

        .spinnerSliderVue {
            margin-top: -2.8rem;
            @include media(phone) {
                margin-top: 1.2rem;
            }
        }
    }
}

.replays_wrapp {
    .flex-wrapp {
        .tile-cake {
            @media all and (min-width: 768px) and (max-width: 991px) {
                width: 33%;
            }
        }
    }
}
</style>
