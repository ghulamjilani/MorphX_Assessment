<template>
    <div
        class="BPlanding"
        :class="{'unitePricingPage': isUnite, 'onePlan': planPackages.length == 1}">
        <div
            ref="preloader"
            class="BPlanding__head__wrapp">
            <div class="BPlanding__head">
                <h3>{{ $t('pricing_page.banner.choose_the_best_plan') }}</h3>
                <!--<h4>{{ $t('pricing_page.banner.discover') }}</h4>-->
                <div class="BPlanding__switchBtn">
                    <a
                        :class="{active: interval == '1 Month'}"
                        class="month"
                        @click="setInterval('1 Month')">{{ $t('frontend.app.pages.business_plans.banner.monthly') }}</a>
                    <a
                        :class="{active: interval == '1 Year'}"
                        class="year"
                        @click="setInterval('1 Year')">{{ $t('frontend.app.pages.business_plans.banner.yearly') }}</a>
                    <span class="you_can_save">{{ $t('frontend.app.pages.business_plans.banner.you_can_save', {maxDiscount}) }}</span>
                </div>
                <div class="BPlanding__head__img">
                    <div class="BPlanding__head__img__l">
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__1">
                            <image-money />
                        </span>
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__2">
                            <image-money />
                        </span>
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__3">
                            <image-money />
                        </span>
                        <div class="plant1">
                            <image-pl1
                                :class="{active: isPlantActive}"
                                class="plant1__top" />
                            <img
                                :src="$img['bp_pl_bottom']"
                                class="plant1__bottom">
                        </div>
                        <image-pl2
                            :class="{active: isPlantActive}"
                            class="plant2" />
                        <div
                            :style="bubbleWrappStyles"
                            class="bubble__wrapp">
                            <image-bubble class="bubble" />
                            <image-check class="bubble__check" />
                        </div>
                    </div>
                    <div class="BPlanding__head__img__r">
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__1">
                            <image-money />
                        </span>
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__2">
                            <image-money />
                        </span>
                        <span
                            :style="coinStyles"
                            class="BPcoin BPcoin__3">
                            <image-money />
                        </span>
                        <div class="plant1">
                            <image-pl1r
                                :class="{active: isPlantActive}"
                                class="plant1__top" />
                            <img
                                :src="$img['bp_pl_bottom']"
                                class="plant1__bottom">
                        </div>
                        <image-pl2
                            :class="{active: isPlantActive}"
                            class="plant2" />
                        <div class="characters">
                            <image-characters class="characters__img" />
                            <div
                                :style="bubbleWrappStyles"
                                class="bubble__wrapp">
                                <image-bubble class="bubble" />
                                <image-check class="bubble__check" />
                            </div>
                            <gr-r-bg
                                :style="charactersBgStyles"
                                class="characters__bg" />
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="BPlanding__plans__wrapp smallScrollsH">
            <div class="BPlanding__plans">
                <div
                    v-if="mobileView"
                    class="BPlanding__plans__responsive smallScrollsH">
                    <m-btn
                        v-for="(planPackage, index) in planPackages"
                        :key="planPackage.name+index"
                        :class="{active: isPlanActive(planPackage.name)}"
                        type="bordered"
                        @click="setCurrentPlan(planPackage.name)">
                        {{ planPackage.name }}
                    </m-btn>
                </div>
                <div class="BPlanding__plans__tiles__wrapp">
                    <div
                        v-for="(planPackage, index) in planPackages"
                        v-show="!mobileView || planPackage.name == currentPlan"
                        :key="planPackage.name"
                        class="BPlanding__plans__tiles"
                        :style="{'min-width': 100 / planPackages.length - 1 + '%'}">
                        <div class="BPlanding__plans__tiles__head">
                            <div class="planTile__wrapp">
                                <template v-if="planPackage.name == 'Free'">
                                    <div class="planTile planTile__type1" />
                                </template>
                                <template>
                                    <div :class="['planTile', `planTile__type${index+2}`]">
                                        <div class="cube__wrapp">
                                            <div class="cube cube__front" />
                                            <div class="cube cube__back" />
                                            <div class="cube cube__right" />
                                            <div class="cube cube__left" />
                                            <div class="cube cube__top" />
                                            <div class="cube cube__bottom" />
                                        </div>
                                    </div>
                                </template>
                            </div>
                            {{ planPackage.name }}
                        </div>
                        <div class="BPlanding__plans__tiles__body">
                            <div class="fs__15 description">
                                {{ planPackage.description }}
                            </div>
                            <div class="tl__price">
                                <div v-if="!planPackage.isEnterprise" :class="['tl__discount__sum', {'hide': (interval == '1 Month' || discountYear(planPackage) == 0)}]">
                                    <span class="tl__discount">{{ discountYear(planPackage) }}%</span>
                                    <span class="tl__sum">{{ getAnnualAmountMonth(planPackage) }}</span>
                                </div>
                                <div
                                    class="tl__cost"
                                    :class="{'tl__cost__enterprise': planPackage.isEnterprise}">
                                    {{ getIntervalAmount(planPackage, interval) }}
                                </div>
                            </div>
                            <div class="tl__annually">
                                <span v-if="!planPackage.isEnterprise" :class="{'hide': interval == '1 Month'}">
                                    {{ $t('frontend.app.pages.business_plans.plans.billed_annually') }}
                                </span>
                            </div>
                            <div class="tl__overcharge">
                                {{ $t('pricing_page.plans.usage_charges') }}
                            </div>
                            <div class="tl__spacesWrap">
                                <div
                                    v-if="getCodeValue(planPackage, 'storage') >= 1024"
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-disc-space" />
                                    {{ (getCodeValue(planPackage, 'storage') / 1024 ) | shortNumber(false, 1) }} TB
                                </div>
                                <div
                                    v-else-if="planPackage.isEnterprise"
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-disc-space" /> {{ $t('frontend.app.pages.business_plans.plans.unlimited') }}
                                </div>
                                <div
                                    v-else
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-disc-space" />
                                    {{ getCodeValue(planPackage, 'storage') }} GB
                                </div>

                                <div
                                    v-if="planPackage.isEnterprise"
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-stream-video" />
                                    Customizable
                                </div>
                                <div
                                    v-else
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-stream-video" />
                                    {{ getCodeValue(planPackage, 'streaming_time') }} {{ $t('frontend.app.pages.business_plans.plans.min') }} ({{ $t('frontend.app.pages.business_plans.plans.live') }})
                                </div>

                                <div
                                    v-if="planPackage.isEnterprise"
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-users" />
                                    Customizable
                                </div>
                                <div
                                    v-else
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-users" />
                                    {{ getCodeValue(planPackage, 'interactive_streaming_time') }} {{ $t('frontend.app.pages.business_plans.plans.min') }} ({{ $t('frontend.app.pages.business_plans.plans.interactive') }})
                                </div>


                                <div
                                    v-if="planPackage.isEnterprise"
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-play" />
                                    Customizable
                                </div>
                                <div
                                    v-else
                                    class="tl__spacesWrap__spaces">
                                    <i class="GlobalIcon-play" />
                                    {{ (getCodeValue(planPackage, 'transcoding_time') / 1024 ) | shortNumber(false, 1) }}
                                    {{ $t('frontend.app.pages.business_plans.plans.tera_bytes') }} {{ $t('frontend.app.pages.business_plans.plans.video_playback') }}
                                </div>
                            </div>
                            <div v-if="canBuySubscription()">
                                <!--if plan dont have trial periyd-->

                                <!--unless it's an interprise-->
                                <div v-if="!planPackage.isEnterprise">

                                    <!--selected plan for year or month?-->
                                    <div v-if="interval == '1 Month'">
                                        <!--is the trial enabled and does the user have the necessary abilities?-->
                                        <!--show the buy trial button and the buy trial modal window, show the buy plan button-->
                                        <!-- <div v-if="getIntervalTrialDays(planPackage, interval) > 0 && (!currentUser || !currentUser.subscriptionAbility || currentUser.subscriptionAbility.have_trial_service_subscription)">
                                            <m-btn
                                                class="margin-b__15 margin-t__25"
                                                full="true"
                                                type="bordered"
                                                @click="openBuyCreatorPlanTrialModal(planPackage)">
                                                Start Free Trial
                                            </m-btn>
                                            <label @click="openBuyCreatorPlanModal(planPackage)">
                                                {{$t('pricing_page.plans.or_purchase_now') }} </label>
                                        </div> -->

                                        <!--Trial for this plan is less than 0 days?-->
                                        <!--we do not show the trial purchase button, we display the purchase button and buy plan modal -->
                                        <div class="startTrial__wrapper">
                                            <m-btn class="margin-b__15 margin-t__25"
                                                   full="true"
                                                   type="bordered"
                                                   @click="openBuyCreatorPlanModal(planPackage)">
                                                Purchase Now
                                            </m-btn>
                                            <label
                                                v-if="getIntervalTrialDays(planPackage, interval) > 0 &&
                                                    (!currentUser || !currentUser.subscriptionAbility || currentUser.subscriptionAbility.have_trial_service_subscription)"
                                                class="startTrial"
                                                @click="openBuyCreatorPlanTrialModal(planPackage)">
                                                {{ $t('pricing_page.plans.or_start_trial') }}
                                            </label>
                                        </div>
                                    </div>
                                    <!--selected plan for year or Year?-->
                                    <div v-if="interval == '1 Year'">
                                        <!--is the trial enabled and does the user have the necessary abilities?-->
                                        <!--show the buy trial button and the buy trial modal window, show the buy plan button-->
                                        <!-- <div v-if="getIntervalTrialDays(planPackage, interval) > 0 && (!currentUser || currentUser.subscriptionAbility && currentUser.subscriptionAbility.have_trial_service_subscription)">
                                            <m-btn
                                                class="margin-b__15 margin-t__25"
                                                full="true"
                                                type="bordered"
                                                @click="openBuyCreatorPlanTrialModal(planPackage)">
                                                Start Free Trial
                                            </m-btn>
                                            <label @click="openBuyCreatorPlanModal(planPackage)"> {{
                                                $t('pricing_page.plans.or_purchase_now')
                                            }} </label>
                                        </div> -->
                                        <!--Trial for this plan is less than 0 days?-->
                                        <!--we do not show the trial purchase button, we display the purchase button and buy plan modal -->
                                        <div class="startTrial__wrapper">
                                            <m-btn class="margin-b__15 margin-t__25"
                                                   full="true"
                                                   type="bordered"
                                                   @click="openBuyCreatorPlanModal(planPackage)">
                                                Purchase Now
                                            </m-btn>
                                            <label
                                                v-if="getIntervalTrialDays(planPackage, interval) > 0 &&
                                                    (!currentUser || currentUser.subscriptionAbility &&
                                                        currentUser.subscriptionAbility.have_trial_service_subscription)"
                                                class="startTrial"
                                                @click="openBuyCreatorPlanTrialModal(planPackage)">
                                                {{ $t('pricing_page.plans.or_start_trial') }}
                                            </label>
                                        </div>
                                    </div>
                                </div>

                                <div v-if="planPackage.isEnterprise">
                                    <m-btn
                                        class="margin-b__15 margin-t__25"
                                        full="true"
                                        type="bordered"
                                        @click="openContactUsModal">
                                        {{ $t('pricing_page.plans.contact') }}
                                    </m-btn>
                                </div>
                            </div>

                        </div>
                        <div class="BPlanding__plans__tiles__footer">
                            <a
                                v-if="planPackage.name == 'Free'"
                                class="btn btn-m btn-borderred-grey">
                                Try
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            <div
                class="BPlanding__plans__desc">
                <div
                    v-for="(feature) in featuresUIList"
                    v-show="(feature.code != 'free_trial_period' || (feature.code == 'free_trial_period' && trialExist))"
                    :key="feature.code"
                    class="BPP__row">
                    <div
                        v-show="!mobileView"
                        class="BPP__head">
                        {{ feature.title }}
                        <i
                            v-tooltip="feature.description"
                            class="GlobalIcon-info" />
                    </div>

                    <div
                        v-show="tabletView"
                        class="BPP">
                        {{ feature.title }}
                        <i
                            v-tooltip="feature.description"
                            class="GlobalIcon-info" />
                    </div>

                    <div
                        v-for="planPackage in planPackages"
                        v-show="!mobileView || planPackage.name == currentPlan"
                        :key="planPackage.name"
                        class="BPP">
                        <i
                            v-if="mobileView"
                            v-tooltip="feature.description"
                            class="GlobalIcon-info" />
                        <div
                            v-show="mobileView"
                            class="text__bold margin-b__20">
                            {{ feature.title }}
                        </div>

                        <div v-if="feature.code == 'video_creation_content_management'">

                            <!--max_channels_count-->
                            <p>
                                <b v-if="getCodeValue(planPackage, 'max_channels_count') == '1'">{{
                                    getCodeValue(planPackage, 'max_channels_count')
                                }} {{ $t('frontend.app.pages.business_plans.info.channel') }}</b>
                                <b v-else>{{ getCodeValue(planPackage, 'max_channels_count') }}
                                    {{ $t('frontend.app.pages.business_plans.info.channel') }}s</b>
                            </p>

                            <!--Livestreaming-->
                            <p> Livestreaming </p> <!--TODO:ADD LOCALIZATION-->

                            <!--Replays-->
                            <p> Replays </p> <!--TODO:ADD LOCALIZATION-->

                            <!--max_session_duration_up_to-->
                            <p>
                                {{ $t('frontend.app.pages.business_plans.info.max_session_duration_up_to') }}
                                <b>{{ getCodeValue(planPackage, 'max_session_duration') | minsToHours }} {{
                                    $t('frontend.app.pages.business_plans.info.hours')
                                }}</b>
                                <b v-if="planPackage.isEnterprise">
                                    on Demand<!--TODO:ADD LOCALIZATION-->
                                </b>
                            </p>

                            <!--private_sessions-->
                            <p v-if="getCodeValue(planPackage, 'private_sessions') === 'true'">
                                Private Option<!--TODO:ADD LOCALIZATION-->
                            </p>

                            <!--interactive_stream-->
                            <p v-if="getCodeValue(planPackage, 'interactive_stream') === 'true'">
                                {{ $t('frontend.app.pages.business_plans.info.interactive_conference') }}
                                max for {{getCodeValue(planPackage, 'max_interactive_participants')}} participants
                            </p>

                            <!--multi_room-->
                            <p v-if="getCodeValue(planPackage, 'multi_room') === 'true'">
                                Multi Facility Management (a la carte)<!--TODO:ADD LOCALIZATION-->
                            </p>

                            <!--co_hosting-->
                            <p v-if="getCodeValue(planPackage, 'co_hosting') == 'true'">
                                Co-Hosting (Coming Soon)<!--TODO:ADD LOCALIZATION-->
                            </p>

                            <!--mobile_apps-->
                            <p v-if="getCodeValue(planPackage, 'mobile_apps') == 'true'">
                                {{ $t('pricing_page.info.ios_and_android_apps') }}  (Coming Soon)<!--TODO:ADD LOCALIZATION-->
                            </p>
                        </div>

                        <div v-if="feature.code == 'storage_space'">

                            <b v-if="planPackage.isEnterprise">
                                <!--{{ $t('pricing_page.info.customizable') }}-->
                                Unlimited<!--TODO:ADD LOCALIZATION-->
                            </b>
                            <b v-else-if="getCodeValue(planPackage, 'storage') >= 1024">
                                <!-- translate GB to TB -->
                                {{ (getCodeValue(planPackage, 'storage') / 1024 ) | shortNumber(false, 1) }} TB
                            </b>
                            <b v-else>
                                {{ getCodeValue(planPackage, 'storage') }} GB
                            </b>
                        </div>

                        <div v-if="feature.code == 'monetization_options'">
                            <!--split_revenue_percent-->
                            <p v-if="planPackage.owner_split_revenue_percent != 100">
                                {{ $t('pricing_page.info.split_revenue_percent', {percents: planPackage.platform_split_revenue_percent} ) }}
                            </p>

                            <!--ppv-->
                            <p v-if="getCodeValue(planPackage, 'ppv') == 'true'">
                                {{ $t('pricing_page.info.ppv') }}
                            </p>

                            <!--gift_channel_subscription-->
                            <p v-if="getCodeValue(planPackage, 'gift_channel_subscription') == 'true'">
                                {{ $t('pricing_page.info.gifting') }}
                            </p>

                            <!--online_store-->
                            <p v-if="getCodeValue(planPackage, 'online_store') == 'true'">
                                {{ $t('frontend.app.pages.business_plans.info.online_store') }}
                            </p>

                            <!--channel_subscriptions-->
                            <p v-if="getCodeValue(planPackage, 'channel_subscriptions') == 'true'">
                                {{ $t('pricing_page.info.subscriptions_for_channel') }}
                            </p>

                            <p v-if="getCodeValue(planPackage, 'donations') == 'true'">
                                Donations (Beta)
                            </p>

                            <!--instream_shopping-->

                            <p v-if="getCodeValue(planPackage, 'instream_shopping') == 'true'">
                                {{ $t('frontend.app.pages.business_plans.info.stream_shopping') }}
                            </p>

                        </div>

                        <div v-if="feature.code == 'user_management'">

                            <!--  manage_admins == 'false'
                                  manage_creators == 'false'  -->
                            <template
                                v-if="getCodeValue(planPackage, 'manage_admins') == 'false' && getCodeValue(planPackage, 'manage_creators') == 'false'">
                                <b>1 Owner</b>
                            </template>


                            <!--  manage_admins == 'true'
                                  manage_creators == 'false'  -->
                            <template
                                v-if="getCodeValue(planPackage, 'manage_admins') == 'true' && getCodeValue(planPackage, 'manage_creators') == 'false'">
                                <p>
                                    <b>1 Owner,</b>
                                    <b v-if="getCodeValue(planPackage, 'max_admins_count') === -1"> {{ $t('frontend.app.pages.business_plans.info.unlimited') }} </b> <!-- if unlimited admins -->
                                    <b v-else> {{ getCodeValue(planPackage, 'max_admins_count') }} </b>
                                    <b>{{ $t('frontend.app.pages.business_plans.info.admin') }}</b>
                                </p>
                                <p>{{ $t('frontend.app.pages.business_plans.info.organization_members_management') }}</p>
                            </template>

                            <!--  manage_admins == 'true'
                                  manage_creators == 'true'  -->
                            <template
                                v-if="getCodeValue(planPackage, 'manage_admins') == 'true' && getCodeValue(planPackage, 'manage_creators') == 'true'">
                                <p>
                                    <b>1 Owner,</b>

                                    <b v-if="getCodeValue(planPackage, 'max_admins_count') < 0 "> {{ $t('frontend.app.pages.business_plans.info.unlimited') }} </b> <!-- if unlimited admins -->
                                    <b v-else> {{ getCodeValue(planPackage, 'max_admins_count') }} </b>
                                    <b>{{ $t('frontend.app.pages.business_plans.info.admins')}}</b>

                                    {{ $t('frontend.app.pages.business_plans.info.and')}}

                                    <b v-if="getCodeValue(planPackage, 'max_creators_count') < 0"> {{ $t('frontend.app.pages.business_plans.info.unlimited') }} </b> <!-- if unlimited Creators -->
                                    <b v-else> {{ getCodeValue(planPackage, 'max_creators_count') }} </b>
                                    <b>{{ $t('frontend.app.pages.business_plans.info.creators')}}</b>
                                </p>

                                <p>{{ $t('frontend.app.pages.business_plans.info.organization_members_management') }}</p>
                            </template>

                        </div>

                        <div v-if="feature.code == 'social_features'">

                            <!--constant_contact-->
                            <p v-if="getCodeValue(planPackage, 'constant_contact') == 'true'">
                                {{ $t('pricing_page.info.integration_constant') }}
                            </p>


                            <!--audience_chat-->
                            <p v-if="getCodeValue(planPackage, 'audience_chat') == 'true'">
                                {{ $t('pricing_page.info.audience_chat') }}
                            </p>

                            <!--community_blog-->

                            <p v-if="getCodeValue(planPackage, 'community_blog') == 'true'">
                                {{ $t('frontend.app.pages.business_plans.info.personalized_community_blog') }}
                            </p>

                            <!--<p>-->
                            <!--    Internal Direct Messaging Service(Coming Soon)&lt;!&ndash;TODO:ADD LOCALIZATION&ndash;&gt;-->
                            <!--</p>-->

                            <!--Document Management-->
                            <p v-if="getCodeValue(planPackage, 'document_management') == 'true'">
                                Document Management<!--TODO:ADD LOCALIZATION-->
                            </p>

                        </div>

                        <div v-if="feature.code == 'other_video_features'">

                            <!--add_free_streaming-->
                            <p v-if="getCodeValue(planPackage, 'add_free_streaming') == 'true'">
                                {{ $t('pricing_page.info.free_streaming') }}
                            </p>

                            <!--ip_cam-->
                            <p v-if="getCodeValue(planPackage, 'ip_cam') == 'true'">
                                {{ $t('pricing_page.info.ip_camera') }}
                            </p>

                            <!--encoder-->
                            <p v-if="getCodeValue(planPackage, 'encoder') == 'true'">
                                {{ $t('pricing_page.info.encoder') }}
                            </p>

                            <!--multi_language-->
                            <p v-if="getCodeValue(planPackage, 'multi_language') == 'true'">
                                {{ $t('pricing_page.info.support_multiple_languages') }}
                            </p>

                            <!--full_hd_uploads-->
                            <p v-if="getCodeValue(planPackage, 'full_hd_uploads') == 'true'">
                                {{ $t('pricing_page.info.full_uploads') }}
                            </p>

                            <!--video_transcoding-->
                            <p v-if="getCodeValue(planPackage, 'video_transcoding') == 'true'">
                                {{ $t('pricing_page.info.transcoding') }}
                            </p>

                            <!--embed-->
                            <p v-if="getCodeValue(planPackage, 'embed') == 'true'">
                                {{ $t('pricing_page.info.player') }}
                            </p>

                        </div>

                        <div v-if="feature.code == 'analytics'">
                            <!--analytics-->
                            <p v-if="getCodeValue(planPackage, 'analytics') == 'true'">
                                {{ $t('pricing_page.info.real_time') }}
                            </p>

                            <!--statistics-->
                            <p v-if="getCodeValue(planPackage, 'statistics') == 'true'">
                                {{ $t('pricing_page.info.statistics') }}
                            </p>
                        </div>

                        <div v-if="feature.code == 'support_level'">
                            {{ getCodeValue(planPackage, 'support_level') }}
                        </div>

                        <div v-if="feature.code == 'free_trial_period' && isTrialPlan(planPackage) && trialExist">
                            <p v-if="planPackage.isEnterprise" />
                            <p v-else>
                                {{ getTrialText(planPackage) }}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="BPlanding__body hide">
            <div class="BPlanding__body__section">
                <div class="BPlanding__body__section__img">
                    <span
                        style="background-image: url(https://i.pinimg.com/564x/fa/14/a4/fa14a4ef72ae902e45bb92f18055cb7e.jpg)" />
                </div>
                <div class="BPlanding__body__section__content">
                    <div class="text-color-red fs-15">
                        Add-on
                    </div>
                    <div class="fc-main-dark bold fs-22 margin-bottom-10">
                        Need help with live-streaming?
                    </div>
                    <div>
                        Be ready for the next wave of Live Stream and Video on Demand features give you the tools you
                        need to meet demand for virtual fitness, add value to your memberships, and deliver your
                        services to clients wherever they are.
                    </div>
                    <div class="text-color-red fs-32 bold margin-bottom-20">
                        $9.99
                        <span class="fs-12">/mo</span>
                    </div>
                    <a
                        class="btn btn-m padding-left-40 padding-right-40"
                        href="#">Contact Sales</a>
                </div>
            </div>
        </div>
        <div class="BPlanding__adds hidden">
            <div class="BPlanding__adds__title">
                <b class="fs__30 color__h1">Unlock your potential with powerful add-ons</b>
                <span class="fs__16">
                    Boost the functionality of your software and improve your client retention by
                    adding these optional products to your plan
                </span>
            </div>
            <div class="BPlanding__adds__WrapperSections">
                <div class="BPlanding__adds__WrapperSections__section">
                    <img
                        :src="$img['adds_1']"
                        alt>
                    <label>Add-on</label>
                    <span class="fs__22">Rent camera</span>
                    <p>
                        Be ready for the next wave of Live Stream and Video on Demand
                        features give you the tools and services to clients wherever they are.
                    </p>
                    <div class="BPlanding__adds__WrapperSections__section__pricing">
                        <span class="fs__32">$9.99/mo</span>
                        <m-btn type="bordered">
                            Buy
                        </m-btn>
                    </div>
                </div>
                <div class="BPlanding__adds__WrapperSections__section">
                    <img
                        :src="$img['adds_2']"
                        alt>
                    <label>Add-on</label>
                    <span class="fs__22">Rent camera</span>
                    <p>
                        Be ready for the next wave of Live Stream and Video on Demand
                        features give you the tools and services to clients wherever they are.
                    </p>
                    <div class="BPlanding__adds__WrapperSections__section__pricing">
                        <span class="fs__32">$9.99/mo</span>
                        <m-btn type="bordered">
                            Buy
                        </m-btn>
                    </div>
                </div>
                <div class="BPlanding__adds__WrapperSections__section">
                    <img
                        :src="$img['adds_3']"
                        alt>
                    <label>Add-on</label>
                    <span class="fs__22">Rent camera</span>
                    <p>
                        Be ready for the next wave of Live Stream and Video on Demand
                        features give you the tools and services to clients wherever they are.
                    </p>
                    <div class="BPlanding__adds__WrapperSections__section__pricing">
                        <span class="fs__32">$9.99/mo</span>
                        <m-btn type="bordered">
                            Buy
                        </m-btn>
                    </div>
                </div>
            </div>
        </div>
        <div class="BPlanding__footer hidden">
            <div class="BPlanding__footer__wrapper">
                <div class="BPlanding__footer__wrapper__title">
                    <span class="fs__32 text__bold text__center">Every plan comes with:</span>
                </div>
                <div class="BPlanding__footer__wrapper__body">
                    <div
                        v-for="i in 6"
                        :key="i"
                        class="BPlanding__footer__wrapper__body__section">
                        <span><i class="GlobalIcon-check fs__14" /></span>
                        <b class="fs__14">1-on-1 support and training</b>
                    </div>
                </div>
            </div>
        </div>
        <div class="BPlanding__appex">
            <p>{{ $t('frontend.app.pages.business_plans.info.pricing_change') }}</p>
        </div>
        <contact-us-modal ref="contactUsModal" />
        <buy-creator-plan-trial ref="buyCreatorPlanTrial" />
        <buy-creator-plan ref="buyCreatorPlan" />
    </div>
