<template>
    <section class="content__wrapp">
        <div class="content__main announcement__wrapp">
            <div class="announcement__left">
                <div class="announcement__left__content">
                    <span
                        class="announcement__text"
                        v-html="bannerContent" />
                    <Upp__svg class="Upp Upp__1"/>
                    <Upp__svg class="Upp Upp__2"/>
                </div>
                <Sh__1__svg class="sh__balloon sh__1 sh__ColorMain"/>
                <Sh__2__svg class="sh__balloon sh__2 sh__ColorMain"/>
                <Sh__2__svg class="sh__balloon sh__3 sh__ColorMain sh__opacity"/>
                <Sh__2__svg class="sh__balloon sh__4 sh__ColorMain sh__opacity"/>
                <Sh__2__svg class="sh__balloon sh__5 sh__ColorMain"/>
                <Sh__1__svg class="sh__balloon sh__6 sh__ColorSecond"/>
            </div>
            <div class="announcement__right">

                <Transition appear
                            :duration="5500"
                            name="bubble" >

                    <div class="announcement__bubble">
                        <span
                            class="announcement__label"
                            v-html="bannerLabel" />
                        <img :src="require('../../../../assets/images/homePage/announcement/bubble.png')" alt="">
                    </div>
                </transition>
                <Sh__1__svg class="sh__balloon sh__1 sh__ColorMain"/>
                <Sh__2__svg class="sh__balloon sh__2 sh__ColorMain sh__opacity"/>
                <Sh__3__svg class="sh__balloon sh__3 sh__ColorSecond"/>
                <Sh__3__svg class="sh__balloon sh__4 sh__ColorMain"/>
                <Sh__1__svg class="sh__balloon sh__5 sh__ColorMain"/>
                <Sh__2__svg class="sh__balloon sh__6 sh__ColorMain"/>
                <Sh__2__svg class="sh__balloon sh__7 sh__ColorMain sh__opacity"/>
                <Sh__1__svg class="sh__balloon sh__8 sh__ColorSecond"/>
                <Sh__1__svg class="sh__balloon sh__9 sh__ColorSecond"/>
                <people-svg class="sh__people"/>
            </div>
        </div>
    </section>
</template>

<script>
import Sh__1__svg from "./sh__1__svg"
import Sh__2__svg from "./sh__2__svg"
import Sh__3__svg from "./sh__3__svg"
import Upp__svg   from "./upp__svg"
import PeopleSvg  from "./peopleSvg"

export default {
    name: "BannerAnnouncement",
    components: {PeopleSvg, Upp__svg, Sh__3__svg, Sh__2__svg, Sh__1__svg},
    props: {
      bannerLabel: String,
      bannerContent: String
    },
    data() {
        return {
            Content: "Starting september 2022 our new domain and your new home will change from unite.live to <a href='https://joybee.live' title='https://joybee.live'> joybee.live</a>",
            Label:"Announcement"
        }
    },
    mounted () {

    },
    destroyed () {

    },
    methods: {

    }
}
</script>

