<template>
    <div class="tabsMK2">
        <div class="tabsMK2__titles">
            <div
                v-for="tab in tabs"
                :key="tab.title"
				:class="['tabsMK2__title', {'tabsMK2__title__active': current == tab}, tab.additionalClass]"
                @click="change(tab)">
                {{ tab.title }}
            </div>
        </div>
        <slot />
    </div>
</template>

<script>
/**
 *  <m-tabs>
 <m-tab title="test 1">text 1</m-tab>
 <m-tab title="test 2">text 2</m-tab>
 </m-tabs>
 */
export default {
    data() {
        return {
            tabs: [],
            current: null
        }
    },
    methods: {
        change(tab) {
            this.current = tab
        },
        changeByName(name) {
            this.current = this.tabs.find(tab => tab.title === name)
        },
        registerTab(tab) {
            if (!this.current) {
                this.current = tab
            }
            this.tabs.push(tab)
        }
    }
}
</script>

