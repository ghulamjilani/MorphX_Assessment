<template>
    <div class="statistics-channel">
        <div class="statistics-channel__wrapper">
            <div class="statistics-channel__left-part">
                <img
                    alt="Channel cover"
                    class="statistics-channel_left-part_channel-cover"
                    src="https://encrypted-tbn0.gstatic.com/images?q=tbn%3AANd9GcRhoZS7KOyl0ECqODvTGUVSBog9lAzqR9-x9Q&usqp=CAU">
            </div>
            <div class="statistics-channel__right-part">
                <div class="statistics-channel_right-part__title title bold fs-18 text-color-Darkgrey margin-bottom-15">
                    {{ channel.name }}
                </div>
                <div class="statistics-channel__right-part__info">
                    <div class="statistics-channel_right-part__info-item infoItem">
                        <i class="VideoClientIcon-stream-video-icon fs-17" />
                        <span class="bold text-color-Darkgrey">{{ channel.past_sessions_count }}</span>
                        <span>Sessions</span>
                    </div>
                    <div class="statistics-channel_right-part_info_item infoItem">
                        <i class="VideoClientIcon-play-circle fs-22" />
                        <span class="bold text-color-Darkgrey">{{ channel.replays_count }}</span>
                        <span>Replays</span>
                    </div>

                    <div class="statistics-channel_right-part_info_item infoItem">
                        <i class="VideoClientIcon-disc fs-22" />
                        <span class="bold text-color-Darkgrey">{{ channel.recordings_count }}</span>
                        <span>Recordings</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
export default {
    /*
    Channel:
    {
      "name": "Guitar",
      "sessions_count": 1,
      "replays_count": 0,
      "recordings_count": 0,
      "creators": [
        {
          "name": "conumoquj",
          "logo_url": "https://my.unite.live/assets/gender/male-3bdcc9dd5244dc0fcaed2d10c0489112587592bf1ac31736a02597a362924c22.png",
          "url": "https://my.unite.live/conumoquj"
        }
      ]
    }
    */
    props: ['channel']
}
</script>

<style lang="scss">
.statistics-container_channel-list {
    padding: 30px;

    .statistics-channel {
        margin-right: -30px;
        margin-left: -30px;
        border-bottom: 1px solid var(--border__separator);
        margin-bottom: 30px;

        &:last-child {
            border: none;
            margin-bottom: 0;
        }

        &__wrapper {
            padding: 0 30px 30px 30px;
            display: flex;
        }

        &__left-part {
            img {
                max-width: 300px;
                max-height: 80px;
                min-height: 80px;
                border-radius: 5px;
                margin-right: 25px;
            }
        }

        &__right-part {
            display: flex;
            flex-direction: column;
            width: 100%;

            &__info {
                display: flex;
                align-items: center;
                width: max-content;

                .infoItem {
                    margin-right: 60px;
                    @media all and (min-width: 992px) and (max-width: 1199px) {
                        margin-right: 30px;
                    }

                    &:last-child {
                        margin-right: 0;
                    }
                }
            }

            i {
                margin-right: 10px;
                color: var(--tp__h1);
            }
        }
    }

    @media all and (max-width: 767px) {
        .statistics-channel {
            width: 50%;
            margin: 0;
            border: 0;

            &:first-child {
                margin-right: 25px;
            }

            &__wrapper {
                flex-direction: column;
                padding: 0;
            }

            &__left-part {
                img {
                    max-width: 100%;
                    width: 100%;
                    margin-right: 0;
                }
            }

            &__right-part {
                flex-direction: column;

                .title {
                    padding-bottom: 10px;
                    border-bottom: 1px solid var(--border__separator);
                }

                &__info {
                    flex-direction: column;
                    align-items: flex-start;
                }
            }
        }
    }
    @media all and (max-width: 500px) {
        .statistics-channel {
            width: 100%;
            margin-bottom: 30px;
        }
    }
}
</style>