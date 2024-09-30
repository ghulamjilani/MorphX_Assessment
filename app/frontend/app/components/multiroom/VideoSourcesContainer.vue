<template>
    <div class="v-vidio-sources-container">
        <div class="add-vidio-source-section">
            <h2 class="title">
                Video Sources
            </h2>
            <div class="add-btn-wrap">
                <div>
                    Add new video source or edit your current sources:
                </div>
                <div
                    class="add-studio-btn btn btn-m btn-red"
                    @click="openCreateModal()">
                    + Add new Source
                </div>
            </div>
        </div>

        <div
            v-show="videoSources && videoSources.length > 0"
            class="v-video-sources-list">
            <div class="v-thead hideOnMobile">
                <div class="v-trow">
                    <div class="v-tcell">
                        Video Source Name
                    </div>
                    <div class="v-tcell">
                        Type
                    </div>
                    <div class="v-tcell" />
                    <div class="v-tcell" />
                </div>
            </div>
            <div class="v-tbody">
                <div
                    v-for="videoSource in videoSources"
                    :key="videoSource.id"
                    class="v-trow">
                    <!--   mobile only  -->
                    <div class="mobile-header">
                        <div class="v-tcell">
                            Video Source Name
                        </div>
                        <div class="v-tcell">
                            Type
                        </div>
                        <div class="v-tcell">
                            Options
                        </div>
                    </div>
                    <div class="content mobileContent">
                        <div
                            class="v-tcell name show"
                            @click="openShowModal(videoSource)">
                            {{ videoSource.custom_name }}
                        </div>
                        <div class="v-tcell">
                            {{ deviceType(videoSource.current_service) }}
                        </div>
                        <div class="v-tcell">
                            <span
                                class="edit-vs"
                                @click="openEditModal(videoSource)"><i class="VideoClientIcon-edit-icon" /> Edit</span>
                        </div>
                        <div class="v-tcell">
                            <div
                                class="remove"
                                @click="openRemoveModal(videoSource)">
                                <i class="VideoClientIcon-trash-emptyF" /><span>Remove</span>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <validation-observer
            ref="formNew"
            v-slot="{ handleSubmit }">
            <modal ref="videoSourceModal">
                <template #header>
                    <h2 class="title">
                        New Video Source
                    </h2>
                </template>

                <template #body>
                    <div class="source-types">
                        <div
                            :class="{selected: isSelected('IP Cam')}"
                            class="source-type"
                            @click="chengeSourceType('IP Cam')">
                            <img :src="require('../../assets/images/ipCam.png')">
                            <label>IP Camera</label>
                        </div>
                        <div
                            :class="{selected: isSelected('Encoder')}"
                            class="source-type"
                            @click="chengeSourceType('Encoder')">
                            <img :src="require('../../assets/images/rtmp.png')">
                            <label>Encoder</label>
                        </div>
                    </div>

                    <div
                        v-show="currentSourceType"
                        class="bodyWrapper">
                        <validation-provider
                            v-slot="{ errors }"
                            rules="required">
                            <div class="inputsAndSelect">
                                <label for="name">Name*</label>
                                <input
                                    id="name"
                                    v-model="newVideoSourceData.custom_name"
                                    maxlength="256"
                                    type="text">
                                <span class="error">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>

                        <validation-provider
                            v-if="isSelected('IP Cam')"
                            v-slot="{ errors }"
                            rules="required">
                            <div class="inputsAndSelect">
                                <label for="source_url">Source URL*</label>
                                <input
                                    id="source_url"
                                    v-model="newVideoSourceData.source_url"
                                    type="text">
                                <span class="error">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>
                    </div>
                </template>

                <template #footer>
                    <div class="modal-buttons">
                        <button
                            class="btn btn-l btn-borderred-light"
                            @click="$refs.videoSourceModal.closeModal">
                            Cancel
                        </button>
                        <button
                            class="btn btn-l btn-red"
                            @click="handleSubmit(submit)">
                            Save
                        </button>
                    </div>
                </template>
            </modal>
        </validation-observer>

        <validation-observer
            ref="formEdit"
            v-slot="{ invalid }">
            <modal
                ref="videoSourceEditModal"
                @modalClosed="clearPreview">
                <template #header>
                    <h2 class="title margin-bottom-0">
                        Edit Video Source
                    </h2>
                </template>

                <template #body>
                    <div :class="{'source-types-top': editVideoSourceData.current_service == 'rtmp'}">
                        <div class="source-types">
                            <div
                                v-if="editVideoSourceData.current_service == 'ipcam'"
                                class="source-type selected">
                                <img :src="require('../../assets/images/ipCam.png')">
                                <label>IP Camera</label>
                            </div>
                            <div
                                v-if="editVideoSourceData.current_service == 'rtmp'"
                                class="source-type selected">
                                <img :src="require('../../assets/images/rtmp.png')">
                                <label>Encoder</label>
                            </div>
                        </div>

                        <div
                            :class="{'encoder-edit': editVideoSourceData.current_service == 'rtmp'}"
                            class="bodyWrapper edit">
                            <validation-provider
                                v-slot="{ errors }"
                                rules="required">
                                <div class="inputsAndSelect">
                                    <label for="name">Name*</label>
                                    <input
                                        id="name"
                                        v-model="editVideoSourceData.custom_name"
                                        type="text">
                                    <span class="error">{{ errors[0] }}</span>
                                </div>
                            </validation-provider>
                            <validation-provider
                                v-if="editVideoSourceData.current_service == 'ipcam'"
                                v-slot="{ errors }"
                                rules="required">
                                <div class="inputsAndSelect">
                                    <label for="source_url">Source URL*</label>
                                    <input
                                        id="source_url"
                                        v-model="editVideoSourceData.source_url"
                                        type="text">
                                    <span class="error">{{ errors[0] }}</span>
                                </div>
                            </validation-provider>
                        </div>
                    </div>

                    <div
                        v-if="editVideoSourceData.current_service == 'rtmp'"
                        class="data-wrapper">
                        <div class="vs-data">
                            <div class="vs-data-item-wrap">
                                <div class="vs-data-item-label bold">
                                    URL
                                </div>
                                <div class="vs-data-item-data">
                                    {{ editVideoSourceData.server }}
                                    <i
                                        v-clipboard="editVideoSourceData.server"
                                        class="VideoClientIcon-squaresF" />
                                </div>
                            </div>
                        </div>
                        <div class="items-wrapper">
                            <div class="vs-data">
                                <div class="vs-data-item-wrap">
                                    <div class="vs-data-item-label bold">
                                        Port
                                    </div>
                                    <div class="vs-data-item-data">
                                        {{ editVideoSourceData.port }}
                                        <i
                                            v-clipboard="editVideoSourceData.port"
                                            class="VideoClientIcon-squaresF" />
                                    </div>
                                </div>
                            </div>
                            <div class="vs-data">
                                <div class="vs-data-item-wrap">
                                    <div class="vs-data-item-label bold">
                                        Stream Key
                                    </div>
                                    <div class="vs-data-item-data">
                                        {{ editVideoSourceData.stream_name }}
                                        <i
                                            v-clipboard="editVideoSourceData.stream_name"
                                            class="VideoClientIcon-squaresF" />
                                    </div>
                                </div>
                            </div>
                        </div>
                        <div class="items-wrapper">
                            <div class="vs-data">
                                <div class="vs-data-item-wrap">
                                    <div class="vs-data-item-label bold">
                                        Username
                                    </div>
                                    <div class="vs-data-item-data">
                                        {{ editVideoSourceData.username }}
                                        <i
                                            v-clipboard="editVideoSourceData.username"
                                            class="VideoClientIcon-squaresF" />
                                    </div>
                                </div>
                            </div>
                            <div class="vs-data">
                                <div class="vs-data-item-wrap">
                                    <div class="vs-data-item-label bold">
                                        Password
                                    </div>
                                    <div class="vs-data-item-data">
                                        {{ editVideoSourceData.password }}
                                        <i
                                            v-clipboard="editVideoSourceData.password"
                                            class="VideoClientIcon-squaresF" />
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <div class="test-connection">
                        <div
                            v-show="['off', 'down', 'nil', null, undefined, 'starting', 'up'].includes(testConnectionStatus)"
                            class="test-connection-window">
                            <div>
                                <span v-show="['off', 'nil', null, undefined].includes(testConnectionStatus)">
                                    PREVIEW
                                </span>
                                <div
                                    v-show="testConnectionStatus == 'starting'"
                                    class="test-connection-window-message">
                                    Please wait. It may take up to 30 seconds to start the stream.
                                </div>
                                <div
                                    v-show="testConnectionStatus == 'down'"
                                    class="test-connection-window-message">
                                    Make sure your {{ deviceType(editVideoSourceData.current_service) }} is live to see
                                    the preview.
                                </div>
                            </div>
                            <div
                                :class="{'btn-red': ['off', 'down', 'nil', null, undefined, 'up'].includes(testConnectionStatus), 'test-connection-btn__posTop': testConnectionStatus == 'up', 'btn-grey-solid': ['starting', 'down',].includes(testConnectionStatus), disabled: ['starting', 'down',].includes(testConnectionStatus)}"
                                class="test-connection-btn btn btn-s btn-red margin-top-10"
                                @click="switchStream()">
                                <span v-show="['off', 'nil', null, undefined].includes(testConnectionStatus)">
                                    Test Stream(5 minutes length)
                                    <i class="VideoClientIcon-play3" />
                                </span>
                                <span v-show="['starting', 'down'].includes(testConnectionStatus)">
                                    Processing...
                                </span>
                                <span v-show="testConnectionStatus == 'up'">
                                    Stop Preview
                                    <i class="VideoClientIcon-stop2" />
                                </span>
                            </div>
                        </div>
                        <div
                            v-show="testConnectionStatus == 'up'"
                            class="test-connection-window preview-video-source">
                            <div class="spinnerSlider">
                                <div class="bounceS1" />
                                <div class="bounceS2" />
                                <div class="bounceS3" />
                            </div>
                            <div
                                ref="theoplayer"
                                class="test-preview-theoplayer" />
                        </div>
                    </div>
                </template>

                <template #footer>
                    <div class="modal-buttons">
                        <button
                            class="btn btn-l btn-borderred-light"
                            @click="closeEditModal()">
                            Cancel
                        </button>
                        <button
                            :disabled="invalid"
                            class="btn btn-l btn-red"
                            @click="updateVideoSource">
                            Update
                        </button>
                    </div>
                </template>
            </modal>
        </validation-observer>

        <modal ref="removeModal">
            <template #header>
                <h2 class="title">
                    Remove Video Source
                </h2>
            </template>

            <template #body>
                <div class="bodyWrapper remove">
                    <span>Are you sure you want to remove</span>
                    <b>{{ removeVideoSourceData.custom_name }}</b>
                    <span>video source?</span>
                </div>
            </template>

            <template #footer>
                <div class="modal-buttons">
                    <button
                        class="btn btn-l btn-borderred-light"
                        @click="$refs.removeModal.closeModal">
                        Cancel
                    </button>
                    <button
                        class="btn btn-l btn-red"
                        @click="removeVideoSource">
                        Remove
                    </button>
                </div>
            </template>
        </modal>

        <modal ref="showModal">
            <template #header>
                <h2 class="title">
                    Video Source
                </h2>
            </template>

            <template #body>
                <div class="source-types">
                    <div
                        v-if="showVideoSourceData.current_service == 'ipcam'"
                        class="source-type selected">
                        <img :src="require('../../assets/images/ipCam.png')">
                        <label>IP Camera</label>
                    </div>
                    <div
                        v-if="showVideoSourceData.current_service == 'rtmp'"
                        class="source-type selected">
                        <img :src="require('../../assets/images/rtmp.png')">
                        <label>Encoder</label>
                    </div>
                </div>

                <div class="data-wrapper">
                    <div class="vs-data">
                        <div class="vs-data-item-wrap">
                            <div class="vs-data-item-label bold">
                                Name
                            </div>
                            <div class="vs-data-item-data">
                                {{ showVideoSourceData.custom_name }}
                                <i
                                    v-clipboard="showVideoSourceData.custom_name"
                                    class="VideoClientIcon-squaresF" />
                            </div>
                        </div>
                    </div>
                    <div
                        v-if="showVideoSourceData.current_service == 'ipcam'"
                        class="vs-data">
                        <div class="vs-data-item-wrap">
                            <div class="vs-data-item-label bold">
                                URL
                            </div>
                            <div class="vs-data-item-data">
                                {{ showVideoSourceData.source_url }}
                                <i
                                    v-clipboard="showVideoSourceData.source_url"
                                    class="VideoClientIcon-squaresF" />
                            </div>
                        </div>
                    </div>
                    <div
                        v-if="showVideoSourceData.current_service == 'rtmp'"
                        class="vs-data">
                        <div class="vs-data-item-wrap">
                            <div class="vs-data-item-label bold">
                                URL
                            </div>
                            <div
                                v-if="editVideoSourceData.sever"
                                class="vs-data-item-data">
                                {{ showVideoSourceData.server }}
                                <i
                                    v-clipboard="showVideoSourceData.server"
                                    class="VideoClientIcon-squaresF" />
                            </div>
                        </div>
                    </div>
                    <div class="items-wrapper">
                        <div
                            v-if="showVideoSourceData.current_service == 'rtmp'"
                            class="vs-data">
                            <div class="vs-data-item-wrap">
                                <div class="vs-data-item-label bold">
                                    Port
                                </div>
                                <div class="vs-data-item-data">
                                    {{ showVideoSourceData.port }}
                                    <i
                                        v-clipboard="showVideoSourceData.port"
                                        class="VideoClientIcon-squaresF" />
                                </div>
                            </div>
                        </div>
                        <div
                            v-if="showVideoSourceData.current_service == 'rtmp'"
                            class="vs-data">
                            <div class="vs-data-item-wrap">
                                <div class="vs-data-item-label bold">
                                    Stream Key
                                </div>
                                <div class="vs-data-item-data">
                                    {{ showVideoSourceData.stream_name }}
                                    <i
                                        v-clipboard="showVideoSourceData.stream_name"
                                        class="VideoClientIcon-squaresF" />
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="items-wrapper">
                        <div
                            v-if="showVideoSourceData.current_service == 'rtmp'"
                            class="vs-data">
                            <div class="vs-data-item-wrap">
                                <div class="vs-data-item-label bold">
                                    Username
                                </div>
                                <div class="vs-data-item-data">
                                    {{ showVideoSourceData.username }}
                                    <i
                                        v-clipboard="showVideoSourceData.username"
                                        class="VideoClientIcon-squaresF" />
                                </div>
                            </div>
                        </div>
                        <div
                            v-if="showVideoSourceData.current_service == 'rtmp'"
                            class="vs-data">
                            <div class="vs-data-item-wrap">
                                <div class="vs-data-item-label bold">
                                    Password
                                </div>
                                <div class="vs-data-item-data">
                                    {{ showVideoSourceData.password }}
                                    <i
                                        v-clipboard="showVideoSourceData.password"
                                        class="VideoClientIcon-squaresF" />
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </template>

            <template #footer>
                <div class="modal-buttons">
                    <button
                        class="btn btn-l btn-red"
                        @click="$refs.showModal.closeModal">
                        Close
                    </button>
                </div>
            </template>
        </modal>
    </div>
