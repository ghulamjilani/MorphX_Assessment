<template>
    <div>
        <div
            :id="title.toLowerCase().replace(/ /g, '_')"
            class="container bookingUsers">
            <div class="homePage__title__wrapper">
                <h3
                    class="homePage__title">
                    {{ title }}
                </h3>
                <!-- <a
                    v-if="showSeeMore"
                    class="homePage__title__more"
                    href="/organizations">{{ $t('home_page.titles.see_more') }}</a> -->
            </div>

            <BookingUsersRow
                :users="users" />
        </div>
    </div>
</template>

<script>
import BookingUsersRow from "@components/booking/BookingUsersRow"
import Search from "@models/Search"

export default{
  components: {BookingUsersRow},
  props: {
    title: String,
    useStandartTitle: {
      type: Boolean,
      default: false
    },
    onlyShowOnHome: Boolean,
        hideOnHome: {
            type: Boolean,
            default: false
        },
    promoWeight: Boolean,
    itemsCount: Number,
    orderBy: String,
    order: String,
    showMore: {
        type: Boolean,
        default: false
    },
    loadCount: {
        type: Number,
        default: 8
    },
    isScrollable: {
        type: Boolean,
        default: true
    }
  },
  data() {
    return {
      users: [],
      loading: false,
      count: 0,
      showMoreLoading: false
    }
  },
  computed: {
    currentUser() {
        return this.$store.getters["Users/currentUser"]
    },
    showSeeMore() {
        return this.$route.name == "MainPage"
    }
  },
  mounted() {
    this.LoadUsers()
  },
  methods: {
    LoadUsers() {
      this.loading = true
      Search.api().searchApi({
          show_on_home: (this.onlyShowOnHome ? true : null),
          hide_on_home: (this.hideOnHome ? false : null),
          limit: this.itemsCount || 100,
          // order_by: this.orderBy,
          order: this.order,
          searchable_type: "User",
          promo_weight: (this.promoWeight ? '1' : null),
          has_booking_slots: true
      }).then((res) => {
          this.users = this.users.concat(res.response.data.response.documents?.map(e => {
              e.searchable_model.type = e.document.searchable_type.toLowerCase()
              e.searchable_model.user = Object.assign(e.searchable_model.user, e.document)
              return e.searchable_model.user
          })).filter(e => e.has_booking_slots).slice(0, 4)
          this.loading = false
      })
    }
  }
}
</script>
