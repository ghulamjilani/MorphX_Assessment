<template>
    <div class="FS__table__wrapper">
        <m-loader
            v-if="loading"
            class="FS__loader" />
        <table
            v-else-if="freeSubscriptions.length"
            class="FS__table">
            <thead class="FS__table__head">
                <tr>
                    <th class="FS__table__head__th">
                        Name
                    </th>
                    <th class="FS__table__head__th">
                        Email
                    </th>
                    <th class="FS__table__head__th">
                        Channel
                    </th>
                    <th class="FS__table__head__th">
                        Start Date
                    </th>
                    <th class="FS__table__head__th">
                        Duration
                    </th>
                    <th class="FS__table__head__th">
                        End Date
                    </th>
                    <th class="FS__table__head__th">
                        Stopped At
                    </th>
                    <th class="FS__table__head__th">
                        Last Login
                    </th>
                </tr>
            </thead>
            <tbody class="FS__table__body">
                <tr
                    v-for="subscription in freeSubscriptions"
                    :key="subscription.id"
                    class="FS__table__body__tr">
                    <td
                        class="FS__table__td FS__table__title"
                        data-th="Name">
                        {{ subscription.user.first_name }} {{ subscription.user.last_name }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="Email">
                        {{ subscription.user.email }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="Channel">
                        {{ subscription.channel.title }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="Start Date">
                        {{ subscription.starts_at | formattedDate }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="Duration">
                        {{ subscription.duration_in_months ? `${subscription.duration_in_months} Months` : '' }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="End Date">
                        {{ subscription.end_at | formattedDate }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="End Date">
                        {{ subscription.stopped_at | formattedDate }}
                    </td>
                    <td
                        class="FS__table__td"
                        data-th="Last Login">
                        <span v-if="subscription.user.last_sign_in_at">
                            {{ subscription.user.last_sign_in_at | formattedDate }}
                        </span>
                    </td>
                </tr>
            </tbody>
        </table>
        <div
            v-else
            class="FS__empty">
            No Free Subscriptions found
        </div>
    </div>
</template>

<script>

export default {
    name: 'TableFreeSubscriptions',
    props: {
        freeSubscriptions: Array,
        loading: Boolean
    }
}
</script>