</template>

<script>
import Modal from "@components/common/Modal"
import VideoSource from '@models/VideoSource'

export default {
    components: {Modal},
    data() {
        return {
            showVideoSourceData: null,
            newVideoSourceData: {
                id: null,
                custom_name: '',
                source_url: ''
            },
            editVideoSourceData: {
                id: null,
                custom_name: '',
                current_service: '',
                stream_previews_id: '',
                source_url: ''
            },
            removeVideoSourceData: {
                id: null,
                custom_name: ''
            },
            currentSourceType: '', // IP Cam, Encoder
            testConnectionStatus: 'off', // off/nil, down, starting, up
            player: null,
            isVideoSourceEditModalOpen: false
        }
    },
    computed: {
        delivery_method() {
            // pull or push
            if (this.currentSourceType == 'IP Cam') {
                return 'pull'
            } else {
                return 'push'
            }
        },
        current_service() {
            switch (this.currentSourceType) {
                case 'IP Cam':
                    return 'ipcam'
                case 'Encoder':
                    return 'rtmp'
            }
        },
        videoSources() {
            return VideoSource.query().orderBy('updated_at').get()
        }
    },
    watch: {
        isVideoSourceEditModalOpen(val) {
            if (val) {
                window.addEventListener('beforeunload', this.isVideoSourceEditModalOpenHandler)
            } else {
                window.removeEventListener('beforeunload', this.isVideoSourceEditModalOpenHandler)
            }
        }
    },
    created() {
        VideoSource.api().fetchFfmpegserviceAccounts({current_service: "rtmp,ipcam"})
    },
    mounted() {
        $(this.$el).on('click', '.VideoClientIcon-squaresF', function () {
            $.showFlashMessage('Copied', {type: "success", timeout: 2000})
        })
    },
    methods: {
        deviceType(current_service) {
            switch (current_service) {
                case 'ipcam':
                    return 'IP Cam'
                case 'rtmp':
                    return 'Encoder'
            }
        },
        chengeSourceType(type) {
            this.currentSourceType = type
            this.newVideoSourceData.id = null
            VideoSource.api().reserveFfmpegserviceAccount({
                delivery_method: this.delivery_method
            }).then((res) => {
                this.newVideoSourceData.id = res?.response?.data?.response?.ffmpegservice_account?.id
            })
        },
        isSelected(type) {
            return this.currentSourceType == type
        },
        clearForm() {
            this.currentSourceType = '',
                this.newVideoSourceData = {
                    id: null,
                    custom_name: '',
                    source_url: '',
                    stream_name: '',
                    username: '',
                    password: ''
                }
        },
        openCreateModal() {
            this.$refs.videoSourceModal.openModal()
        },
        openShowModal(videoSource) {
            this.showVideoSourceData = videoSource
            this.$refs.showModal.openModal()
        },
        openEditModal(videoSource) {
            this.editVideoSourceData = JSON.parse(JSON.stringify(videoSource))
            this.$refs.videoSourceEditModal.openModal()
            this.isVideoSourceEditModalOpen = true

            setTimeout(() => {
                // init player
                this.player = new window.THEOplayer.ChromelessPlayer(this.$refs.theoplayer, {
                    license: window.ConfigFrontend.services.theo_player.license,
                    libraryLocation: location.origin + "/javascripts/theo/",
                    ui: {
                        width: '100%',
                        height: '100%',
                        fullscreen: {
                          fullscreenOptions: {
                            navigationUI: "auto"
                          }
                        }

                    }
                })
                this.player.autoplay = true

                // setup player.source
                if (['up'].includes(this.editVideoSourceData.stream_status)) {
                    this.testConnectionStatus = this.editVideoSourceData.stream_status
                    this.player.source = this.playerSource()
                }

                this.streamPreviewsChannel = initStreamPreviewsChannel(this.editVideoSourceData.id)
                this.streamPreviewsChannel.bind(streamPreviewsChannelEvents.streamStatus, (data) => {
                    this.testConnectionStatus = data.stream_status
                    if (data.stream_status == 'up') {
                        this.player.source = this.playerSource()
                    }
                    VideoSource.update({
                        where: this.editVideoSourceData.id,
                        data: {stream_status: data.stream_status}
                    })
                })
            }, 1000)
        },
        playerSource() {
            let source = {}

            if (this.editVideoSourceData.hls_url.split('.').pop() === 'm3u8') {
                source.sources = [
                    {
                        src: this.editVideoSourceData.hls_url,
                        type: 'application/x-mpegurl'
                    }
                ]
            } else {
                source.sources = [
                    {
                        src: this.editVideoSourceData.hls_url
                    }
                ]
            }

            return source
        },
        updateVideoSource() {
            VideoSource.api().updateFfmpegserviceAccount(this.editVideoSourceData).then((res) => {
                this.$refs.videoSourceEditModal.closeModal()
                this.isVideoSourceEditModalOpen = false
            })
        },
        closeEditModal() {
            this.closeStreamPreviewSubscription()
            this.$refs.videoSourceEditModal.closeModal()
            this.isVideoSourceEditModalOpen = false
        },
        closeStreamPreviewSubscription() {
            if (this.streamPreviewsChannel) {
                this.streamPreviewsChannel.subscription.unsubscribe();
                delete this.streamPreviewsChannel.subscription;
                delete websocketConnection.subscriptions[this.StreamPreviewsChannel.configHash];
                this.streamPreviewsChannel = null
            }
        },
        openRemoveModal(videoSource) {
            this.removeVideoSourceData['id'] = videoSource.id
            this.removeVideoSourceData['custom_name'] = videoSource.custom_name
            this.$refs.removeModal.openModal()
        },
        removeVideoSource() {
            VideoSource.api().unassignFfmpegserviceAccount(this.removeVideoSourceData).then(() => {
                VideoSource.delete(this.removeVideoSourceData.id)
                this.$refs.removeModal.closeModal()
            })
        },
        submit() {
            let submitParams = {
                id: this.newVideoSourceData.id,
                current_service: this.current_service
            }

            if (this.isSelected('Encoder')) {
                submitParams['custom_name'] = this.newVideoSourceData.custom_name
            } else if (this.isSelected('IP Cam')) {
                submitParams['custom_name'] = this.newVideoSourceData.custom_name
                submitParams['source_url'] = this.newVideoSourceData.source_url
            } else {
                submitParams = {...submitParams, ...this.newVideoSourceData}
            }

            VideoSource.api().assignFfmpegserviceAccount(submitParams)
                .then((res) => {
                    this.$refs.videoSourceModal.closeModal()
                    this.openEditModal(VideoSource.find(submitParams.id))
                    this.clearForm()
                })
        },
        switchStream() {
            if (['starting', 'down'].includes(this.testConnectionStatus)) {
                return
            } else if (['off', 'nil', null, undefined].includes(this.testConnectionStatus)) {
                /* START */
                VideoSource.api().startStreaming({id: this.editVideoSourceData.id}).then((data) => {
                    this.editVideoSourceData.stream_previews_id = data.response.data.response.stream_preview.id
                    this.testConnectionStatus = 'starting'
                    // todo: check hls_url
                    // this.player.source = { sources: data.response.data.response.ffmpegservice_account.hls_url }
                }).catch(error => {
                    // TODO: andrey replace $.showFlashMessage -> to this.$flash after move this component to SPA
                    if (error?.response?.data?.message) {
                        $.showFlashMessage(error?.response?.data?.message, {
                            type: 'error'
                        })
                    } else {
                        $.showFlashMessage('Something went wrong please try again later', {
                            type: 'error'
                        })
                    }
                })
            } else if (this.testConnectionStatus == 'up') {
                /* STOP */
                this.stopStreaming()
            }
        },
        clearPreview() {
            this.testConnectionStatus = 'off'
            this.player = null
            this.isVideoSourceEditModalOpen = false

            // Todo: andrey ActionCable unsubscribe
            this.closeStreamPreviewSubscription()
            this.stopStreaming()
        },
        stopStreaming() {
            if (this.editVideoSourceData.stream_previews_id) {
                VideoSource.api().stopStreaming({stream_previews_id: this.editVideoSourceData.stream_previews_id}).then(() => {
                    VideoSource.update({
                        where: this.editVideoSourceData.id,
                        data: {stream_status: 'off'}
                    })
                })
            }
        },
        isVideoSourceEditModalOpenHandler() {
            event.preventDefault()
            event.returnValue = ''
            this.stopStreaming()
        }
    }
}
</script>

