### Example

```vue
<template>
  <m-checkbox v-model="check">{{check ? "Selected" : "Not selected"}}</m-checkbox>
</template>

<script>
export default {
  data() {
    return {
      check: true
    }
  }
}
</script>

```

```vue
<template>
  <div>
    <m-checkbox v-model="check" val="1">1</m-checkbox>
    <br />
    <m-checkbox v-model="check" val="2">2</m-checkbox>
    <br />
    <m-checkbox v-model="check" val="3">3</m-checkbox>
    <br />
    {{check}}
  </div>
</template>

<script>
export default {
  data() {
    return {
      check: []
    }
  }
}
</script>

```