<template>
    <a
        class="ad"
        :href="'https://servedbyadbutler.com/go2/;ID=187571;size=1254x348;setID=' + adKey"
        target="_blank">
        <img :src="'https://servedbyadbutler.com/adserve/;ID=187571;size=1254x348;setID=' + adKey + ';type=img'">
    </a>
</template>

<script>
export default {
  name: 'AdButler',
  props: {
    adKey: String || Number
  }
}
</script>