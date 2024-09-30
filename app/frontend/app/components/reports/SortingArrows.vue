<template>
    <div class="sorting-arrows">
        <m-icon
            size="0.9rem"
            class="reports-table__sortingUp"
            :class="{'active': sorting.order == 1 && field == sorting.field}">
            GlobalIcon-angle-down
        </m-icon>
        <m-icon
            size="0.9rem"
            :class="{'active': sorting.order != 1 && field == sorting.field}">
            GlobalIcon-angle-down
        </m-icon>
    </div>
</template>

<script>
export default {
  props: {
    field: String,
    sorting: Object
  }
}
</script>

<style>

</style>