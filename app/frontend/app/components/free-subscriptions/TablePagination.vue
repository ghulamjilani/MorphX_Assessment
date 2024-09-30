<template>
    <div class="FS__paginate">
        <p class="FS__paginate__text">
            {{ paginationData.offset + 1 }}-{{ paginationData.limit > paginationData.total ? paginationData.total : paginationData.limit }} From {{ paginationData.total }}
        </p>
        <a
            class="FS__paginate__arrow"
            :class="{ FS__paginate__disable: paginationData.offset + 1 <= paginationData.perPage }"
            @click="$emit('prevPage')">
            <m-icon class="FS__paginate__icon">
                GlobalIcon-angle-left
            </m-icon>
        </a>
        <a
            class="FS__paginate__arrow"
            :class="{ FS__paginate__disable: paginationData.limit >= paginationData.total }"
            @click="$emit('nextPage')">
            <m-icon class="FS__paginate__icon">
                GlobalIcon-angle-right
            </m-icon>
        </a>
    </div>
</template>

<script>
export default {
    props: {
        paginationData: Object
    }
}
</script>
