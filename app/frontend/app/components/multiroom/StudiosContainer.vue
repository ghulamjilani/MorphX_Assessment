<template>
    <div class="v-studios">
        <div class="add-studio-section">
            <h2>Studios</h2>
            <div class="add-btn-wrap">
                <div class="addNew">
                    Add new or edit Studios:
                </div>
                <div
                    class="add-studio-btn btn btn-m btn-red"
                    @click="$refs.studioNewModal.openModal()">
                    + Add new Studio
                </div>
            </div>
        </div>

        <div class="section-list">
            <studio
                v-for="studio in studios"
                :key="studio.id"
                :studio="studio" />
        </div>

        <validation-observer
            ref="form"
            v-slot="{ invalid }">
            <modal ref="studioNewModal">
                <template #header>
                    <h2>New Studio</h2>
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
                                    v-model="newStudioData.name"
                                    maxlength="256"
                                    type="text">
                                <span class="error">{{ errors[0] }}</span>
                            </div>
                        </validation-provider>

                        <div class="modalInputs">
                            <label for="phone">Phone</label>
                            <input
                                id="phone"
                                v-model="newStudioData.phone"
                                type="number">
                        </div>
                    </div>

                    <div class="address modalInputs">
                        <label for="address">Address</label>
                        <input
                            id="address"
                            v-model="newStudioData.address"
                            maxlength="256"
                            type="text">
                    </div>
                </template>

                <template #footer>
                    <div class="modal-buttons">
                        <button
                            class="btn btn-l btn-borderred-light"
                            @click="$refs.studioNewModal.closeModal()">
                            Cancel
                        </button>
                        <button
                            :disabled="invalid"
                            class="btn btn-l btn-red"
                            @click="saveStudio">
                            Save
                        </button>
                    </div>
                </template>
            </modal>
        </validation-observer>
    </div>
</template>

<script>
import Modal from "@components/common/Modal"
import Studio from "@components/multiroom/Studio"
import StudioModel from "@models/Studio"
import StudioRoom from "@models/StudioRoom"
import VideoSource from "@models/VideoSource"

export default {
    components: {Modal, Studio},
    data() {
        return {
            newStudioData: {
                name: "",
                address: "",
                phone: ""
            }
            // studios: [
            //   {
            //     id: 1,
            //     name: "New Yoga Studio",
            //     address: "570 Lexington Ave, Brooklyn, NY 10022, USA",
            //     phone: "8800553535",
            //     rooms: [
            //       {
            //         id: 1,
            //         name: 'Yoga room 1/1',
            //         video_source: 1,
            //       },
            //       {
            //         id: 2,
            //         name: 'Yoga room 1/2',
            //         video_source: 2,
            //       },
            //       {
            //         id: 3,
            //         name: 'Yoga room 2/1',
            //         video_source: 3,
            //       }
            //     ]
            //   },
            //   {
            //     id: 2,
            //     name: "Awesome Yoga Studio ### 1",
            //     address: "570 Lexington Ave, Brooklyn, NY 10022, USA",
            //     phone: "8800553535",
            //     rooms: [
            //       {
            //         id: 4,
            //         name: 'Yoga room 1/1',
            //         video_source: 4,
            //       },
            //       {
            //         id: 5,
            //         name: 'Yoga room 1/2',
            //         video_source: 5,
            //       },
            //       {
            //         id: 6,
            //         name: 'Yoga room 2/1',
            //         video_source: 6,
            //       }
            //     ]
            //   },
            //   {
            //     id: 3,
            //     name: "Yoga Studio Yoga Studio Yoga Studio Yoga Studio",
            //     address: "570 Lexington Ave, Brooklyn, NY 10022, USA",
            //     phone: "8800553535",
            //     rooms: [
            //     ]
            //   },
            // ]
        }
    },
    computed: {
        studios() {
            return StudioModel.query().with('rooms.video_source').get()
        }
    },
    created() {
        StudioModel.api().fetch()
        StudioRoom.api().fetch()
        VideoSource.api().fetchFfmpegserviceAccounts({current_service: "rtmp,ipcam"})
    },
    methods: {
        saveStudio() {
            StudioModel.api().create(this.newStudioData)
                .then(() => {
                    this.newStudioData = {
                        name: "",
                        address: "",
                        phone: ""
                    }
                    this.$refs.studioNewModal.closeModal()
                })
                .catch(error => {
                    if (error.response.status == 422) {
                        if (error.response.data.message.includes('Name')) {
                            this.$refs.form.setErrors({name: ['Name has already been taken']})
                        }
                    }
                })
        }
    }
}
</script>

<style lang="scss" scoped>
.v-studios {
    padding: 15px 20px;
    border-radius: 10px;
    background-color: var(--bg__content);
    box-shadow: 0 4px 7px 0 var(--sh__main);


    .add-studio-section {
        h2 {
            color: var(--tp__h1);
            font-weight: bold;
        }

        .add-btn-wrap {
            display: flex;
            justify-content: space-between;
            align-items: center;

            .addNew {
                color: var(--tp__main);
            }

            .add-studio-btn {
                font-weight: bold;
                font-size: 14px;
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

@media (max-width: 500px) {
    .v-studios {
        .add-studio-section {
            .add-btn-wrap {
                flex-direction: column;
                align-items: inherit;

                .addNew {
                    padding-bottom: 20px;
                }
            }
        }
    }
}
</style>