### Example

```vue
  <m-datepicker label="Birthday" />
```

```vue
<template>
  <m-datepicker v-model="date" label="From" />
</template>

<script>
export default {
  data() {
    return {
      date: new Date(),
    }
  }
}
</script>

```

```vue
<template>
  <m-datepicker v-model="date" :range="true" :labels="['From', 'To']" />
</template>

<script>
export default {
  data() {
    return {
      date: {
        start: new Date(2020, 0, 1),
        end: new Date(2020, 0, 5)
      }
    }
  }
}
</script>

```