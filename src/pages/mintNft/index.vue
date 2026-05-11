<template>
    <div class="home main">
        <!-- Banner -->
        <img class="banner" src="~images/mint-nft/201.jpg" alt="">

        <div class="stake">
            <img class="title" src="~images/mint-nft/202.png" alt="">
            <div class="card">
                <div class="top">
                    铸造NFT
                    <span>余额：{{ state.tokenBalance }} 心币</span>
                </div>
                <div class="input">
                    <div class="label">铸造数量</div>
                    <div class="cont">
                        <input type="text" v-model="state.amount" @keyup="handleAmountChange" placeholder="0">
                        <span>张</span>
                    </div>
                    <img class="plus" @click="handleChange('sub')" src="~images/mint-nft/205.png" alt="">
                    <img class="plus" @click="handleChange('plus')" src="~images/home/114.png" alt="">
                </div>
                <div class="desc">
                    <div class="left">
                        <img src="~images/mint-nft/208.png" alt="">
                        铸造所需心币
                    </div>
                    <div class="right">
                        <span>{{ costToken }}</span>
                        枚
                    </div>
                </div>
                <el-button class="stake-btn" v-if="needApprove" :loading="state.approveLoading" @click="approve()">
                    授权
                </el-button>
                <el-button class="stake-btn" v-else :loading="state.stakeLoading" :disabled="stakeDisabled"
                    @click="stake()">
                    铸造NFT
                </el-button>
                <p>*使用心币铸造一张随机NFT，自动进入钱包地址</p>
            </div>
        </div>

        <div class="info">
            <div class="item">
                <h5>拥有NFT数量 <span>张</span></h5>
                <p>{{ state.nftBalance }}</p>
            </div>
            <div class="item">
                <h5>铸造NFT数量 <span>张</span></h5>
                <p>{{ state.mintNftNums }}</p>
            </div>
        </div>

        <div class="list">
            <h5>铸造记录</h5>
            <div class="th td">
                <div>序号</div>
                <div>时间</div>
                <div>铸造数量</div>
            </div>
            <div class="td" v-for="(item, index) in state.list" :key="index">
                <div>{{ (Number(index) + 1).toString().padStart(3, '0') }}</div>
                <div>{{ dayjs(item.time).format('YYYY/MM/DD HH:mm') }}</div>
                <div>{{ item.amount }}</div>
            </div>
            <el-empty v-if="state.list.length === 0" description="暂无数据" />
        </div>

    </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, watch, onBeforeUnmount, computed, ref } from 'vue';
import { dayjs, ElMessage } from 'element-plus';
import { useBlockChain } from '@/store/chain';
import { useI18n } from 'vue-i18n';
import { $BigNumber, $shiftedByFixed, $hash, $copy, $onlyNumber, $debounce, $shiftedByString } from '@/utils/met';

const { t } = useI18n();
const blockChain = useBlockChain();

const timer = ref(null);
const state = reactive({
    amount: 1 as any,
    tokenBalance: '--' as any,
    bnbBalance: '--' as any,
    nftBalance: '--' as any,
    mintNftNums: '--' as any,
    equalTokenPerNFT: 0 as any,
    allowance: 0 as any,
    approveLoading: false,
    stakeLoading: false,
    list: [] as any,
});

watch(() => blockChain.chainId, () => { init(); });
watch(() => blockChain.account, () => { init(); });
watch(() => blockChain.startInit, () => { init(); });



const costToken = computed(() => {
    if (!state.amount || state.equalTokenPerNFT === '--') return '--';
    return Number($BigNumber(state.amount).multipliedBy(state.equalTokenPerNFT).toFixed(2));
})

const needApprove = computed(() => {
    if (!costToken.value || costToken.value === '--') return false;
    return $BigNumber(costToken.value).multipliedBy(2).gt(state.allowance);
});

const stakeDisabled = computed(() => {
    return state.mintNftNums === '--';
})

const handleAmountChange = () => {
    state.amount = $onlyNumber(state.amount);
};
const handleChange = (type: 'plus' | 'sub') => {
    if (type === 'plus') {
        state.amount = Number(state.amount || 0) + 1;
    } else {
        state.amount = Math.max(Number(state.amount || 0) - 1, 1);
    }
};

