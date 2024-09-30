### Example

```vue
<template>
  <m-select v-model="model" :options="options" label="Test" />
</template>

<script>
export default {
  data() {
    return {
      options: [
        {name: "Test 1", value: 1},
        {name: "Test 2", value: 2},
      ],
      model:null,
    }
  }
}
</script>

```

```vue
<template>
  <m-select v-model="model" :options="options" plaseholder="Test" />
</template>

<script>
export default {
  data() {
    return {
      options: [
        {name: "Test 1", value: 1},
        {name: "Test 2", value: 2},
      ],
      model:null,
    }
  }
}
</script>

```

```vue
<template>
  <m-select v-model="model" :options="options" :pure="true"/>
</template>

<script>
export default {
  data() {
    return {
      options: [
        {name: "Test 1", value: 1},
        {name: "Test 2", value: 2},
      ],
      model: 1,
    }
  }
}
</script>

```
