<template>
    <div class="layout">
        <!-- <template v-if="!dialogVisible"> -->
        <router-view v-slot="{ Component, route }">
            <transition :name="transitionName" mode="out-in" appear>
                <component :is="Component" :key="route.path" />
            </transition>
        </router-view>
        <Footer />
        <!-- </template> -->
        <!-- <div class="bind-invite" v-else>
            <img src="~images/006.png" alt="">
            <h5>绑定上级地址</h5>
            <textarea rows="3" v-model="inviterInput" :placeholder="t('base.bindInviterInput')" />
            <el-button :loading="state.bindLoading" @click="bindInviter">{{ t('base.bindInviterConfirm')
            }}</el-button>
        </div> -->

        <el-dialog v-model="dialogVisible" :close-on-click-modal="false" :close-on-press-escape="false"
            :show-close="false" :title="t('base.bindInviter')" class="black-dialog" width="300px">
            <textarea rows="3" v-model="inviterInput" :placeholder="t('base.bindInviterInput')" />
            <template #footer>
                <el-button :loading="state.bindLoading" @click="bindInviter">{{ t('base.bindInviterConfirm')
                    }}</el-button>
            </template>
        </el-dialog>
    </div>
</template>

<script setup lang="ts">
import Footer from '../footer/index.vue';
import { onMounted, reactive, watch, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useBlockChain } from '@/store/chain';
import { ElMessage } from 'element-plus';
import router from '@/routes';

const { t } = useI18n();
const blockChain = useBlockChain();

// ==================== 转场动画配置 ====================
// 可选值: 'page-fade' | 'page-slide' | 'page-scale' | 'page-blur' | 'page-flip'
const transitionName = ref(blockChain.transitionName);
// ====================================================

const dialogVisible = ref(false);
const inviterInput = ref('');
const state = reactive({
    bindLoading: false,
    userInfoInviter: '',
    firstAddr: '',
});

watch(
    () => blockChain.chainId,
    () => {
        init();
    }
);
watch(
    () => blockChain.account,
    () => {
        init();
    }
);

const bindInviter = async () => {
    try {
        if (inviterInput.value.length !== 42) throw new Error(t('base.bindInviterInputCorrect'));
        state.bindLoading = true;
        const contract = blockChain.getMineContract();
        if (inviterInput.value.toLowerCase() !== state.firstAddr.toLowerCase()) {
            const isValidInviter = await contract.isValidInviter(inviterInput.value);
            if (!isValidInviter) throw new Error(t('base.bindInviterInvalid'));
            // if (inviterInput.value.toLowerCase() === blockChain.account.toLowerCase()) throw new Error(t('base.bindInviterInvalid'));
        }
        console.log('inviterInput.value::::', inviterInput.value);
        const override = {
            // value: $BigNumber(state.fee).shiftedBy(18).toFixed(),
            // gasLimit: 300000,
            // gasPrice: Number(gasPrice) + 1,
        };
        const transferTx = await contract.bind(inviterInput.value, override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({
                showClose: true,
                message: t('base.bindInviterSuccess'),
                type: 'success',
                duration: 2500,
            });
            dialogVisible.value = false;
            blockChain.setStartInit(true);
            getBaseInfo();
        } else {
            ElMessage({
                showClose: true,
                message: t('base.bindInviterFail'),
                type: 'error',
                duration: 2500,
            });
        }
    } catch (e: any) {
        ElMessage({
            showClose: true,
            message: e?.reason ?? e?.message ?? 'Error',
            type: 'error',
            duration: 2500,
        });
    } finally {
        state.bindLoading = false;
    }
};

const getBaseInfo = async () => {
    try {
        const contract = blockChain.getMineContract();
        const userInfo = await contract.userInfo(blockChain.account);
        const firstAddr = await contract.firstAddr();
        state.firstAddr = firstAddr;
        if (blockChain.account.toLowerCase() === state.firstAddr.toLowerCase()) {
            state.userInfoInviter = state.firstAddr.toLowerCase();
            blockChain.setStartInit(true);
        } else if (userInfo.inviter === '0x0000000000000000000000000000000000000000') {
            dialogVisible.value = true;
        } else {
            state.userInfoInviter = userInfo.inviter;
            blockChain.setStartInit(true);
        }
        console.log('firstAddr::::', firstAddr);
    } catch (e: any) { }
};

const init = async () => {
    if (blockChain.account && blockChain.chainId) {
        if (![97, 56].includes(Number(blockChain.chainId))) {
            ElMessage.error({
                message: t('change network'),
                duration: 7000,
            });
            return;
        }
        const inviter = blockChain.inviter || '';
        inviterInput.value = inviter === blockChain.account ? '' : inviter;
        // if (!router.currentRoute.value.path.includes('/admin')) {
        getBaseInfo();
        // }
    }
};
onMounted(() => {
    init();
});
</script>

