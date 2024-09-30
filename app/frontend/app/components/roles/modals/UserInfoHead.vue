<template>
    <div class="newRoleUser__head">
        <div class="newRoleUser__head__avatar logo__xl">
            <img :src="member.user ? member.user.avatar_url : ''">
        </div>
        <div class="newRoleUser__head__name">
            <!--<div class="newRoleUser__head__name__userStatus"></div>-->
            <span>{{ member.user.public_display_name }}</span>
            <!--<div class="GlobalIcon-Pensil2 fs__20 color__icons"></div>-->
        </div>
        <!--<div class="newRoleUser__head__status">-->
        <!--<span>Status:</span>-->
        <!--<label>{{member.status}}</label>-->
        <!--<div class="GlobalIcon-angle-down padding-l__10 color__icons fs__10"></div>-->
        <!--</div>-->
        <!-- <m-btn class="" size="main" type="bordered">Message</m-btn> -->
    </div>
</template>

<script>
export default {
    props: {
        member: Object
    }
}
</script>
