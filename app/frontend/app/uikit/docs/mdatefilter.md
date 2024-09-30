### Example

```vue
<template>
  <m-date-filter v-model="dateFilter" style="width: 340px;"/>
</template>

<script>
export default {
  data() {
    return {
      dateFilter: {
        date: null,
        dateValue: "all"
      }
    }
  }
}
</script>

```