<template>
    <header>
        <div class="header flex_between">
            <div class="left">
                <!-- <img class="menu" @click="openDialog(!state.open)" src="~images/base/menu.png" /> -->
                <!-- <img class="logo" src="~images/base/logo.png" /> -->
                <!-- <span>馬上暴富</span> -->
                <img class="logo-font" src="~images/base/logo-font.png" />
            </div>
            <div class="right">
                <!-- <img src="~images/tg.png" alt="" @click="jump(blockChain.link.tg)" class="link" />
                <img src="~images/x.png" alt="" @click="jump(blockChain.link.tw)" class="link" /> -->
                <!-- <el-popover popper-class="menu-popover" trigger="click" v-model:visible="state.lang_visible">
                    <template #reference>
                        <img class="menu" src="~images/base/lang.png" alt="" />
                    </template>
<div class="menu-list">
    <div v-for="(item, index) in state.langList" :key="index" class="item" @click="setLang(item)">
        {{ item.title }}
    </div>
</div>
</el-popover> -->
                <div class="wallet" @click="connectWallet()">
                    <!-- <img src="~images/base/wallet.png" alt="" /> -->
                    {{ blockChain.account ? $hash(blockChain.account, 8, 4) : t('connect wallet') }}
                </div>

                <!-- <el-popover popper-class="menu-popover" trigger="click" v-model:visible="state.menu_visible">
                    <template #reference>
                        <img class="menu" src="~images/base/menu.png" alt="" />
                    </template>
                    <div class="menu-list">
                        <div v-for="(item, index) in state.menu_list" :key="index" class="item" @click="jump(item.path)">
                            {{ t(`nav.${item.name}`) }}
                        </div>
                    </div>
                </el-popover> -->
                <img class="lang_icon" @click="openDialog(!state.open)" src="~images/base/menu.png" alt="" />
            </div>
        </div>
    </header>
    <div class="dialog_menu" v-if="state.open">
        <div class="mask" @click="openDialog(false)"></div>
        <div class="main">
            <div class="header">
                <!-- <span>Light</span> -->
                <img class="logo" @click="openDialog(false)" src="~images/base/close.png" alt="" />
            </div>
            <!-- <img class="close" @click="openDialog(false)" src="~images/base/close.png" alt="" /> -->

            <div class="nav">
                <div class="lib" v-for="(item, index) of state.menu_list" :key="index" @click="jump(item.path)">
                    <!-- <img class="icon" src="~images/base/logo.png" alt="" /> -->
                    <!-- <span>{{ t(`base.${item.name}`) }}</span> -->
                    <!-- <span>{{ t(`nav.${item.name}`) }}</span> -->
                    <span>{{ item.name }}</span>
                    <!-- <img class="icon_right" src="~images/base/rigth.png" alt="" /> -->
                </div>
            </div>

            <!-- <div class="link">
                <a :href="blockChain.link.tw" target="_blank"><img src="~images/tw.png" alt="" /></a>
                <a :href="blockChain.link.tg" target="_blank"><img src="~images/tg.png" alt="" /></a>
            </div> -->
        </div>
    </div>
</template>

<script setup lang="ts">
import { getCurrentInstance, reactive, ref, watch } from 'vue';
import { storeToRefs } from 'pinia';
import { useBlockChain } from '@/store/chain';
import { $hash } from '@/utils/met';
import { ElMessage } from 'element-plus';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import zh from '../../assets/images/base/zh.png';
import en from '../../assets/images/base/en.png';
import { useAccount, useChainId, useDisconnect } from '@wagmi/vue';
import { appKit } from '@/config/appkit';
const route = useRoute();

const { t, locale } = useI18n();
const { proxy } = getCurrentInstance();
const router = useRouter();
const blockChain = useBlockChain();
const { account } = storeToRefs(blockChain);


