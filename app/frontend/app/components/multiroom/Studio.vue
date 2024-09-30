<template>
    <div
        :class="{open: isOpen}"
        class="v-studio">
        <div class="v-studio-header">
            <div class="headerWrapp">
                <div class="name">
                    {{ studio.name }}
                </div>
                <div
                    v-if="studio.address"
                    class="address">
                    <i class="VideoClientIcon-map-pin-icon" />
                    {{ studio.address }}
                </div>
                <div
                    v-if="studio.phone"
                    class="phone">
                    <i class="VideoClientIcon-phone" />
                    {{ studio.phone }}
                </div>
            </div>
            <div class="line" />
            <div class="controls">
                <div class="editAndDel">
                    <i
                        class="VideoClientIcon-edit-icon"
                        @click="openStudioEditModal(studio)" />
                    <i
                        class="VideoClientIcon-trash-2"
                        @click="openRemoveStudioModal(studio)" />
                </div>
                <span
                    class="toggleBtn"
                    @click="toggle()"> {{ toggleText }} <i class="VideoClientIcon-angle-downF" /> </span>
            </div>
        </div>
        <div
            v-show="isOpen"
            class="v-studio-body">
            <validation-observer
                ref="newRoom"
                v-slot="{ handleSubmit }">
                <div class="v-rooms-form">
                    <div class="fields">
                        <validation-provider
                            v-slot="{ errors }"
                            rules="required"
                            vid="name">
                            <div class="inputsWrapper">
                                <label for="name">Name*</label>
                                <input
                                    id="name"
                                    v-model="newRoom.name"
                                    placeholder="Add room name..."
                                    type="text">
                                <span class="error">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>

                        <validation-provider
                            v-slot="{ errors }"
                            rules="required"
                            vid="video_source_id">
                            <div class="inputsWrapper">
                                <label for="video-source">Video Source*</label>
                                <dropdown
                                    v-model="newRoom.video_source_id"
                                    :options="dropdownVideoSources"
                                    placeholder="Select" />
                                <span
                                    class="error"
                                    style="margin-top: -10px">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>
                    </div>
                    <button
                        class="btn btn-m btn-borderred-grey"
                        @click="handleSubmit(addRoom)">
                        + Add new Room
                    </button>
                </div>
            </validation-observer>

            <div
                v-show="studio.rooms && studio.rooms.length > 0"
                class="v-rooms-list">
                <div class="v-thead hideOnMobile">
                    <div class="v-trow">
                        <div class="v-tcell">
                            Room Name
                        </div>
                        <div class="v-tcell">
                            Video Source
                        </div>
                        <div class="v-tcell" />
                        <div class="v-tcell" />
                    </div>
                </div>
                <div class="v-tbody">
                    <div
                        v-for="room in studio.rooms"
                        :key="room.id"
                        class="v-trow-body">
                        <!--   mobile only  -->
                        <div class="mobile-header">
                            <div class="v-tcell">
                                Room Name
                            </div>
                            <div class="v-tcell">
                                Video Source
                            </div>
                            <div class="v-tcell">
                                Add Session
                            </div>
                            <div class="v-tcell">
                                Options
                            </div>
                        </div>
                        <validation-observer
                            ref="editRoom"
                            v-slot="{ handleSubmit }">
                            <div class="content mobileContent">
                                <div class="v-tcell">
                                    <template v-if="editRoomData.id == room.id">
                                        <validation-provider
                                            v-slot="{ errors }"
                                            rules="required"
                                            vid="name">
                                            <div class="inputsWrapper">
                                                <input
                                                    id="name"
                                                    v-model="editRoomData.name"
                                                    placeholder="Add room name..."
                                                    type="text">
                                                <span class="error">{{ errors[0] }}</span>
                                            </div>
                                        </validation-provider>
                                    </template>
                                    <template v-else>
                                        {{ room.name }}
                                    </template>
                                </div>
                                <div class="v-tcell">
                                    <template v-if="editRoomData.id == room.id">
                                        <validation-provider
                                            v-slot="{ errors }"
                                            rules="required"
                                            vid="video_source_id">
                                            <div class="inputsWrapper">
                                                <!-- TODO: options should be (already selected for this source) + dropdownVideoSources  -->
                                                <dropdown
                                                    v-model="editRoomData.video_sources_id"
                                                    :options="dropdownVideoSources"
                                                    :type="'multi'"
                                                    :with-search="true"
                                                    placeholder="Select" />
                                                <span
                                                    class="error"
                                                    style="margin-top: -10px">{{ errors[0] }}</span>
                                            </div>
                                        </validation-provider>
                                    </template>
                                    <template v-if="room.video_source">
                                        {{ room.video_source.custom_name }}
                                    </template>
                                </div>
                                <div class="v-tcell text-center">
                                    <a
                                        class="btn btn-s btn-red disabled"
                                        title="Coming soon">+ New session</a>
                                </div>
                                <div class="v-tcell text-right">
                                    <div class="remove">
                                        <!-- TODO: andrey enabre this btn -->
                                        <!-- <span v-if="editRoomData.id == room.id || editRoomData.id == null" @click="handleSubmit(startEditRoom(room))" class="remove"> -->
                                        <span
                                            v-if="false"
                                            class="remove"
                                            @click="handleSubmit(startEditRoom(room))">
                                            <i
                                                class="VideoClientIcon-edit-icon"
                                                title="Edit" />
                                            <span v-if="editRoomData.id == room.id">Save</span>
                                        </span>
                                        <span @click="openRemoveStudioRoomModal(room)">
                                            <i
                                                class="VideoClientIcon-trash-emptyF"
                                                title="Remove" /> <span>Remove</span>
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </validation-observer>
                    </div>
                </div>
            </div>
        </div>

        <modal ref="removeStudioModal">
            <template #header>
                <h2 class="title">
                    Remove Studio
                </h2>
            </template>

            <template #body>
                <div class="bodyWrapper remove">
                    <span>Are you sure you want to remove</span>
                    <b>{{ removeStudioData.name }}</b>
                    <span>studio?</span>
                </div>
            </template>

            <template #footer>
                <div class="modal-buttons">
                    <button
                        class="btn btn-l btn-borderred-light"
                        @click="$refs.removeStudioModal.closeModal">
                        Cancel
                    </button>
                    <button
                        class="btn btn-l btn-red"
                        @click="removeStudio">
                        Remove
                    </button>
                </div>
            </template>
        </modal>

        <modal ref="removeStudioRoomModal">
            <template #header>
                <h2 class="title">
                    Remove Room
                </h2>
            </template>

            <template #body>
                <div class="bodyWrapper remove">
                    <span>Are you sure you want to remove</span>
                    <b>{{ removeRoomData.name }}</b>
                    <span>Room?</span>
                </div>
            </template>

            <template #footer>
                <div class="modal-buttons">
                    <button
                        class="btn btn-l btn-borderred-light"
                        @click="$refs.removeStudioRoomModal.closeModal">
                        Cancel
                    </button>
                    <button
                        class="btn btn-l btn-red"
                        @click="removeStudioRoom">
                        Remove
                    </button>
                </div>
            </template>
        </modal>

        <validation-observer
            ref="formEdit"
            v-slot="{ invalid }">
            <modal ref="studioEditModal">
                <template #header>
                    <h2 class="technicalPage__label">
                        Edit Studio
                    </h2>
                </template>

                <template #body>
                    <div class="nameAndPhone">
                        <validation-provider
                            v-slot="{ errors }"
                            rules="required"
                            vid="name">
                            <div class="modalInputs">
                                <label for="name">Studio Name*</label>
                                <input
                                    id="name"
                                    v-model="editStudioData.name"
                                    maxlength="256"
                                    type="text">
                                <span class="error">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>

                        <div class="modalInputs">
                            <label for="phone">Phone</label>
                            <input
                                id="phone"
                                v-model="editStudioData.phone"
                                type="number">
                        </div>
                    </div>

                    <div class="address modalInputs">
                        <label for="address">Address</label>
                        <input
                            id="address"
                            v-model="editStudioData.address"
                            maxlength="256"
                            type="text">
                    </div>
                </template>

                <template #footer>
                    <div class="modal-buttons">
                        <button
                            class="btn btn-l btn-borderred-light"
                            @click="$refs.studioEditModal.closeModal()">
                            Cancel
                        </button>
                        <button
                            :disabled="invalid"
                            class="btn btn-l btn-red"
                            @click="updateStudio">
                            Update
                        </button>
                    </div>
                </template>
            </modal>
        </validation-observer>
    </div>