<style lang="scss" scoped>
.preview-video-source {
    .spinnerSlider {
        > div {
            background-color: #E2E7EA;
        }
    }

    .test-preview-theoplayer {
        height: 100%;
        width: 100%;
        background-color: #12191d;

        > video {
            width: 100%;
            height: 100%;
        }
    }
}
</style>

<style lang="scss" scoped>
.v-vidio-sources-container {
    padding: 15px 20px 20px;
    border-radius: 10px;
    background-color: var(--bg__content);
    box-shadow: 0 4px 7px 0 var(--sh__main);

    .add-vidio-source-section {
        .title {
            color: var(--tp__h1);
            font-weight: bold;
        }

        .add-btn-wrap {
            display: flex;
            justify-content: space-between;
            align-items: center;
            @media (max-width: 600px) {
                flex-direction: column;
                align-items: inherit;
                line-height: 3;
            }
        }
    }

    .v-video-sources-list {
        margin-top: 15px;
        margin-bottom: 25px;

        .v-tbody {
            .content {
                display: flex;
                width: 100%;

                .show, .remove, .edit-vs {
                    cursor: pointer;
                }

                .remove {
                    > i {
                        margin-right: 5px;
                    }

                    > span {
                        @media all and (min-width: 601px) and (max-width: 640px) {
                            display: none;
                        }
                    }
                }

                .show {
                    &:hover {
                        color: var(--tp__h1);
                    }
                }
            }
        }

        .v-thead {
            font-weight: 600;
        }

        .v-trow {
            display: flex;
            padding: 10px 0;
            justify-content: space-between;
            border-bottom: 1px solid var(--border__separator);

            .v-tcell {
                flex-grow: 1;
                flex-basis: 0;

                &:first-child {
                    flex-grow: 4;
                }

                &:nth-child(2) {
                    flex-grow: 3;
                }

                &:nth-child(3), &:nth-child(4) {
                    flex-basis: 20px;
                }
            }

            .name {
                @media all and (min-width: 601px) {
                    width: 100%;
                    white-space: nowrap;
                    overflow-x: hidden;
                    text-overflow: ellipsis;
                }
            }
        }
    }

    .v-modal {
        .title {
            color: var(--tp__h1);
            font-weight: bold;
        }

        .source-types-top {
            display: flex;
            align-items: flex-end;
        }

        .source-types {
            display: flex;
            padding-bottom: 20px;

            .source-type {
                text-align: center;
                font-weight: bold;
                color: var(--tp__h1);
                cursor: pointer;
                margin-right: 15px;
                height: 110px;
                padding: 15px 15px 10px;
                border-radius: 10px;
                box-sizing: border-box;
                border: 1px solid rgba(9, 95, 115, 0.2);
                display: flex;
                flex-direction: column;
                justify-content: space-between;

                > img {
                    opacity: 0.3;
                }

                &.selected {
                    border: 1px solid var(--tp__h1);

                    > img {
                        opacity: 1;
                    }
                }

                img {
                    width: 70px;
                    height: 40px;
                }

                label {
                    margin-bottom: 0;
                    white-space: nowrap;
                    font-size: 13px;
                }
            }
        }

        .bodyWrapper {
            .inputsAndSelect {
                display: flex;
                flex-direction: column;
                padding-bottom: 30px;

                label {
                    margin-bottom: 0;
                    line-height: 14px;
                    font-size: 14px;
                }

                input {
                    font-size: 16px;
                    padding: 0;
                }

                .error {
                    font-size: 14px;
                    color: #f23535;
                }
            }

            span:last-of-type > .inputsAndSelect {
                padding-bottom: 0;
            }

            .userNameAndPassword {
                display: flex;
                @media (max-width: 640px) {
                    flex-direction: column;
                }

                :first-child {
                    margin-right: 30px;
                }

                .inputsAndSelect {
                    width: 100%;
                }
            }
        }

        .encoder-edit {
            &.edit {
                padding: 0;
                width: 100%;
                background: none;
                border: none;
                border-radius: 0;
            }
        }

        .data-wrapper {
            padding: 20px;
            margin-bottom: 20px;
            background: rgba(9, 95, 115, 0.05);
            border-radius: 10px;
            border: 1px solid rgba(9, 95, 115, 0.2);

            .items-wrapper {
                display: flex;
                flex-direction: column;
                align-items: baseline;

                .vs-data {
                    margin-bottom: 15px;
                    width: 100%;
                    margin-right: 0;
                }

                @media all and (min-width: 641px) {
                    flex-direction: row;
                    &:first-child {
                        margin-bottom: 0;
                    }
                    .vs-data {
                        width: 50%;

                        &:first-child {
                            margin-right: 30px;
                        }
                    }
                }
            }

            .vs-data {
                margin-bottom: 15px;
                word-break: break-all;
                border-bottom: 1px solid var(--border__separator);

                .vs-data-item-data {
                    position: relative;
                }

                .VideoClientIcon-squaresF {
                    font-size: 20px;
                    cursor: pointer;
                    display: inline-block;
                    transform: rotateZ(90deg);
                    position: absolute;
                    right: 0;

                    &:hover {
                        color: var(--tp__h1);
                    }
                }
            }
        }

        .test-connection {
            position: relative;
            padding-top: 56.6%;
            height: 0;
            width: 100%;

            &-window {
                overflow: hidden;
                color: white;
                position: absolute;
                left: 0;
                top: 0;
                width: 100%;
                height: 100%;
                font-weight: 600;
                background: var(--bg__label);
                border-radius: 5px;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-direction: column;

                i {
                    vertical-align: text-bottom;
                }

                @media (max-width: 640px) {
                    width: 100%;
                }

                .test-connection-window-message {
                    margin: auto;
                    padding: 10px;
                    width: 270px;
                    text-align: center;
                    border-radius: 5px;
                    background: rgba(0, 0, 0, 0.2);
                }
            }
        }
    }
}

@media (max-width: 600px) {
    .v-tcell {
        margin-top: 10px;
    }

    .hideOnMobile {
        display: none;
    }
    .mobile-header {
        margin-right: 20px;

        .v-tcell {
            white-space: nowrap;
        }
    }
    .mobileContent {
        flex-direction: column;
        align-items: center;
        overflow: hidden;
        white-space: nowrap;
        text-overflow: ellipsis;

        .v-tcell {
            white-space: nowrap;
        }
    }
}

@media (max-width: 640px) {
    .v-tcell {
        i {
            display: inline-block;
            margin-right: 5px;
        }
    }
}

@media (min-width: 601px) {
    .mobile-header, .mobileContent {
        display: none;
    }
}

.test-connection {
    &-btn {
        z-index: 19;

        &__posTop {
            position: absolute;
            left: 10px;
            top: 10px;
        }
    }
}

</style>