<style lang="scss">
.layout {
    // background: url('../../assets/images/bg.png') no-repeat center center;
    // background-size: 110% 110%;
    min-height: 100%;
    position: relative;
    min-height: 100vh;

    .main {
        padding: 0.65rem 0.17rem 0;
        // min-height: 100vh;
    }

    .bind-invite {
        margin-top: 2rem;
        padding-inline: .13rem;
        color: #fff;
        background: linear-gradient(222deg, #5E3F7C 0%, #3627AC 100%);
        border-radius: .25rem;
        width: calc(100% - .26rem);
        margin-left: .13rem;
        padding-inline: .15rem;
        padding-bottom: .6rem;

        img {
            width: 100%;
            // position: relative;
            margin-top: -1rem;
        }

        h5 {
            margin: .6rem 0 .22rem;
            font-family: Source Han Sans, Source Han Sans;
            font-weight: 400;
            font-size: .2rem;
            color: #FFFFFF;
            line-height: 1.5;
            text-align: center;
        }

        textarea {
            padding: 0.05rem 0.1rem;
            width: 100%;
            font-size: 0.13rem;
            color: #000000;
            background: #D3B2E4;
            // min-height: 0.4rem;
            border-radius: 0.08rem;
            border-color: #D3B2E4;

            &::placeholder {
                color: #3e3d3d;
            }

            &:focus {
                outline: none;
            }
        }

        button {
            min-width: 1.7rem;
            height: 0.42rem;
            // background: url('../../assets/images/base/052.png') no-repeat center center;
            background-size: 100% 100%;
            border: none;
            font-size: 0.16rem;
            color: #000;
            margin-top: .25rem;
            position: relative;
            left: 50%;
            transform: translateX(-50%);
        }
    }
}



.el-dialog {
    border-radius: 0.1rem;
    // background: linear-gradient(180deg, #D7392B 0%, #E86815 100%);
    background: #000;
    border: 1px solid #00ed6b;

    .el-dialog__header {
        text-align: center;

        button,
        .el-dialog__title {
            color: #fff;
            // color: transparent;
            // -webkit-background-clip: text;
            // -webkit-text-fill-color: transparent;
            // background-image: linear-gradient(40.863615476748684deg, #fcf6b2 0%, #da9e41 22%, #e8c576 38%, #d8a64d 50%, #f5e380 66%, #dac164 72%, #fcf6b2 100%);
        }
    }
}

.el-dialog__body {
    padding-top: 14px;
    padding-bottom: 14px;

    textarea {
        padding: 0.05rem 0.1rem;
        width: 100%;
        font-size: 0.13rem;
        color: #442e12;
        background: #fff;
        // min-height: 0.4rem;
        border-radius: 0.08rem;
        border-color: #000;

        &:focus {
            outline: none;
        }
    }

    .th {
        font-size: 0.12rem;
        color: #ffffff;
        line-height: 1.5;
        text-align: center;
        margin-bottom: 0.07rem;
        display: flex;

        div {
            flex: 0.7;
        }

        div:nth-child(1) {
            flex: 0.7;

            span {
                display: inline-block;
                width: 0.15rem;
            }
        }

        div:nth-child(2) {
            flex: 0.4;
        }
    }

    .tr {
        font-size: 0.11rem;
        color: rgba(255, 255, 255, 0.6);
        margin-bottom: 0.03rem;
    }

    .address {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        flex-direction: row;
        gap: 0.1rem;

        div {
            display: flex;
            align-items: center;
            font-size: 0.13rem;
            gap: 0.08rem;
            color: #000;

            &:nth-child(even) {
                justify-content: end;
            }

            img {
                height: 0.14rem;
                cursor: pointer;
                position: relative;
                top: 0.02rem;
            }
        }
    }
}

.el-dialog__footer {
    display: flex;
    justify-content: center;

    button {
        width: 60%;
        height: 0.4rem;
        // background: linear-gradient(270deg, #328336 0%, #47A74B 100%) !important;
        background: #00ed6b;

        // background: url('../../assets/images/home/023.png') no-repeat center center !important;
        // background-size: 100% 100%;

        font-size: 0.14rem;
        color: #fff !important;
        border-radius: 0.2rem;
        border: none !important;
        padding-left: 0.24rem;
    }
}

.address-dialog {
    .el-dialog__header {
        text-align: center;
    }

    .el-dialog__body {
        padding-inline: 0.1rem;
        padding-top: 4px;
        padding-bottom: 20px;
        min-height: 20vh;
        max-height: 50vh;
        overflow: auto;
    }
}
</style>
