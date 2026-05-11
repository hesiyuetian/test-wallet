<template>
    <!-- <div class="footer">
        <div class="item" v-for="item in nav" :key="item.path" :class="{ active: route.path === item.path }"
            @click="jump(item.path)">
            <img :src="`/images/menu/${item.icon}${route.path === item.path ? '-active' : ''}.png`" alt="" />
            {{ item.name }}
        </div>
    </div> -->
    <img class="logo" src="~/images/base/logo.png" alt="">
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const route = useRoute();
const router = useRouter();
const nav = ref([
    {
        name: '首页',
        icon: 'home',
        path: '/',
    },
    {
        name: '质押',
        icon: 'stake',
        path: '/stake',
    },
    {
        name: '我的',
        icon: 'my',
        path: '/my',
    },
]);
const jump = path => {
    router.push(path);
    window.scrollTo(0, 0);
};
</script>

<style scoped lang="scss">
.footer {
    display: flex;
    width: calc(100% - 0.26rem);
    border-radius: 0.1rem 0.1rem 0 0;
    // border: 0.01rem solid #FFCC00;
    position: fixed;
    bottom: 0.12rem;
    left: 50%;
    transform: translateX(-50%);
    align-items: center;
    justify-content: space-between;
    z-index: 99;
    max-width: calc(450px - 0.26rem);
    height: .4rem;
    border-radius: 0.2rem;
    overflow: hidden;
    background: linear-gradient(132deg, #3D1C63 0%, #66438D 100%);
    padding-inline: .22rem;


    .item {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 0.06rem;
        padding-inline: .2rem;
        font-size: 0.15rem;
        color: #fff;
        position: relative;
        height: .31rem;
        border-radius: .2rem;
        font-family: Source Han Sans, Source Han Sans;
        font-weight: 700;
        font-size: .15rem;
        color: #fff;
        transition: all 0.2s;

        &.active {
            background: #000;
            color: #C431FF;
        }

        img {
            width: 0.17rem;
        }
    }
}

.logo {
    height: .25rem;
    position: relative;
    left: 50%;
    transform: translateX(-50%);
    margin-top: .2rem;
    margin-bottom: .3rem;
}
</style>