// 使用 AppKit 的 composables
const { address, isConnected } = useAccount();
const chainId = useChainId();
const { disconnect } = useDisconnect();
const cacheChainId = ref(0);
const cacheAddress = ref('');


let state = reactive({
    open: false,
    openLang: false,
    menu_visible: false,
    lang_visible: false,
    langList: [
        { title: 'English', value: 'en', icon: en },
        // { title: '日本語', value: 'ja', icon: zh },
        { title: '中文', value: 'zh', icon: zh },
        // { title: '한국어', value: 'ko', icon: zh },
        // { title: 'ไทย', value: 'th', icon: zh },
        // { title: 'Singapore', value: 'sg', icon: zh },
        // { title: 'Malaysia', value: 'my', icon: zh },
    ],
    menu_list: [
        { name: '铸造心币', icon: 'home', path: '/' },
        { name: '铸造NFT', icon: 'home', path: '/mint-nft' },
        { name: '心币节点', icon: 'home', path: '/node' },
        { name: 'NFT介绍', icon: 'home', path: '/nft' },
        { name: '心币官网', icon: 'home', path: '' },
        { name: '电报社区', icon: 'oni', path: blockChain.link.tg },
        { name: '官方推特', icon: 'recommend', path: blockChain.link.x },
    ],
});
// const setLange = () => {
//     proxy.$i18n.locale = proxy.$i18n.locale === 'zh' ? 'en' : 'zh';
//     blockChain.setLange(proxy.$i18n.locale);
// };

// 监听 AppKit 状态变化并同步到 store


const setLang = item => {
    state.openLang = false;
    state.lang_visible = false;
    proxy.$i18n.locale = item.value;
    blockChain.setLange(proxy.$i18n.locale);
};

const openDialog = flag => {
    state.open = flag;
};
const connectWallet = async () => {
    if (!account) {
        try {
            await blockChain.connectWallet();
        } catch (e: any) {
            ElMessage.error(e?.message ?? 'error');
        }
    } else {
        // await blockChain.disconnect();
    }
};
const jump = path => {
    if (path.indexOf('https:') !== -1) {
        window.open(path);
    } else if (path) {
        router.push(path);
    } else {
        ElMessage.warning({
            showClose: true,
            message: 'Coming Soon',
            type: 'warn',
            duration: 2500,
        });
    }
    state.menu_visible = false;
    state.open = false;
};

const watchStatus = async () => {
    if (cacheAddress.value && cacheChainId.value) {
        // blockChain.account = cacheAddress.value;
        // blockChain.chainId = cacheChainId.value;
        blockChain.init_blockChain();
        blockChain.syncAppKitState();

        if (blockChain.signer) {
            // await blockChain.signer.signMessage(`Auth Buurn at:${Date.now()}`);
            blockChain.account = cacheAddress.value;
            blockChain.chainId = cacheChainId.value;
            // blockChain.account = '0x9Ee20a74588A1D89e028a2be4CCF842ac9352111';
            // blockChain.account = '0xec3CfED9CA0CD7BD9D280f0e804431B82C64e222';
            // blockChain.account = '0x27A9627F6757958Df512Fa03Dd7cf66E5f9a8333';

        }
    }
};

const disconnectWallet = async () => {
    try {
        // 先关闭 AppKit 模态框
        appKit.close();

        // 等待一下确保模态框关闭
        await new Promise(resolve => setTimeout(resolve, 100));

        // 然后断开连接
        await disconnect();

        // 清除本地状态
        await blockChain.disconnect();

        // 再次确保模态框关闭
        appKit.close();

        ElMessage.success('钱包已断开连接');
    } catch (e: any) {
        console.error('断开连接失败:', e);
        // 即使出错也要确保模态框关闭
        appKit.close();
        ElMessage.error(e?.message ?? '断开连接失败');
    }
};

watch(
    () => address.value,
    newAddress => {
        if (newAddress) {
            cacheAddress.value = newAddress.toLowerCase();
            // blockChain.account = newAddress.toLowerCase();
            // blockChain.syncAppKitState();
            watchStatus();
        } else {
            cacheAddress.value = '';
            blockChain.account = '';
        }
    },
    { immediate: true }
);

