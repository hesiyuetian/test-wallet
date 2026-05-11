<template>
    <main class="container" :class="{ game: route.path === '/game' }">
        <div class="main">
            <Header />
            <section id="main_section">
                <div class="router">
                    <div>
                        <router-view :key="route.path" />
                    </div>
                </div>
                <div class="dialog" v-if="blockChain.show_process">
                    <div class="mask" @click="blockChain.handProcess('close')"></div>
                    <div class="section">
                        <div>处理中</div>
                        <img src="~images/loadding.svg" alt="" />
                        <p>预计剩余处理时间{{ blockChain.process_time }}秒</p>
                    </div>
                </div>
            </section>
        </div>
    </main>
</template>

<script setup lang="ts">
import { ElMessage, ElButton } from 'element-plus';
import { useRoute, useRouter } from 'vue-router';
import { provide, ref, reactive, onMounted, watch } from 'vue';
import { useBlockChain } from '@/store/chain';
import Header from '@/components/navigation/index.vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from '@wagmi/vue';
const { address, isConnected } = useAccount();

const { t } = useI18n();

const route = useRoute();
const router = useRouter();
const blockChain = useBlockChain();

const state = reactive({
    socket: null,
    inviter: null,
    show: true,
});

watch(
    () => blockChain.account,
    () => {
        init();
    }
);
watch(
    () => route.query,
    () => {
        console.log('route', route);
        if (route.query?.id) {
            blockChain.setInviter((route.query?.id ?? '') as any);
        } else {
            const inviter = window.sessionStorage.getItem('inviter');
            inviter && blockChain.setInviter(inviter);
        }
    }
);

// 监听路由变化，滚动到顶部
watch(
    () => route.path,
    () => {
        const mainSection = document.getElementById('main_section');
        if (mainSection) {
            mainSection.scrollTop = 0;
        }
    }
);

const jump = path => {
    router.push(path);
    window.scrollTo(0, 0);
};

const init = async () => {
    if (blockChain.account) {
        try {
            // const params = {
            //     user: blockChain.account,
            //     inviter: blockChain.inviter,
            // };
            // state.inviter = inviter;
            // if (inviter !== '未知') {
            //     blockChain.setInviter(inviter);
            // }
        } catch (e: any) {
            ElMessage({
                showClose: true,
                message: e.message,
                type: 'error',
                duration: 5000,
            });
        }
    }
};

onMounted(() => {
    // blockChain.init_blockChain();
    // blockChain.connectWallet();

    // if (window.ethereum) {
    //     window.ethereum.on('accountsChanged', async function (accounts) {
    //         await blockChain.connectWallet();
    //     });
    //     //当所连接网络ID变化时触发
    //     window.ethereum.on('chainChanged', networkIDstring => {
    //         console.log('链切换', networkIDstring);
    //         window.location.reload();
    //     });
    // }

    setTimeout(() => {
        if (!isConnected.value) {
            blockChain.connectWallet();
        }
        blockChain.init_blockChain();
        console.log('onMounted:::', address.value, isConnected.value);
    }, 1000);
});
</script>

<style scoped lang="scss">
.container {
    width: 100%;
    max-width: 450px;
    height: 100vh;
    max-height: 100vh;
    overflow: hidden;
    margin: 0 auto;
    position: relative;
    color: #fff;
    /* &::after {
        content: '';
        position: absolute;
        bottom: 0;
        left: 50%;
        width: 100%;
        height: 100%;
        transform: translateX(-50%);
        background: url('images/bg.png') no-repeat;
        background-size: 100% 100%;
    } */

    .main {
        width: 100%;
        height: 100vh;
        max-height: 100vh;
        margin: 0 auto;
        position: relative;
        z-index: 3;
        overflow-x: hidden;
        overflow-y: auto;

        /* @media screen and (max-width: 450px) {
            &::after {
                content: '';
                position: absolute;
                bottom: 0;
                left: 50%;
                width: 9.23rem;
                height: 5.19rem;
                transform: translateX(-50%);
                background-size: 100% 100%;
                z-index: -1;
            }
        } */
        section {
            /* margin-top: 0.15rem; */
        }

        .router {
            height: 100%;

            &>div {
                height: 100%;
            }

            @media screen and (min-width: 450px) {
                background: none;
            }
        }

        footer {
            position: fixed;
            bottom: 0;
            height: 0.64rem;
            left: 50%;
            transform: translateX(-50%);
            z-index: 99;
            width: 100%;
            max-width: 450px;
            padding: 0 0.2rem;

            .cont {
                display: flex;
                height: 100%;
                justify-content: center;
            }

            .navs {
                width: 0.44rem;
                height: 100%;
                display: flex;
                justify-content: center;
                cursor: pointer;
                transition: all 0.2s;
                padding-top: 0.12rem;
                margin-right: 0.5rem;
                transition: all 0.2s;

                img {
                    height: 0.2rem;
                    width: 0.2rem;
                }

                &:last-child {
                    margin-right: 0;
                }

                &.active {
                    border-radius: 0.22rem 0.22rem 0 0;
                    background: #254ae5;
                    position: relative;

                    &::after {
                        content: '';
                        width: 0.04rem;
                        height: 0.04rem;
                        background: #fff;
                        border-radius: 50%;
                        position: absolute;
                        top: 0.4rem;
                        left: 50%;
                        transform: translateX(-50%);
                    }
                }
            }
        }

        .dialog {
            width: 100%;
            position: fixed;
            top: 0;
            left: 0;
            height: 100%;
            z-index: 999;
            width: 100%;

            .mask {
                width: 100%;
                position: absolute;
                top: 0;
                left: 0;
                height: 100%;
                background: rgba(0, 0, 0, 0.6);
            }

            .section {
                position: absolute;
                z-index: 999;
                width: calc(100% - 0.4rem);
                max-width: calc(450px - 0.4rem);
                top: 50%;
                left: 50%;
                transform: translate(-50%, -70%);
                border-radius: 0.24rem;
                background: #fff;
                padding: 0.4rem 0.24rem;
                text-align: center;
                color: #000;
                font-family: Source Han Sans CN;

                div {
                    font-size: 0.18rem;
                    font-weight: 500;
                    line-height: 0.27rem;
                    margin-bottom: 0.27rem;
                }

                svg,
                img {
                    width: 0.4rem;
                    height: 0.4rem;
                    /* margin: 0.27rem 0; */
                    animation: rotate 1s linear infinite;
                }

                p {
                    margin-top: 0.27rem;
                    font-size: 16px;
                    line-height: 0.24rem;
                }
            }
        }
    }
}
</style>
