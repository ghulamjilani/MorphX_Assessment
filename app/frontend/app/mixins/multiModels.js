import store from "@store/store"
import Session from "@models/Session";
import Video from "@models/Video";
import Channel from "@models/Channel";
import Recording from "@models/Recording";
import Search from "@models/Search";

export default {
    data() {
        return {
            orderBy: 'new'
        }
    },

    computed: {
        orderByTransformed() {
            let ord;

            if (this.orderBy == 'new') {
                ord = this.isSession ? 'start_at' : 'created_at'
            } else if (this.orderBy == 'views_count') {
                ord = 'views_count'
            }

            return ord
        },
        isSession() {
            return this.forModel == "session";
        },
        isVideo() {
            return this.forModel == "video";
        },
        isRecording() {
            return this.forModel == "recording";
        },
        isSearch() {
            return this.forModel == "search";
        },
        collection() {
            if (this.isVideo) {
                return Video.query()
                    .where("sortUid", store.getters.sortVideoUid)
                    .orderBy(this.orderByTransformed, 'desc')
                    .get();
            } else if (this.isSession) {
                return Session.query()
                    .where("sortUid", store.getters.sortSessionUid)
                    .orderBy('start_at') // // .orderBy(this.orderByTransformed) // if need switch
                    .get();
            } else if (this.isRecording) {
                return Recording.query()
                    .where("sortUid", store.getters.sortRecordingUid)
                    .orderBy(this.orderByTransformed, 'desc')
                    .get()
            } else if (this.isSearch) {
                return store.getters.getSearchList
            }
        },
        model() {
            if (this.isVideo) {
                return Video
            } else if (this.isSession) {
                return Session
            } else if (this.isRecording) {
                return Recording
            } else if (this.isSearch) {
                return Search
            }
        },
        prefix() {
            if (this.isVideo) {
                return 'v'
            } else if (this.isSession) {
                return 's'
            } else if (this.isRecording) {
                return 'r'
            } else if (this.isSearch) {
                return 'f'
            }
        },
        defaultParams() {
            if (this.isVideo) {
                return {
                    channel_id: this.channel_id,
                    limit: 12
                }
            } else if (this.isSession) {
                return {
                    end_after: moment().toISOString(),
                    channel_id: this.channel_id,
                    limit: 12
                }
            } else if (this.isRecording) {
                return {
                    channel_id: this.channel_id,
                    limit: 12
                }
            }
        }
    }
}