</template>

<script>
import ContactUsModal from "@components/modals/ContactUsModal"
import BuyCreatorPlanTrial from "@components/modals/BuyCreatorPlanTrial"
import BuyCreatorPlan from "@components/modals/BuyCreatorPlan"

import PlanPackage from '@models/PlanPackage'
import ImageBubble from "../assets/images/BusinessPlans/ImageBubble"
import ImageCheck from "../assets/images/BusinessPlans/ImageCheck"
import ImageCharacters from "../assets/images/BusinessPlans/ImageCharacters"
import ImageMoney from "../assets/images/BusinessPlans/ImageMoney"
import ImagePl2 from "../assets/images/BusinessPlans/ImagePl2"
import ImagePl1 from "./../assets/images/BusinessPlans/ImagePl1"
import ImagePl1r from "../assets/images/BusinessPlans/ImagePl1r"
import GrRBg from "../assets/images/BusinessPlans/gr-rBg"

import eventHub from "@helpers/eventHub.js"
import filtersv2 from "@helpers/filtersv2"

export default {
    components: {
        GrRBg,
        ImagePl1r,
        ImagePl2,
        ImageMoney,
        ImageCharacters,
        ImageCheck,
        ImageBubble,
        ContactUsModal,
        BuyCreatorPlanTrial,
        BuyCreatorPlan,
        ImagePl1
    },
    data() {
        return {
            isPlantActive: false,
            interval: '1 Year', // 1 Month, 1 Year
            charactersBgStyles: {
                transform: ''
            },
            coinStyles: {
                transform: ''
            },
            bubbleWrappStyles: {
                transform: ''
            },
            windowWidth: 0,
            currentPlan: 'Starter',
            tabletView: false,
            mobileView: false,
            featuresUIList: [
                {
                    code: "video_creation_content_management",
                    title: this.$t('frontend.app.pages.business_plans.info.video_creation_content_management'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.video_creation_tooltip')
                },
                {
                    code: "storage_space",
                    title: this.$t('frontend.app.pages.business_plans.info.storage_space'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.storage_space_tooltip')
                },
                {
                    code: "monetization_options",
                    title: this.$t('frontend.app.pages.business_plans.info.monetization_options'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.monetization_tooltip')
                },
                {
                    code: "user_management",
                    title: this.$t('frontend.app.pages.business_plans.info.user_management'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.management_tooltip')
                },
                {
                    code: "social_features",
                    title: this.$t('frontend.app.pages.business_plans.info.social_features'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.featuresTooltip')
                },
                {
                    code: "other_video_features",
                    title: this.$t('frontend.app.pages.business_plans.info.other_video_features'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.other_features_tooltip')
                },
                {
                    code: "analytics",
                    title: this.$t('frontend.app.pages.business_plans.info.analytics'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.analytics_tooltip')
                },
                {
                    code: "support_level",
                    title: this.$t('frontend.app.pages.business_plans.info.support_level'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.support_tooltip')
                },
                {
                    code: "free_trial_period",
                    title: this.$t('frontend.app.pages.business_plans.info.free_trial_period'),
                    description: this.$t('frontend.app.pages.business_plans.tooltips.trial_tooltip')
                }
            ],
            maxDiscount: 0,
            trialExist: false
        }
    },
    computed: {
        planPackages() {
            return PlanPackage.query().orderBy('position').get()
        },
        currentUser() {
            return this.$store.getters["Users/currentUser"]
        },
        pricingConfig() {
            return this.$railsConfig.frontend?.pricing
        },
        isPlanPeriodBoth() {
            return this.prisingConfig?.plan_periods == 'both'
        },
        canSave() {
            return 20
        },
        isUnite() {
            return this.$railsConfig.global.project_name == 'unite'
        }
    },
    watch: {
        planPackages(val) {
            if (val.length) {
                this.currentPlan = val[0].name
            }
        }
    },
    mounted() {
        document.body.classList.add("BusinessPlans")

        PlanPackage.api().fetch()
        if(this.pricingConfig.enterprise_plan) {
            PlanPackage.insert({
            data: [
                {
                    isEnterprise: true,
                    id: 999999999999999999999,
                    name: this.$t('frontend.app.pages.business_plans.plans.enterprise'),
                    custom: false,
                    active: true,
                    recommended: false,
                    description: this.$t('frontend.app.pages.business_plans.plans.discover_your_potential'),
                    position: 4,
                    platform_split_revenue_percent: 'Custom ',
                    owner_split_revenue_percent: 'Custom ',
                    plans: [{
                        id: 1,
                        active: true,
                        stripe_id: null,
                        trial_period_days: 7,
                        plan_package_id: 1,
                        name: this.$t('frontend.app.pages.business_plans.plans.enterprise'),
                        amount: "CUSTOMIZABLE",
                        formatted_interval: "1 Month"
                    }, {
                        id: 2,
                        active: true,
                        stripe_id: null,
                        trial_period_days: 7,
                        plan_package_id: 1,
                        name: this.$t('frontend.app.pages.business_plans.plans.enterprise'),
                        amount: "CUSTOMIZABLE",
                        formatted_interval: "1 Year"
                    }],
                    features: [{
                        code: "storage",
                        value: "-1",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "streaming_time",
                        value: "500",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "transcoding_time",
                        value: "500",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "max_channels_count",
                        value: "-1",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "max_session_duration",
                        value: "1440",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "private_sessions",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "co_hosting",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "mobile_apps",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "ppv",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "gift_channel_subscription",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "donations",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "video_transcoding",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "analytics",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "statistics",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "support_level",
                        value: "Coming soon: 24/7 Live Streaming Support.Chat Support responsive within 2 hours during US business hours and overnight",
                        // value: "24/7 Live Streaming Support.Chat Support responsive within\n" +
                        //     "2 hours during US business\n" +
                        //     "hours and overnight",
                        validation_regexp: "/(.*)/",
                        parameter_type: "string"
                    }, {
                        code: "instream_shopping",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "add_free_streaming",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "audience_chat",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "document_management",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "channel_subscriptions",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "online_store",
                        value: "false",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "community_blog",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "ip_cam",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "encoder",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "embed",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "manage_admins",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "max_admins_count",
                        value: "-1",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: "manage_creators",
                        value: "true",
                        validation_regexp: "/(true|false)/",
                        parameter_type: "boolean"
                    }, {
                        code: "max_creators_count",
                        value: "-1",
                        validation_regexp: "/(\\d*)/",
                        parameter_type: "integer"
                    }, {
                        code: 'multi_room',
                        value: 'true'
                    }, {
                        code: 'max_interactive_participants',
                        value: '49'
                    }, {
                        code: 'interactive_stream',
                        value: 'true'
                    }]
                }
            ]
        })
        }
        setTimeout(() => {
            this.isPlantActive = true
        }, 500)

        document.addEventListener('mousemove', (event) => {
            var i = this.$refs.preloader.getBoundingClientRect(),
                x = Math.round(Math.floor(-(i.left + i.width)) / 60),
                y = Math.round(Math.floor(-(i.top + i.height)) / 30)

            x += (event.screenX - x) / 100
            y += (event.screenY - y) / 100

            this.charactersBgStyles.transform = `translate3d(${-x}px, ${-y}px, 0)`
            this.coinStyles.transform = `translate3d(${-x / 3}px, ${-y / 2}px, 0)`
            this.bubbleWrappStyles.transform = `translate3d(${-x / 20}px, ${-y / 8}px, 0)`
        })

        this.$nextTick(function () {
            window.addEventListener('resize', this.getWindowWidth)
            this.getWindowWidth()
        })

        eventHub.$on('openBuyCreatorPlanModal', (data) => {
            this.$refs.buyCreatorPlan.open(data.planPackage, data.interval)
        })

        eventHub.$on('openBuyCreatorPlanTrialModal', (data) => {
            this.$refs.buyCreatorPlanTrial.open(data.planPackage, data.interval)
        })
    },
    beforeDestroy() {
        window.removeEventListener('resize', this.getWindowWidth)
        document.body.classList.remove("BusinessPlans")
    },
    methods: {
        localeString(amount, options) {
            return filtersv2.formattedPrice(amount, options)
        },
        discountYear(planPackage) {
            let annualAmountMonth = planPackage.plans.find((el) => {
                return el.formatted_interval === '1 Month'
            })?.annual_amount
            let annualAmountYear = planPackage.plans.find((el) => {
                return el.formatted_interval === '1 Year'
            })?.annual_amount
            let discount = Math.floor(100 - annualAmountYear * 100 / annualAmountMonth)
            if(discount > this.maxDiscount) {this.maxDiscount = discount}
            return discount*-1
        },
        getAnnualAmountMonth(planPackage) {
            let plan = planPackage.plans.find((el) => {
                return el.formatted_interval === '1 Month'
            })
            return this.localeString(plan.amount, plan.money_currency)
        },
        getIntervalAmount(planPackage, interval) {
            let plan = planPackage.plans.find((el) => {
                return el.formatted_interval === interval
            })
            return isNaN(plan.amount) ? plan.amount : this.localeString(plan.annual_amount/12, plan.money_currency)
        },
        getIntervalTrialDays(planPackage, interval) {
            return planPackage.plans.find((el) => {
                return el.formatted_interval === interval
            })?.trial_period_days
        },
        getCodeValue(planPackage, code) {
            if (code == 'max_channels_count' || code == 'max_session_duration') {
                return this.unlimitedOrvalue(planPackage.features.find((el) => {
                    return el.code === code
                })?.value)
            }
            if (code == 'max_interactive_participants'){ //show max number of participants with +1 (host)
                let max_interactive_participants = planPackage.features.find((el) => {
                    return el.code === code
                })?.value
                return (~~max_interactive_participants + 1)
            }
            return planPackage.features.find((el) => {
                return el.code === code
            })?.value
        },
        openContactUsModal() {
            this.$refs.contactUsModal.open()
        },
        openBuyCreatorPlanTrialModal(planPackage) {
            if (this.currentUser) {
                this.$refs.buyCreatorPlanTrial.open(planPackage, this.interval)
            } else {
                this.$eventHub.$emit("open-modal:auth", "login", {
                    action: "close-and-emit",
                    event: 'openBuyCreatorPlanTrialModal',
                    data: {
                        planPackage: planPackage,
                        interval: this.interval
                    }
                })
            }
        },
        openBuyCreatorPlanModal(planPackage) {
            if (this.currentUser) {
                this.$refs.buyCreatorPlan.open(planPackage, this.interval)
            } else {
                this.$eventHub.$emit("open-modal:auth", "login", {
                    action: "close-and-emit",
                    event: 'openBuyCreatorPlanModal',
                    data: {
                        planPackage: planPackage,
                        interval: this.interval,
                        modal: ''
                    }
                })
            }
        },
        getWindowWidth(event) {
            this.windowWidth = document.documentElement.clientWidth
            if (this.windowWidth <= 480) {
                this.mobileView = true
            } else {
                this.mobileView = false
            }
        },
        setCurrentPlan(newPlanType) {
            this.currentPlan = newPlanType
        },
        isPlanActive(planType) {
            return this.currentPlan == planType
        },
        setInterval(newInterval) {
            this.interval = newInterval
        },
        unlimitedOrvalue(value) {
            return value == '-1' ? 'Unlimited' : value
        },
        getTrialText(planPackage) {
            let trial = planPackage.plans.find((el) => {
                return el.formatted_interval === this.interval
            })
            trial = trial ? trial.trial_period_days : false
            if (!trial || trial === 0) {
                return this.$t('frontend.app.pages.business_plans.plans.no_trial')
            }
            else if(trial / 30 >= 1) {
                let month = Math.floor(trial / 30)
                let days = trial % 30
                let str = ""
                if (month > 0) str += `${month} month`
                if (days > 0) str += `${month > 0 ? ' and ' : ''}${days} day${days > 1 ? 's' : ''}`
                return `${str}`
            }
            else {
                // for days, if 1 day then no end s
                return `${trial} day${trial > 1 ? 's' : ''}`
            }
        },
        isTrialPlan(planPackage){
            let trial = planPackage.plans.find((el) => {
                return el.formatted_interval === this.interval
            })
            trial = trial ? trial.trial_period_days : false
            if (!trial || trial > 0) {
                this.trialExist = true
            }
            return !trial || trial > 0
        },
        canBuySubscription(){
            if (!ConfigGlobal.service_subscriptions?.purchase_permission_required) return true;

            return !!this.currentUser?.can_buy_subscription;
        }
    }
}
</script>
