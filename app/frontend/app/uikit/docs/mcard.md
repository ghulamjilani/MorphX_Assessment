 ### Example
 
Horizontal mode

```vue
<template>
  <m-card orientation="horizontal">
    <template v-slot:top>
      <div class="fp-content">
        First Part
      </div>
    </template>

    <template v-slot:bottom>
      <div class="sp-content">
        Second Part
      </div>
    </template>
  </m-card>
</template>

<style lang="scss">
.fp-content{
  height: 100px;
  background: #e2e2e2;
}

.sp-content{
  height: 100px;
  background: #cecece;
}
</style>
```
Vertical mode

```vue
<template>
  <m-card orientation="vertical">
    <template v-slot:top>
      <div class="fp-content">
        First Part
      </div>
    </template>

    <template v-slot:bottom>
      <div class="sp-content">
        Second Part
      </div>
    </template>
  </m-card>
</template>

<style lang="scss">
.fp-content{
  height: 100px;
  background: #e2e2e2;
}

.sp-content{
  height: 100px;
  background: #cecece;
}
</style>
```