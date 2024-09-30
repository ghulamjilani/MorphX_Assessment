<template>
    <div class="sandbox">
        <!-- <div class="sandbox-wrapp"> -->
        <AuthComponent />
            <!-- <m-btn @click="openModal" /> -->
            <!-- <DocumentPayment /> -->
            <!-- <create-poll
                :model-id="288"
                :model-type="'Session'">
                <button>Create Poll</button>
            </create-poll>
            <create-poll
                :is-poll-create="false">
                <button>Create Poll Template</button>
            </create-poll>

            <poll /> -->
        <!-- </div> -->
    </div>
</template>


<script>
// import CreatePoll from '@components/polls/CreatePoll.vue'
// import Poll from '@components/polls/Poll.vue'
// import DocumentPayment from '@components/documents/DocumentPayment.vue'
import AuthComponent from '@components/modals/AuthComponent.vue'

export default {
    components: {
        AuthComponent
        // DocumentPayment
        // CreatePoll,
        // Poll
    },
    data () {
        return {
        }
    },
    mounted() {

    },
    methods: {
        openModal() {
            // this.$eventHub.$emit("open-modal:documentPayment", {})
        }
    }
}
</script>

<style lang="scss">
    .sandbox-wrapp {
        margin: 10rem;
        max-width: 98.3rem;
        min-height: 20rem;
        background: var(--bg__content);
        box-shadow: 0 4px 7px 0 var(--sh__main);
        border-radius: 1rem;
        margin-bottom: 3rem;
    }
</style>