</template>

<script>
import Modal from "@components/common/Modal"
import dropdown from "@components/common/Dropdown"
import StudioModel from "@models/Studio"
import StudioRoom from "@models/StudioRoom"
import VideoSource from "@models/VideoSource"

export default {
    components: {dropdown, Modal},
    props: ['studio'],
    data() {
        return {
            isOpen: true,
            editStudioData: {
                name: "",
                address: "",
                phone: ""
            },
            removeStudioData: {
                id: '',
                name: ''
            },
            newRoom: {
                name: '',
                video_source_id: 'all'
            },
            removeRoomData: {
                id: null,
                name: ''
            },
            editRoomData: {
                id: null,
                name: '',
                video_sources_id: []
            }
        }
    },
    computed: {
        newSessionLink() {
            return 'link'
        },
        toggleText() {
            return this.isOpen ? "Hide" : "Show"
        },
        freeVideoSources() {
            this._refreshSourceList
            return VideoSource
                .query()
                .where('studio_room_id', null)
                .get()
        },
        dropdownVideoSources() {
            return this.freeVideoSources
                .map((videoSource) => {
                    return {
                        name: videoSource.custom_name,
                        value: videoSource.id
                    }
                })
        }
    },
    methods: {
        toggle() {
            this.isOpen = !this.isOpen
        },

        openStudioEditModal(studio) {
            this.editStudioData = JSON.parse(JSON.stringify(studio))
            this.$refs.studioEditModal.openModal()
        },

        updateStudio() {
            StudioModel.api().update(this.editStudioData)
                .then(() => {
                    this.$refs.studioEditModal.closeModal()
                })
                .catch(error => {
                    if (error.response.status == 422) {
                        if (error.response.data.message.includes('Name')) {
                            this.$refs.formEdit.setErrors({name: ['Name has already been taken']})
                        }
                    }
                })
        },

        openRemoveStudioModal(studio) {
            this.removeStudioData['id'] = studio.id
            this.removeStudioData['name'] = studio.name
            this.$refs.removeStudioModal.openModal()
        },

        removeStudio() {
            StudioModel.api().remove(this.removeStudioData).then(() => {
                StudioModel.delete(this.removeStudioData.id)
                this.$refs.removeStudioModal.closeModal()
            })
        },

        addRoom() {
            if (!this.newRoom.video_source_id || this.newRoom.video_source_id == 'all') {
                this.$refs.newRoom.setErrors({video_source_id: ['This field is required']})
            } else {
                let studioParams = {
                    name: this.newRoom.name,
                    studio_id: this.studio.id
                }

                StudioRoom.api().create(studioParams)
                    .then((res) => {
                        VideoSource.api().updateFfmpegserviceAccount({
                            id: this.newRoom.video_source_id,
                            studio_room_id: res?.response?.data?.response?.studio_room?.id
                        })

                        this.newRoom = {
                            name: '',
                            video_source_id: 'all'
                        }
                        this.$refs.newRoom.reset()
                    })
                    .catch(error => {
                        if (error.response.status == 422) {
                            if (error.response.data.message.includes('Name')) {
                                this.$refs.newRoom.setErrors({name: ['Name has already been taken']})
                            }
                        }
                    })
            }
        },

        openRemoveStudioRoomModal(room) {
            this.removeRoomData['id'] = room.id
            this.removeRoomData['name'] = room.name
            this.$refs.removeStudioRoomModal.openModal()
        },

        removeStudioRoom() {
            StudioRoom.api().remove(this.removeRoomData).then(() => {
                StudioRoom.delete(this.removeRoomData.id)
                VideoSource.update({
                    where: (videoSource) => {
                        return videoSource.studio_room_id == this.removeRoomData.id
                    },
                    data: {studio_room_id: null}
                })
                this.$refs.removeStudioRoomModal.closeModal()
            })
        },

        startEditRoom(room) {
            this.editRoomData = JSON.parse(JSON.stringify(room))
        }
    }
}
</script>