const getBalance = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            tokenContract = blockChain.contract_address[blockChain.chainId].tokenContract;
        const bnbBalance = await blockChain.getBalance('0x0000000000000000000000000000000000000000');
        const calls = [
            {
                target: tokenContract,
                callData: blockChain.getTargetTokenContract(tokenContract).interface.encodeFunctionData('balanceOf', [blockChain.account]),
            },
        ];
        const [, returnData] = await multicallContract.callStatic.aggregate(calls);
        const tokenBalance = blockChain.getTargetTokenContract(tokenContract).interface.decodeFunctionResult('balanceOf', returnData[0]);
        state.bnbBalance = $shiftedByFixed(bnbBalance.toString(), -18, 6);
        state.tokenBalance = $shiftedByFixed(tokenBalance.toString(), -18, 4);
        // state.tokenBalance = 50;
    } catch (e: any) { }
};

const getAllowance = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            tokenContract = blockChain.contract_address[blockChain.chainId].tokenContract,
            mineContract = blockChain.contract_address[blockChain.chainId].mineContract;
        const calls = [
            {
                target: tokenContract,
                callData: blockChain.getTargetTokenContract(tokenContract).interface.encodeFunctionData('allowance', [blockChain.account, mineContract]),
            },
        ];
        const [, returnData] = await multicallContract.callStatic.aggregate(calls);
        const allowance = blockChain.getTargetTokenContract(tokenContract).interface.decodeFunctionResult('allowance', returnData[0]);
        state.allowance = $shiftedByFixed(allowance.toString(), -18, 4);
        console.log('allowance::', state.allowance);
    } catch (e: any) {
        console.error('getAllowance error::', e);
    }
};

const approve = async () => {
    try {
        state.approveLoading = true;
        const contract = blockChain.contract_address[blockChain.chainId].tokenContract;
        const result = await blockChain.approve(
            blockChain.contract_address[blockChain.chainId].mineContract, //
            contract, $BigNumber(costToken.value).multipliedBy(2).shiftedBy(18).toFixed()
        ); //
        if (result) {
            ElMessage({ showClose: true, message: t('base.Approve SucceccFuly'), type: 'success', duration: 2500 });
            getAllowance();
            getBalance();
        } else {
            throw new Error(t('base.Approve Fail'));
        }
    } catch (e: any) {
        ElMessage({ showClose: true, message: e?.reason ?? e?.message ?? 'Error', type: 'error', duration: 2500 });
    } finally {
        state.approveLoading = false;
    }
};

const stake = async () => {
    try {
        if (state.equalTokenPerNFT === '--') throw new Error(t('base.load data'));
        if ($BigNumber(costToken.value).gt(state.tokenBalance)) throw new Error('余额不足');
        state.stakeLoading = true;
        const override = {
            // value: $BigNumber(state.fee).shiftedBy(18).toFixed(),
            gasLimit: 1000000,
            // gasPrice: Number(gasPrice) + 1,
        };
        const mineContract = blockChain.getMineContract();
        const transferTx = await mineContract.mintNFT(Number(state.amount), override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({ showClose: true, message: '质押成功', type: 'success', duration: 2500 });
            getBalance();
            getAllowance();
            getBaseInfo();
            state.amount = 1;
        } else {
            throw new Error('质押失败');
        }
    } catch (e: any) {
        ElMessage({ showClose: true, message: e?.reason ?? e?.message ?? 'Error', type: 'error', duration: 2500 });
    } finally {
        state.stakeLoading = false;
    }
};

const getBaseInfo = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            mineAddress = blockChain.contract_address[blockChain.chainId].mineContract,
            mineContract = blockChain.getMineContract();
        const calls = [
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('userInfo', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('getUserNftBalance', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('getUserNftRecords', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('equalTokenPerNFT', []) },
        ];
        const [, returnData] = await multicallContract.callStatic.aggregate(calls);
        const userInfo = mineContract.interface.decodeFunctionResult('userInfo', returnData[0]);
        const nftBalance = mineContract.interface.decodeFunctionResult('getUserNftBalance', returnData[1])[0];
        const userNftRecords = mineContract.interface.decodeFunctionResult('getUserNftRecords', returnData[2])[0];
        const equalTokenPerNFT = mineContract.interface.decodeFunctionResult('equalTokenPerNFT', returnData[3])[0];
        state.nftBalance = Number(nftBalance.toString());
        state.equalTokenPerNFT = $shiftedByString(equalTokenPerNFT.toString(), -18, 6);

        state.list = userNftRecords.filter(ele => Number(ele.time.toString()) !== 0).map(ele => ({
            amount: Number(ele.amount.toString()),
            time: Number(ele.time.toString()) * 1000,
        }));
        state.mintNftNums = Number(userInfo.mintNftNums.toString())
    } catch (e: any) { }
};


const init = async () => {
    if (blockChain.account && blockChain.chainId && blockChain.startInit) {
        if (![97, 56].includes(Number(blockChain.chainId))) {
            ElMessage.error({ message: t('change network'), duration: 7000 });
            return;
        }
        await getBalance();
        await getAllowance();
        getBaseInfo();
    }
};

