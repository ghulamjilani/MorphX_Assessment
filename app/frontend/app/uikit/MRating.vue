<template>
    <!-- <ul class="starRating clearfix">
    <li v-for="index in 5" :key="index">
        <div v-if="roundedRating - index >= 0" class="VideoClientIcon-starF"></div>
        <div v-else-if="roundedRating - index < 0 && roundedRating - index > -1" class="VideoClientIcon-star-half-altF"></div>
        <div v-else class="VideoClientIcon-star-emptyF"></div>
    </li>
  </ul> -->
    <div>
        <div
            v-if="stars"
            :class="'rating__star__' + parseInt(rating)"
            class="rating__star__wrapp">
            <span
                :class="{'rating__star__edit' : editable}"
                class="GlobalIcon-star"
                @click="changeRating(1)" />
            <span
                :class="{'rating__star__edit' : editable}"
                class="GlobalIcon-star"
                @click="changeRating(2)" />
            <span
                :class="{'rating__star__edit' : editable}"
                class="GlobalIcon-star"
                @click="changeRating(3)" />
            <span
                :class="{'rating__star__edit' : editable}"
                class="GlobalIcon-star"
                @click="changeRating(4)" />
            <span
                :class="{'rating__star__edit' : editable}"
                class="GlobalIcon-star"
                @click="changeRating(5)" />
            <span
                v-if="showText && rating > 0"
                class="rating__star__count">{{ rating }} <span v-if="editable"> / 5</span></span>
        </div>
        <div
            v-else
            class="rating__smile__wrapp">
            <img
                :class="{'rating__smile__active' : parseInt(rating) == 1}"
                :src="$img['bad-smile']"
                alt="bad-smile"
                class="rating__smile"
                @click="changeRating(1)">
            <img
                :class="{'rating__smile__active' : parseInt(rating) == 3}"
                :src="$img['normal-smile']"
                alt="normal-smile"
                class="rating__smile"
                @click="changeRating(3)">
            <img
                :class="{'rating__smile__active' : parseInt(rating) == 5}"
                :src="$img['good-smile']"
                alt="good-smile"
                class="rating__smile"
                @click="changeRating(5)">
        </div>
    </div>
</template>

<script>
export default {
    props: {
        editable: {
            type: Boolean,
            default: false
        },
        showText: {
            type: Boolean,
            default: true
        },
        value: {
            type: Number,
            default: 0
        },
        stars: {
            type: Boolean,
            default: true
        }
    },
    data() {
        return {
            rating: this.value
        }
    },
    computed: {
        roundedRating() {
            return Math.ceil(this.rating * 2) / 2
        }
    },
    watch: {
        value(val) {
            if (this.rating !== val) this.rating = val
        }
    },
    methods: {
        changeRating(val) {
            if (!this.editable) return
            else this.rating = val
            this.$emit("input", this.rating)
            this.$emit("change", this.rating)
        }
    }
}
</script>