<style lang="scss">
.v-studio {
    .v-dropdown-menu {
        min-width: 100%;

        a {
            white-space: nowrap;
            overflow-x: hidden;
            text-overflow: ellipsis;
        }
    }
}
</style>

<style lang="scss" scoped>
.v-studio {
    margin-top: 20px;

    &.open {
        .v-studio-header {
            border-bottom-left-radius: 0;
            border-bottom-right-radius: 0;

            .VideoClientIcon-angle-downF {
                display: inline-block;
                transform: rotate(180deg);
            }

            .headerWrapp {
                display: contents;
            }
        }

        .v-studio-body {
            border-top: none;
        }
    }

    .v-studio-header, .v-studio-body {
        padding: 15px 20px;
        border: 1px solid var(--border__separator);
    }

    .v-studio-header {
        display: flex;
        justify-content: space-between;
        background-color: rgba(9, 95, 115, 0.05);

        border-radius: 10px;
        border-bottom-left-radius: 10px;
        border-bottom-right-radius: 10px;

        .headerWrapp {
            display: contents;
        }

        .name {
            color: var(--tp__h1);
            font-weight: bold;
            font-size: 18px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            margin-right: 10px;

            @media (min-width: 1201px) {
                max-width: 230px;
            }
        }

        .address, .phone {
            color: var(--tp__main);
            font-size: 15px;
            font-weight: normal;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            line-height: 28px;
            margin-right: 10px;
        }

        .controls {
            color: var(--tp__main);
            font-weight: normal;

            width: 100px;
            min-width: 100px;
            display: flex;
            justify-content: space-between;
            align-items: center;

            i {
                cursor: pointer;
                font-size: 18px;
                color: var(--tp__main);
            }

            .toggleBtn {
                cursor: pointer;
                font-weight: bold;
                font-size: 14px;
                color: var(--tp__main);
            }
        }
    }

    .v-studio-body {
        // overflow: hidden;
        border-radius: 10px;;
        background-color: var(--bg__content);
        border-top-left-radius: 0px;
        border-top-right-radius: 0px;

        .v-rooms-form {
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            justify-content: space-between;

            .fields {
                display: flex;
                justify-content: space-between;

                .inputsWrapper {
                    display: flex;
                    flex-direction: column;

                    label {
                        font-size: 14px;
                        color: var(--tp__main);
                        margin-bottom: 0;
                        line-height: 15px;
                    }

                    input {
                        padding-left: 0;
                        margin-right: 30px;
                    }

                    select {
                        border: none;
                        border-bottom: 1px solid #baccdb;
                        padding: 5px 0;
                        background: transparent;
                        border-radius: 0;
                        font-size: 14px;
                        color: var(--tp__main);
                    }

                    input, select {
                        width: 270px;
                    }

                    .error {
                        font-size: 14px;
                        color: #f23535;
                    }
                }
            }

            .btn[disabled] {
                pointer-events: all !important;
            }

            button {
                max-height: 30px;
                font-weight: bold;
                font-size: 14px;
            }
        }

        .v-rooms-list {
            padding: 0 20px;
            background: var(--bg__content);
            border-radius: 10px;
            border: 1px solid var(--border__separator);

            .v-thead {
                font-weight: 600;
            }

            .v-trow {
                display: flex;
                padding: 15px 0;
                justify-content: space-between;
                border-bottom: 1px solid var(--border__separator);

                .v-tcell {
                    color: var(--tp__main);
                    font-size: 16px;
                    font-weight: bold;
                    flex-grow: 1;
                    flex-basis: 0;
                }
            }

            .v-trow-body {
                .content {
                    display: flex;
                    padding: 15px 0;
                    justify-content: space-between;
                    border-bottom: 1px solid var(--border__separator);

                    .remove {
                        > i, > span {
                            cursor: pointer;
                        }
                    }

                    .v-tcell {
                        color: var(--tp__main);
                        font-size: 16px;
                        font-weight: bold;
                        flex-grow: 1;
                        flex-basis: 0;

                        .btn.disabled {
                            pointer-events: auto !important;
                        }
                    }
                }
            }

            .v-tbody {
                .v-tcell {
                    white-space: nowrap;
                    overflow: hidden;
                    text-overflow: ellipsis;
                    margin-right: 10px;
                    font-weight: normal;

                    .remove {
                        color: var(--tp__main);

                        i {
                            padding-right: 10px;
                        }
                    }

                    a {
                        font-size: 12px;
                        font-weight: bold;
                    }
                }
            }
        }
    }

    .v-modal {
        &__body {
            .nameAndPhone {
                display: flex;

                :first-child {
                    margin-right: 30px;
                }

                @media (max-width: 640px) {
                    flex-direction: column;
                }
            }
        }
    }
}