<style lang="scss">
    @import "app/frontend/app/assets/styles/core/_mixin.scss";

    .announcement{
      &__wrapp{
        --announcement__sh: var(--btn__main);
        background: var(--bg__secondary);

        padding: 0 6rem;
        @include flex($align_items:stretch);
        position: relative;
        height: 50rem;
        @include media(tablet){
          height: auto;
          padding: 3rem 1rem;
        }
      }
      &__left{
        width: 100%;
        font-size: 4rem;
        color: var(--tp__h1);
        line-height: 4.7rem;
        font-weight: bold;
        position: relative;
        z-index: 10;
        position: relative;
        @include flex($align_items:center);
        a{
          color: var(--btn__main);
        }
        &__content{
          padding-right: 2rem;
          position: relative;
          @include media(p-tablet){
            padding-right: 0rem;
          }
        }
        .sh{
          &__1{
            top: 10%;
            left: 14%;
            animation: driftFlip 5.5s ease-in-out infinite;
            transform: scaleX(-1);
          }
          &__2{
            bottom: 10%;
            left: 20%;
            transform: translateY(-2rem) rotate(-6deg);
            animation: driftBottom 7s ease-in-out infinite;
          }
          &__3{
            bottom: 10%;
            left: 18%;
            width: 2.6rem;
            animation: drift 8s ease-in-out infinite;
          }
          &__4{
            top: 7%;
            right: 18%;
            width: 2.3rem;
            transform: translateY(-2rem) rotate(-6deg);
            animation: driftBottom 10s ease-in-out infinite;
          }
          &__5{
            top: 9%;
            right: 14%;
            animation: driftFlip 6s ease-in-out infinite;
            transform: scaleX(-1);
          }
          &__6{
            bottom: 9%;
            right: 34%;
            animation: drift 7.5s ease-in-out infinite;
          }
        }
      }
      &__right{
        flex-basis:35rem;
        position: relative;
        margin-bottom: -1.5rem;
        display: flex;
        align-items: flex-end;
        @include media(p-tablet){
          display: none;
        }
        .sh{
          &__people{
            position: relative;
            z-index: 2;
          }
        }
        .sh {
          &__1 {
            bottom: 5%;
            left: 58%;
            animation: drift 6s ease-in-out infinite;
          }
          &__2 {
            bottom: 27%;
            left: 26%;
            width: 2rem;
            animation: driftBottom 7s ease-in-out infinite;
          }
          &__3 {
            bottom: 38%;
            left: 12%;
            animation: driftFlip 5s ease-in-out infinite;
            transform: scaleX(-1);
          }
          &__4 {
            bottom: 45%;
            right: 6%;
            animation: drift 7s ease-in-out infinite;
          }
          &__5 {
            bottom: 46%;
            left: 24%;
            width: 3.4rem;
            animation: driftBottom 6s ease-in-out infinite;
          }
          &__6 {
            bottom: 71%;
            left: 39%;
            animation: drift 5.4s ease-in-out infinite;
          }
          &__7 {
            bottom: 58%;
            left: 51%;
            width: 2.5rem;
            animation: driftBottom 9s ease-in-out infinite;
          }
          &__8 {
            bottom: 48%;
            left: 54%;
            width: 3.7rem;
            animation: drift 6.4s ease-in-out infinite;
          }
          &__9 {
            bottom: 49%;
            width: 3rem;
            left: 65%;
            animation: driftBottom 7s ease-in-out infinite;
          }
        }
      }
      &__text{
        position: relative;
        display: inline-block;
        z-index: 5;
        @include media(tablet){
          backdrop-filter: blur(10px);
          background: rgba(255,255,255,0.4);
          padding: 1rem;
          box-shadow: 0px 0px 12px rgb(255 255 255);
        };
        @include media(p-tablet){
          border: 1px solid rgba(0,0,0,1);
        }
      }
      &__bubble{
        width: 62%;
        bottom: 40%;
        transform:  translateX(0) scale(1);
        opacity: 1;
        position: absolute;
        left: 20%;
        z-index: 1;
        img{
          width: 100%;
          position: relative;
          z-index: 1;
        }
      }
      &__label{
        color: var(--btn__main);
        text-transform: uppercase;
        font-weight: bold;
        transform: translate(-50%, -50%) rotate(-16deg);
        opacity: 1;
        z-index: 2;
        display: inline-block;
        text-align: center;
        position: absolute;
        left: 54%;
        bottom: 39%;
      }
    }

    .sh {
      &__balloon {
        position: absolute;
      }

      &__ColorMain {
        --announcement__sh: var(--btn__main);
      }

      &__ColorSecond {
        --announcement__sh: #455A64;
      }

      &__opacity {
        opacity: 0.2;
      }
    }

    .Upp{
      position: absolute;
      @include media(p-tablet){
        display: none;
      }
      &__1{
        top: 110%;
        right: 20%;
      }
      &__2{
        bottom: 110%;
        left: 20%;
        transform: rotate(40deg);
      }
    }



    @keyframes drift{
      0% {transform: translateY(0px) rotate(0deg);}
      50% {transform: translateY(-1rem) rotate(-6deg);}
      100% {transform: translateY(0px) rotate(0deg);}
    }
    @keyframes driftBottom{
      0% {transform: translateY(-.3rem) rotate(-6deg);}
      50% {transform: translateY(.6rem) rotate(0deg);}
      100% {transform: translateY(-.3rem) rotate(-6deg);}
    }
    @keyframes driftFlip{
      0% {transform: translateY(0px) rotate(0deg) scaleX(-1);}
      50% {transform: translateY(-1rem) rotate(-6deg) scaleX(-1);}
      100% {transform: translateY(0px) rotate(0deg) scaleX(-1);}
    }

    .bubble-enter-from {
      width: 30%;
      bottom: 44%;
    }
    .bubble-enter-active {
      animation: bubble-in 2s ;
      .announcement__label{
        animation: label-fade-in 2s ease-out;
      }
    }
    .bubble-leave-active {
      animation: bubble-in 2s reverse;
      animation-delay: 1s;
      .announcement__label{
        animation: label-fade-in 2s ease-out reverse;
      }
    }
    @keyframes bubble-in {
      0% {
        transform:  translate(-30%, 10%) scale(.2);
      }
      60% {
        transform: translate(7%, 0%) scale(1.2);
      }
      100% {
        transform:  translate(0, 0%) scale(1);
      }
    }
    @keyframes label-fade-in {
      0% {
        opacity: 0;
        transform:  translate(-50%, -50%) rotate(-17deg);
      }
      60% {
        opacity: .3;
        transform:  translate(-50%, -50%) rotate(-17deg);
      }
      100% {
        opacity: 1;
        transform:  translate(-50%, -50%) rotate(-17deg);
      }
    }
</style>