onMounted(() => { init(); });
onBeforeUnmount(() => { clearInterval(timer.value); });
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

    .stake {
        margin-top: .2rem;

        .title {
            height: .57rem;
        }

        .card {
            background: url('../../assets/images/home/111.png') no-repeat center center;
            background-size: 100% 100%;
            padding: .25rem .22rem .16rem;
            margin-top: .02rem;

            .top {
                display: flex;
                justify-content: space-between;
                align-items: center;
                font-weight: 500;
                font-size: .13rem;
                color: #FFFFFF;

                span {
                    font-size: .11rem;
                }
            }

            .input {
                margin-top: .06rem;
                position: relative;
                height: .42rem;
                display: flex;
                align-items: center;
                gap: .12rem;

                .label {
                    font-weight: 500;
                    font-size: .15rem;
                    color: #FFFFFF;
                    width: 200px;
                }

                .cont {
                    width: 100%;
                    height: 100%;
                    background: #F1FFD5;
                    border-radius: .05rem;
                    position: relative;

                    span {
                        position: absolute;
                        right: .08rem;
                        top: 50%;
                        transform: translateY(-50%);
                        font-weight: 500;
                        font-size: .18rem;
                        color: #000000;
                    }

                    input {
                        width: 100%;
                        height: 100%;
                        border: none !important;
                        outline: none !important;
                        padding: 0 .35rem;
                        font-size: .17rem;
                        font-size: 600;
                        color: #000000;
                        background: transparent;
                        text-align: right;
                    }
                }

                .plus {
                    height: .42rem;
                    width: .42rem;
                    cursor: pointer;
                }

            }

            .desc {
                margin: .13rem 0 .16rem;
                display: flex;
                align-items: center;
                justify-content: space-between;
                height: .35rem;
                background: #B9B9B9;
                border-radius: .05rem;
                padding-inline: .1rem;
                font-weight: 500;
                font-size: .11rem;
                color: #4D4D4D;

                .left {
                    display: flex;
                    align-items: center;
                    gap: .04rem;

                    img {
                        height: .25rem;
                    }
                }

                .right {
                    display: inline-flex;
                    align-items: center;
                    gap: .06rem;

                    span {
                        font-size: .18rem;
                    }
                }
            }


            .stake-btn {
                width: 100%;
                height: .35rem;
                font-weight: 500;
                font-size: .18rem;
                color: #000000;
                background: linear-gradient(180deg, #00ED6B 0%, #006D1D 100%);
                border-radius: .28rem;
                border: 1px solid #FCF6B2;
            }

            p {
                margin-top: .11rem;
                font-weight: 500;
                font-size: .08rem;
                color: #A2A2A2;
                line-height: .11rem;
                text-align: center;
            }
        }
    }

    .info {
        background: url('../../assets/images/home/120.png') no-repeat center center;
        background-size: 100% 100%;
        margin-top: .14rem;
        padding: .2rem 0.15rem .29rem;
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: .12rem;

        .item {

            h5 {
                display: flex;
                align-items: center;
                justify-content: center;
                gap: .04rem;
                font-weight: 500;
                font-size: .13rem;
                color: #FFCFA1;

                span {
                    font-size: .1rem;
                    color: #FFFFFF;
                }
            }

            p {
                margin-top: .05rem;
                text-align: center;
                font-weight: 500;
                font-size: .15rem;
                color: #1EFF00;
            }
        }
    }

    .list {
        background: linear-gradient(360deg, #1E2433 0%, #282E43 100%), #FFA100;
        border-radius: .1rem;
        margin-top: .17rem;
        padding: .12rem .24rem;
        min-height: 2rem;

        h5 {
            font-family: Source Han Sans, Source Han Sans;
            font-weight: 500;
            font-size: .13rem;
            color: #FFCFA1;
            line-height: 1.5;
            margin-bottom: 0.06rem;
        }

        .td {
            display: flex;
            align-items: center;

            &.th {
                div {
                    font-weight: 500;
                    font-size: .11rem;
                    color: #FFCFA1;
                    line-height: 1.5;
                }
            }

            div {
                font-weight: 500;
                font-size: .11rem;
                color: #fff;
                line-height: 1.5;
                margin-bottom: 0.02rem;

                &:nth-child(1) {
                    flex: 1;
                }

                &:nth-child(2) {
                    flex: 1;
                    text-align: center;
                }

                &:nth-child(3) {
                    flex: 1;
                    text-align: right;
                }
            }
        }
    }
}
</style>