watch(
    chainId,
    newChainId => {
        if (newChainId) {
            cacheChainId.value = newChainId;
            // blockChain.chainId = newChainId;
            // blockChain.syncAppKitState();
            watchStatus();
        }
    },
    { immediate: true }
);

</script>

<style scoped lang="scss">
header {
    width: 100%;
    padding: 0.1rem 0.13rem;
    background: #000;
    // background: #000;
    /* position: sticky; */
    position: fixed;
    top: 0;
    left: 50%;
    transform: translateX(-50%);
    z-index: 99;
    max-width: 450px;

    // &::after {
    //     content: '';
    //     position: absolute;
    //     bottom: 0;
    //     left: 0.13rem;
    //     width: calc(100% - 0.26rem);
    //     height: 0.01rem;
    //     border-bottom: 1px dashed #D8D8D8;
    // }

    .header {
        width: 100%;
        position: relative;
        display: flex;
        justify-content: space-between;
        align-items: center;
        height: 0.4rem;
        // background: linear-gradient(360deg, #1e2433 0%, #282e43 100%);
        // border: 2px solid #4e5772;
        // padding-inline: 0.13rem;
        // border-radius: 0.3rem;

        .left {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 0.04rem;

            .logo {
                height: 0.32rem;
            }

            span {
                font-weight: 900;
                font-size: 0.19rem;
                line-height: 0.24rem;
                background: linear-gradient(90deg, #FFCE00 0%, #FF9E00 100%);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
            }

            .menu {
                height: 0.26rem;
                cursor: pointer;
                margin-right: 0.05rem;
            }

            .logo-font {
                height: 0.34rem;
                // margin-left: 0.06rem;
            }
        }

        .right {
            display: flex;
            align-items: center;
            gap: 0.12rem;

            /* .lang {
                height: 0.3rem;
                margin-right: 0.15rem;
            } */
            .link {
                width: 0.3rem;
                cursor: pointer;
            }

            .lang {
                /* margin-right: 0.13rem; */
                cursor: pointer;
                position: relative;
                display: flex;
                align-items: center;

                .icon {
                    width: 0.23rem;
                }

                .lang_dialog {
                    position: absolute;
                    top: calc(100% + 3px);
                    left: 50%;
                    transform: translateX(-50%);
                    background: #2b2b2b;
                    border-radius: 0.1rem;
                    transition: all 0.2s;
                    /* transform: scale(0);
                    transform-origin: center top; */
                    height: 0;
                    opacity: 0;
                    overflow: hidden;
                    transition: opacity 267ms cubic-bezier(0.4, 0, 0.2, 1) 0ms, transform 178ms cubic-bezier(0.4, 0, 0.2, 1) 0ms;

                    div {
                        font-size: 0.13rem;
                        height: 0.24rem;
                        padding: 0 0.1rem 0.1rem;

                        box-sizing: content-box;
                        display: flex;
                        align-items: center;
                        border-bottom: 1px solid rgba(0, 0, 0, 0.45);
                        text-indent: 0.03rem;
                        margin-bottom: 0.06rem;
                        color: #fff;
                        white-space: nowrap;

                        img {
                            width: 0.17rem;
                            margin-right: 0.04rem;
                        }

                        &:last-child {
                            border-bottom: none;
                            margin-bottom: 0;
                            padding-bottom: 0.02rem;
                        }

                        &.active {
                            color: #40d07e;
                        }

                        &:last-child {
                            margin-bottom: 0;
                        }
                    }
                }

                .show {
                    padding: 0.1rem 0.04rem 0.1rem;
                    height: auto;
                    /* transform: scale(1); */
                    opacity: 1;
                }
            }

            .menu {
                height: 0.3rem;
            }

            .lang_icon {
                height: 0.31rem;
            }

            .wallet {
                min-width: 1.4rem;
                padding-inline: 0.14rem;
                // padding-left: .35rem;
                height: 0.34rem;
                display: flex;
                align-items: center;
                justify-content: center;
                position: relative;
                // background: #1fc7d4;
                // background: linear-gradient(270deg, #662dfa 0%, #b05ae2 100%);
                // border: 1px solid #ffbb00;
                // background: linear-gradient(180deg, #47A74B 0%, #318335 100%);
                background: url('../../assets/images/base/102.png') no-repeat center center;
                background-size: 100% 100%;
                font-weight: 900;
                font-size: 0.14rem;
                color: #FFF2C9;

                img {
                    height: 0.22rem;
                    position: absolute;
                    left: 0.05rem;
                    top: 50%;
                    transform: translateY(-50%);
                }
            }
        }
    }
}

.dialog_menu {
    position: fixed;
    width: 100%;
    /* height: calc(100vh - 0.54rem);
    min-height: calc(100vh - 0.54rem); */
    height: 100vh;
    bottom: 0;
    left: 0;
    z-index: 9999;

    .mask {
        position: absolute;
        width: 100%;
        height: 100%;
        background: rgba(0, 0, 0, 0.36);
    }

    .main {
        position: absolute;
        height: 100%;
        right: 0;
        top: 0;
        // background: linear-gradient(132deg, #3D1C63 0%, #66438D 100%);
        background: linear-gradient(90deg, #0A3429 0%, #000000 100%);
        border-radius: 0px 0px 0px 0px;
        padding: 0.2rem 0.14rem 0;
        z-index: 3;
        width: 1.9rem;

        .header {
            display: flex;
            align-items: center;
            justify-content: flex-end;
            margin-bottom: 0.31rem;

            span {
                font-weight: 700;
                font-size: 0.21rem;
                color: #fff;
            }

            .logo {
                width: 0.3rem;
            }

            .close {
                // margin-left: 0.11rem;
                width: 0.33rem;
                cursor: pointer;
            }
        }

        .close {
            position: absolute;
            top: 0.25rem;
            right: 0.16rem;
            cursor: pointer;
            height: 0.3rem;
        }

        .nav {
            width: 100%;
            margin-top: 0.4rem;
            padding-inline: 0.1rem;

            .lib {
                width: 100%;
                height: 0.35rem;
                font-size: 0.14rem;
                color: #000;
                margin-bottom: 0.15rem;
                background: url('../../assets/images/base/102.png') no-repeat center center;
                background-size: 100% 100%;
                cursor: pointer;
                display: flex;
                align-items: center;
                justify-content: center;
                position: relative;
                font-weight: 600;
                padding-inline: 0.06rem;


                .icon {
                    width: 0.22rem;
                    margin-right: 0.1rem;
                }

                .icon_right {
                    height: 0.19rem;
                    position: absolute;
                    right: 0;
                    top: 50%;
                    transform: translateY(-50%);
                }

                span {
                    background: linear-gradient(76.22708624543837deg, #FCF6B2 0%, #DA9E41 22%, #E8C576 38%, #D8A64D 50%, #F5E380 66%, #DAC164 72%, #FCF6B2 100%);
                    -webkit-background-clip: text;
                    background-clip: text;
                    -webkit-text-fill-color: transparent;
                    text-fill-color: transparent;
                    // display: inline-block;
                    // flex: 1;
                    // text-align: right;
                }
            }
        }

        .link {
            width: 100%;
            height: 0.7rem;
            margin-top: 0.3rem;
            // position: absolute;
            // bottom: 0.47rem;
            // left: 0;
            display: flex;
            align-items: center;
            justify-content: center;

            a {
                margin-right: 0.2rem;

                &:last-child {
                    margin: 0;
                }
            }

            img {
                height: 0.25rem;
            }
        }
    }
}
</style>

<style lang="scss"></style>
