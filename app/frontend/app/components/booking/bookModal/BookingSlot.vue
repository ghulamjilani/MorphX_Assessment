<template>
    <div class="bookUser__slot">
        <div class="bookUser__slot__info">
            <div>
                <span>Name:</span>
                {{ bookingSlot.name }}
            </div>

            <div>
                <span>Channel:</span>
                {{ bookingSlot.channel.title }}
            </div>
            <div>
                <span>Category:</span>
                {{ bookingSlot.category.name }}
            </div>
            <div>
                <span>Replay:</span>
                {{ bookingSlot.replay ? 'Included' : 'No' }}
            </div>
            <div class="bookUser__slot__info__description">
                <span>Description:</span>
                <div class="bookingSlotDescription">
                    {{ bookingSlot.description }}
                </div>
            </div>
            <div class="bookUser__slot__info__tags">
                <template>
                    <m-chips
                        v-for="tag in tags"
                        :key="tag"
                        class="tagsMK2__tag tagsMK2__tag__iconless">
                        {{ tag }}
                    </m-chips>
                </template>
            </div>
        </div>
    </div>
</template>

<script>
export default {
  props: {
    bookingSlot: {
      type: Object,
      required: true
    },
    duration: {
      required: true
    }
  },
  data() {
    return {

    }
  },
	computed: {
		tags() {
			return JSON.parse(this.bookingSlot.tags)
		}
	}
}
</script>

<style>

</style>