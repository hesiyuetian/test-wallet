<template>
    <div class="home main">
        <!-- Banner -->
        <img class="banner" src="~images/nft/401.jpg" alt="">

        <div class="title">
            <img class="label" src="~images/nft/402.png" alt="">
            <div @click="open(blockChain.link.tg)">
                访问频道了解更多
            </div>
        </div>

        <div class="item">
            <img class="label" src="~images/nft/410.png" alt="">
            <img class="nfts first" src="~images/nft/411.png" alt="">
        </div>
        <div class="item">
            <img class="label" src="~images/nft/420.png" alt="">
            <img class="nfts common" src="~images/nft/421.png" alt="">
        </div>
        <div class="item">
            <img class="label" src="~images/nft/430.png" alt="">
            <img class="nfts common" src="~images/nft/431.png" alt="">
        </div>
        <div class="item">
            <img class="label" src="~images/nft/440.png" alt="">
            <img class="nfts common" src="~images/nft/441.png" alt="">
        </div>
        <div class="item">
            <img class="label" src="~images/nft/450.png" alt="">
            <img class="nfts common" src="~images/nft/451.png" alt="">
        </div>

        <div class="more" @click="open(blockChain.link.tg)">
            访问频道了解更多
        </div>
    </div>
</template>

<script setup lang="ts">
import { useBlockChain } from '@/store/chain';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const blockChain = useBlockChain();

const open = (href: string) => {
    if (!href) return;
    window.open(href);
};
</script>


<style scoped lang="scss">
.home {
    width: 100%;
    position: relative;
    z-index: 10;
    min-height: 100vh;
    color: #fff;
    background: #000;

    /* ====== Banner ====== */
    .banner {
        width: calc(100% + 0.34rem);
        margin-left: -0.17rem;
        display: block;
    }

    .title {
        display: flex;
        align-items: center;
        justify-content: space-between;

        margin: .25rem 0 .4rem;

        .label {
            height: .57rem;
        }

        div {
            width: 1.5rem;
            height: .4rem;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 500;
            font-size: .15rem;
            color: #000000;
            cursor: pointer;
            background: url('../../assets/images/nft/403.png') no-repeat center center;
            background-size: 100% 100%;
        }
    }

    .item {
        margin-bottom: .22rem;

        .label {
            height: .4rem;
            display: block;
            margin-bottom: .12rem;
        }

        .nfts {

            &.first {
                height: 1.53rem;
            }

            &.common {
                width: 100%;

            }
        }
    }

    .more {
        width: 1.5rem;
        height: .4rem;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 500;
        font-size: .15rem;
        color: #000000;
        background: url('../../assets/images/nft/403.png') no-repeat center center;
        background-size: 100% 100%;
        position: relative;
        left: 50%;
        transform: translateX(-50%);
        cursor: pointer;
    }

}
</style>