@media all and (min-width: 601px) and (max-width: 1200px) {
    .v-studio {
        .v-studio-header {
            align-items: baseline;

            .headerWrapp {
                display: inline-block !important;
                width: calc(100% - 110px);
            }
        }

        .v-studio-body {
            .v-rooms-form {
                align-items: baseline;
                flex-direction: column;

                .fields {
                    width: 100%;
                    flex-direction: row;

                    :first-child {
                        margin-right: 30px;
                    }

                    .inputsWrapper {
                        padding-bottom: 20px;
                        width: 100%;

                        input, select {
                            width: 100%;
                        }
                    }
                }
            }
        }
    }
}

@media all and (max-width: 600px) {
    .v-studio {
        .v-tcell {
            margin-top: 5% !important;
        }

        .v-studio-header {
            flex-direction: column;

            .headerWrapp {
                .name, .address, .phone {
                    padding-bottom: 20px;
                }
            }

            .line {
                margin: 0 -20px;
                display: block;
                border-top: 1px solid rgba(9, 95, 115, 0.2);
            }

            .controls {
                width: 100%;
                padding-top: 20px;

                .editAndDel {
                    :first-child {
                        padding-right: 15px;
                    }
                }
            }
        }

        .v-studio-body {
            .v-rooms-form {
                flex-direction: column;
                align-items: inherit;

                .fields {
                    flex-direction: column;

                    :first-child {
                        padding-top: 5px;
                    }

                    .inputsWrapper {
                        padding-bottom: 20px;

                        input, select {
                            width: 100%;
                        }
                    }
                }
            }

            .v-rooms-list {
                .hideOnMobile {
                    display: none;
                }
            }

            .v-tbody {
                padding: 20px 0;

                :last-child {
                    padding-bottom: 0 !important;
                }

                .v-trow-body {
                    padding-bottom: 10px;
                    justify-content: space-between;
                    border-bottom: 1px solid var(--border__separator);

                    .v-tcell {
                        span {
                            font-size: 14px;
                            margin-left: 10px;
                        }

                        i {
                            padding-right: 0 !important;
                        }
                    }
                }

                .v-trow-body {
                    display: flex;
                    @media (max-width: 480px) {
                        justify-content: space-between;
                    }

                    .mobile-header {
                        width: 40%;

                        .v-tcell {
                            white-space: nowrap;
                        }
                    }

                    .mobileContent {
                        border: none;
                        padding: 0;
                        display: flex;
                        flex-direction: column;
                        align-items: flex-end;

                        .v-tcell {
                            flex-basis: auto !important;
                            max-width: 175px;
                        }

                        @media (max-width: 480px) {
                            .v-tcell {
                                font-size: 13px;
                                white-space: nowrap;
                                max-width: 95px;

                                a {
                                    padding: 0 5px;
                                    white-space: nowrap;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@media all and (min-width: 601px) {
    .line, .mobile-header {
        display: none;
    }
}
</style>