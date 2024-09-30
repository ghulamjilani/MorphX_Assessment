<template>
    <div v-if="currentUser && paymentTransactions.length">
        <div class="business_plan__current__billingHistory">
            <label>Billing History</label>
            <table class="full__width">
                <thead>
                    <tr class="text__left">
                        <th>Date</th>
                        <th>Type</th>
                        <th>Transaction ID</th>
                        <th>Price</th>
                    </tr>
                </thead>
                <tbody>
                    <tr
                        v-for="paymentTransaction in paymentTransactions"
                        :key="paymentTransaction.id">
                        <td data-attr="Date">
                            {{ paymentTransaction.checked_at | formattedDate(true, false, timeFormat) }}
                        </td>
                        <td data-attr="Type">
                            {{ displayingPlanName(paymentTransaction) }}
                        </td>
                        <td data-attr="Transaction ID">
                            {{ paymentTransaction.pid }}
                        </td>
                        <td data-attr="Price">
                            {{ paymentTransaction.total_amount * 100 | formattedPrice }} (USD)
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</template>

<script>
import PaymentTransaction from '@models/PaymentTransaction'

export default {
    props: [
        'planName',
        'purchased_item_id',
        'purchased_item_type',
        'purchased_item_name'
    ],
    computed: {
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        timeFormat() {
            return this.currentUser.time_format == "12hour" ? 'DD MMMM YYYY, hh:mm A' : 'DD MMMM YYYY, HH:mm'
        },
        paymentTransactions() {
            return PaymentTransaction.query().orderBy('checked_at', 'desc').get()
        }
    },
    mounted() {
        let params = {
            order: 'desc',
            limit: 100
        }
        if (this.purchased_item_id) {
            params['purchased_item_id'] = this.purchased_item_id
        }
        if (this.purchased_item_type) {
            params['purchased_item_type'] = this.purchased_item_type
        }
        PaymentTransaction.api().fetch(params)
    },
    methods: {
        displayingPlanName(paymentTransaction) {
            return paymentTransaction.planName || paymentTransaction.purchased_item_name || this.planName
        }
    }
}
</script>