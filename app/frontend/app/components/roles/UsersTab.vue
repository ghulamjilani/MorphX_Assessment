<template>
    <div>
        <r-filters />
        <members-table />
    </div>
</template>

<script>
import RFilters from "./RFilters"
import MembersTable from './MembersTable.vue'

export default {
    name: 'RolesUsersTab',
    components: {RFilters, MembersTable}
}
</script>