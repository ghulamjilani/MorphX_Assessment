<template>
    <div
        :id="title.toLowerCase().replace(/ /g, '_')"
        class="homePage__creators">
        <div
            v-if="users.length || !loading"
            class="container">
            <div class="homePage__title__wrapper homePage__title__wrapper__creators">
                <h3
                    class="homePage__title homePage__title__creators">
                    {{ useStandartTitle ? $t('views.home_page.connent_with_creators', {creators_upper: $t('dictionary.creators_upper')}) : title }}
                </h3>
                <a
                    class="homePage__title__more homePage__title__more__creators"
                    href="/search?ford=views_count&ft=User">{{ $t('home_page.titles.see_more') }}</a>
            </div>
            <div class="TileSlider__Wrapper">
                <div
                    v-if="loading"
                    class="TileSlider">
                    <vue-horizontal-list
                        :items="users"
                        :options="options">
                        <template #default="{item}">
                            <user-tile
                                :exist-user="item.user"
                                :use-promo-weight="promoWeight" />
                        </template>
                    </vue-horizontal-list>
                </div>
                <div
                    v-else
                    class="mChannel__tiles__list">
                    <div class="mChannel__tiles__items placeholder">
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                        <tile-placeholder class="cardMK2" />
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import TilePlaceholder from "@components/TilePlaceholder"
import UserTile from "../tiles/UserTile"
import VueHorizontalList from 'vue-horizontal-list'
import SelfFollows from "@models/SelfFollows"
import Search from "@models/Search"

export default {
    components: {TilePlaceholder, VueHorizontalList, UserTile},
    props: {
        title: String,
        useStandartTitle: {
            type: Boolean,
            default: false
        },
        orderBy: String,
        onlyShowOnHome: Boolean,
        hideOnHome: {
            type: Boolean,
            default: false
        },
        promoWeight: Boolean,
        order: String,
        itemsCount: Number
    },
    data() {
        return {
            users: [],
            loading: false,
            options: {
                responsive: [
                    {end: 640, size: 1.2},
                    {start: 641, end: 767, size: 2.5},
                    {start: 768, end: 991, size: 2.5},
                    {start: 992, end: 1199, size: 3},
                    {start: 1950, end: 2249, size: 5},
                    {start: 2250, size: 6},
                    {size: 4}
                ],
                list: {
                    windowed: 992
                }
            }
        }
    },
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        }
    },
    watch: {
        currentUser: {
            handler(val) {
                if (val) {
                    SelfFollows.api().getFollows({followable_type: "User"})
                }
            },
            deep: true,
            immediate: true
        }
    },
    mounted() {
        this.loadCreators()
    },
    methods: {
        loadCreators() {
            Search.api().searchApi({
                show_on_home: (this.onlyShowOnHome ? true : null),
                hide_on_home: (this.hideOnHome ? false : null),
                limit: this.itemsCount || 12,
                order_by: this.orderBy,
                order: this.order,
                searchable_type: "User",
                promo_weight: (this.promoWeight ? '1' : null)
            }).then((res) => {
                this.users = this.users.concat(res.response.data.response.documents?.map(e => {
                    e.searchable_model.type = e.document.searchable_type.toLowerCase()
                    e.searchable_model.user = Object.assign(e.searchable_model.user, e.document)
                    return e.searchable_model
                }))
                this.loading = true
                this.$eventHub.$emit('home-page:scroll__creators', (this.users.length))
                this.$nextTick(() => { this.$eventHub.$emit("componentSettings:checkState") })
            })
        }
    }
}
</script>
