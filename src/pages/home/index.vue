<template>
    <div class="home main">
        <!-- Banner -->
        <img class="banner" src="~images/home/105.jpg" alt="">

        <div class="address">
            <div class="address-item">
                <div class="left">
                    <b>上级地址</b>
                    {{ $hash(state.userInfo.inviter, 18, 8) }}
                </div>
                <!-- <div class="right">绑定</div> -->
            </div>
            <div class="address-item">
                <div class="left">
                    <b>我的邀请链接</b>
                    {{ $hash(inviterLink, 14, 8) }}
                </div>
                <div class="right" @click="$copy(inviterLink)">复制</div>
            </div>
        </div>

        <div class="stake">
            <img class="title" src="~images/home/110.png" alt="">
            <div class="card">
                <div class="top">
                    选择铸造数量
                    <span>余额：{{ state.tokenBalance }} USDT</span>
                </div>
                <div class="input">
                    <div class="cont">
                        <div class="left">
                            <img src="~images/home/113.png" alt="">
                            USDT
                        </div>
                        <input type="text" disabled v-model="state.amount" @keyup="handleAmountChange" placeholder="0">
                    </div>
                    <img class="plus" @click="state.amount = $BigNumber(state.amount || 0).plus(200).toFixed()"
                        src="~images/home/114.png" alt="">
                </div>
                <div class="btns">
                    <div v-for="item in presetAmounts" :key="item" :class="{ active: state.amount == item }"
                        @click="state.amount = item">{{ item }}</div>
                </div>
                <el-button class="stake-btn" v-if="needApprove" :loading="state.approveLoading" @click="approve()">
                    授权
                </el-button>
                <el-button class="stake-btn" v-else :loading="state.stakeLoading" :disabled="stakeDisabled"
                    @click="stake()">
                    质押挖矿
                </el-button>
                <p>*每铸造200USDT会获得一张随机NFT，自动进入钱包地址</p>
            </div>
        </div>

        <div class="info">
            <div class="item">
                <h5>铸造数量 <span>USDT</span></h5>
                <p>{{ state.userInfo.amountIn }}</p>
            </div>
            <div class="item">
                <h5>最大收益 <span>USDT</span></h5>
                <p>{{ state.userInfo.maxReward }}</p>
            </div>
            <div class="item">
                <h5>获得NFT数量 <span>张</span></h5>
                <p>{{ state.userInfo.rewardNftNums }}</p>
            </div>
            <div class="item">
                <h5>已实现收益 <span>USDT</span></h5>
                <p>{{ state.userInfo.realizedRewards }}</p>
            </div>
        </div>

        <div class="process">
            <div class="cont">
                <div class="mask" :style="{ width: `${progressPercent}%` }"></div>
                <div class="tag" :style="{ left: `calc(${progressPercent}% - 10px)` }">
                    <img src="~images/home/123.png" alt="">
                    {{ state.userInfo.realizedRewards }}
                </div>
            </div>
            <div class="tips">
                已实现收益
                <div>{{ state.userInfo.realizedRewards }}<span>/{{ state.userInfo.maxReward }} USDT</span></div>
            </div>
        </div>

        <div class="reward">
            <div class="item">
                <div class="left">
                    <h5>待领取收益</h5>
                    <p>USDT</p>
                </div>
                <div class="right">
                    <img src="~images/home/113.png" alt="">
                    {{ state.userInfo.rewardsForUSDT }}
                    <el-button :loading="state.claimUsdtLoading" :disabled="claimUsdtDisabled"
                        @click="claimUsdt()">领取</el-button>
                </div>
            </div>
            <div class="item">
                <div class="left">
                    <h5>待兑换收益</h5>
                    <p>心币</p>
                </div>
                <div class="right">
                    <img src="~images/home/134.png" alt="">
                    {{ state.equalToken }}
                    <el-button :loading="state.claimTokenLoading" :disabled="claimTokenDisabled"
                        @click="claimToken()">领取</el-button>
                </div>
            </div>
        </div>

        <div class="info invite">
            <div class="item">
                <h5>邀请数量 <span>地址</span></h5>
                <p>{{ state.userInfo.directReferralNum }}</p>
            </div>
            <div class="item">
                <h5>邀请铸造数量 <span>USDT</span></h5>
                <p>{{ state.userInfo.score }}</p>
            </div>
            <div class="item">
                <h5>已获推荐奖励 <span>USDT</span></h5>
                <p>{{ state.userInfo.refRewards }}</p>
            </div>
            <div class="item">
            </div>
        </div>

        <div class="list">
            <h5>铸造记录</h5>
            <div class="th td">
                <div>序号</div>
                <div>时间</div>
                <div>金额USDT</div>
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
const presetAmounts = [200, 400, 600, 800, 1000];

const state = reactive({
    amount: 200 as any,
    bnbBalance: '--' as any,
    tokenBalance: '--' as any,
    allowance: 0 as any,
    approveLoading: false,
    list: [] as any,
    equalToken: '--' as any,
    startTime: 0,
    minAmount: 0,
    userInfo: {
        inviter: '--',
        amountIn: '--',
        maxReward: '--',
        realizedRewards: '--',
        rewardsForUSDT: '--',
        score: '--',
        refRewards: '--',
        rewardNftNums: '--',
        directReferralNum: '--',
    } as any,
    stakeLoading: false,
    claimUsdtLoading: false,
    claimTokenLoading: false,
});

watch(() => blockChain.chainId, () => { init(); });
watch(() => blockChain.account, () => { init(); });
watch(() => blockChain.startInit, () => { init(); });

const inviterLink = computed(() => {
    return `${blockChain.link.web_url}?id=${blockChain.account}`;
});

const needApprove = computed(() => {
    if (!state.amount) return false;
    return $BigNumber(state.amount).gt(state.allowance);
});


const progressPercent = computed(() => {
    let num = 0
    if (state.equalToken === '--' || !state.userInfo.maxReward) {
        num = 0;
    } else {
        num = $BigNumber(state.userInfo.realizedRewards).div(state.userInfo.maxReward).multipliedBy(100).toNumber();
    }
    return Math.max(num, 5);
})
const stakeDisabled = computed(() => {
    return state.equalToken === '--' || !state.startTime;
})
const claimUsdtDisabled = computed(() => {
    return state.userInfo.rewardsForUSDT === '--' || !state.userInfo.rewardsForUSDT;
})
const claimTokenDisabled = computed(() => {
    return state.equalToken === '--' || !state.equalToken;
})

const handleAmountChange = () => {
    state.amount = $onlyNumber(state.amount);
};

const getBalance = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            tokenContract = blockChain.contract_address[blockChain.chainId].usdtContract;
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
    } catch (e: any) { }
};

const getAllowance = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            tokenContract = blockChain.contract_address[blockChain.chainId].usdtContract,
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
        const contract = blockChain.contract_address[blockChain.chainId].usdtContract;
        const result = await blockChain.approve(blockChain.contract_address[blockChain.chainId].mineContract, contract, $BigNumber(state.amount).shiftedBy(18).toFixed());
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
        if (state.equalToken === '--') throw new Error(t('base.load data'));
        if ($BigNumber(state.amount).lt(state.minAmount)) throw new Error(`质押数量不能小于${state.minAmount}`);
        if ($BigNumber(state.amount).gt(state.tokenBalance)) throw new Error('余额不足');
        state.stakeLoading = true;
        const override = {
            // value: $BigNumber(state.fee).shiftedBy(18).toFixed(),
            // gasLimit: $BigNumber(gas.toString()).multipliedBy(2).toFixed(0),
            // gasPrice: Number(gasPrice) + 1,
        };
        const mineContract = blockChain.getMineContract();
        const transferTx = await mineContract.stake($BigNumber(state.amount).shiftedBy(18).toFixed(), override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({ showClose: true, message: '质押成功', type: 'success', duration: 2500 });
            getBalance();
            getAllowance();
            getBaseInfo();
            state.amount = 200;
        } else {
            throw new Error('质押失败');
        }
    } catch (e: any) {
        ElMessage({ showClose: true, message: e?.reason ?? e?.message ?? 'Error', type: 'error', duration: 2500 });
    } finally {
        state.stakeLoading = false;
    }
};

const claimUsdt = async () => {
    try {
        if (state.equalToken === '--') throw new Error(t('base.load data'));
        state.claimUsdtLoading = true;
        const override = {
            // value: $BigNumber(state.fee).shiftedBy(18).toFixed(),
            // gasLimit: $BigNumber(gas.toString()).multipliedBy(2).toFixed(0),
            // gasPrice: Number(gasPrice) + 1,
        };
        const mineContract = blockChain.getMineContract();
        const transferTx = await mineContract.claimUsdt(override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({ showClose: true, message: '领取成功', type: 'success', duration: 2500 });
            getBalance();
            getBaseInfo();
        } else {
            throw new Error('领取失败');
        }
    } catch (e: any) {
        ElMessage({ showClose: true, message: e?.reason ?? e?.message ?? 'Error', type: 'error', duration: 2500 });
    } finally {
        state.claimUsdtLoading = false;
    }
};

const claimToken = async () => {
    try {
        if (state.equalToken === '--') throw new Error(t('base.load data'));
        state.claimTokenLoading = true;
        const override = {
            // value: $BigNumber(state.fee).shiftedBy(18).toFixed(),
            // gasLimit: $BigNumber(gas.toString()).multipliedBy(2).toFixed(0),
            // gasPrice: Number(gasPrice) + 1,
        };
        const mineContract = blockChain.getMineContract();
        const transferTx = await mineContract.claimToken(override);
        const receipt = await transferTx.wait();
        if (receipt.status) {
            ElMessage({ showClose: true, message: '领取成功', type: 'success', duration: 2500 });
            getBalance();
            getBaseInfo();
        } else {
            throw new Error('领取失败');
        }
    } catch (e: any) {
        ElMessage({ showClose: true, message: e?.reason ?? e?.message ?? 'Error', type: 'error', duration: 2500 });
    } finally {
        state.claimTokenLoading = false;
    }
};

const getBaseInfo = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            mineAddress = blockChain.contract_address[blockChain.chainId].mineContract,
            mineContract = blockChain.getMineContract();
        const calls = [
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('userInfo', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('equalToken', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('getUserStakeRecords', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('minAmount', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('startTime', []) },
        ];
        const [, returnData] = await multicallContract.callStatic.aggregate(calls);

        const userInfo = mineContract.interface.decodeFunctionResult('userInfo', returnData[0]);
        const equalToken = mineContract.interface.decodeFunctionResult('equalToken', returnData[1])[0];
        const userStakeRecords = mineContract.interface.decodeFunctionResult('getUserStakeRecords', returnData[2])[0];
        const minAmount = mineContract.interface.decodeFunctionResult('minAmount', returnData[3])[0];
        const startTime = mineContract.interface.decodeFunctionResult('startTime', returnData[4])[0];

        state.minAmount = $shiftedByFixed(minAmount.toString(), -18, 4);
        state.startTime = Number(startTime.toString()) * 1000;

        const amountIn = $shiftedByFixed(userInfo.amountIn.toString(), -18, 4);
        state.userInfo = {
            inviter: userInfo.inviter === '0x0000000000000000000000000000000000000000' ? '--' : userInfo.inviter,
            amountIn,
            maxReward: Number($BigNumber(amountIn).multipliedBy(3).toFixed(4, 1)), //
            realizedRewards: $shiftedByFixed(userInfo.realizedRewards.toString(), -18, 4),
            rewardsForUSDT: $shiftedByFixed(userInfo.rewardsForUSDT.toString(), -18, 4),
            score: $shiftedByFixed(userInfo.score.toString(), -18, 4),
            refRewards: $shiftedByFixed(userInfo.refRewards.toString(), -18, 4),
            rewardNftNums: Number(userInfo.rewardNftNums.toString()),
            directReferralNum: Number(userInfo.directReferralNum.toString()),
        };
        state.equalToken = $shiftedByFixed(equalToken.toString(), -18, 1)
        state.list = userStakeRecords.filter(ele => Number(ele.time.toString()) !== 0).map(ele => ({
            amount: $shiftedByFixed(ele.amount.toString(), -18, 4),
            time: Number(ele.time.toString()) * 1000,
        }));
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

    .address {
        margin: .18rem 0 .1rem;

        .address-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-left: .17rem;
            height: .33rem;
            background: #0A3429;
            border-radius: .05rem;
            margin-bottom: .12rem;

            &:last-child {
                margin-bottom: 0;
            }

            .left {
                display: flex;
                align-items: center;
                gap: .12rem;
                font-weight: 500;
                font-size: .11rem;
                color: #FFFFFF;

                b {
                    font-size: .13rem;
                    color: #FFCFA1;
                }
            }

            .right {
                width: .75rem;
                height: 100%;
                background: url('../../assets/images/home/133.png') no-repeat center center;
                background-size: 100% 100%;
                font-weight: 500;
                font-size: .15rem;
                color: #000000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
        }
    }

    .stake {
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

                .cont {
                    width: 100%;
                    height: 100%;
                    background: #F1FFD5;
                    border-radius: .05rem;

                    .left {
                        position: absolute;
                        left: .08rem;
                        top: 50%;
                        transform: translateY(-50%);
                        display: flex;
                        align-items: center;
                        gap: .06rem;
                        font-weight: 500;
                        font-size: .15rem;
                        color: #000000;

                        img {
                            height: .25rem;
                        }


                    }

                    input {
                        width: 100%;
                        height: 100%;
                        border: none !important;
                        outline: none !important;
                        padding: 0 .18rem;
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

            .btns {
                margin-block: .16rem;
                display: flex;
                align-items: center;
                justify-content: space-between;
                gap: 0.08rem;

                div {
                    flex: 1;
                    height: .25rem;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-weight: 500;
                    font-size: .13rem;
                    color: #000000;
                    border-radius: .05rem;
                    cursor: pointer;
                    background: linear-gradient(180deg, #00ED6B 0%, #006D1D 100%);

                    &.active {
                        background: linear-gradient(360deg, #A0FF97 0%, #FFFFFF 100%);
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

        &.invite {
            background: url('../../assets/images/home/130.png') no-repeat center center;
            background-size: 100% 100%;
        }

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

    .process {
        margin-top: .3rem;
        width: 100%;

        .cont {
            width: 100%;
            height: .1rem;
            position: relative;
            background: #FFFFFF;
            border-radius: .1rem;

            .mask {
                height: 100%;
                background: #1EFF00;
                border-radius: .1rem;
                position: absolute;
                top: 0;
                left: 0;
                z-index: 1;
            }

            .tag {
                position: absolute;
                top: -.15rem;
                z-index: 2;
                left: 0;
                display: flex;
                align-items: center;
                gap: .03rem;
                font-size: .1rem;
                font-weight: 500;
                color: #1EFF00;

                img {
                    height: .13rem;
                }
            }
        }

        .tips {
            margin-top: .04rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-weight: 500;
            font-size: .1rem;
            color: #1EFF00;

            div {
                span {
                    color: #fff;
                }
            }
        }
    }

    .reward {
        background: url('../../assets/images/home/130.png') no-repeat center center;
        background-size: 100% 100%;
        margin-top: .17rem;
        padding: .18rem 0.22rem .3rem;

        .item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: .09rem;

            &:last-child {
                margin-top: .18rem;
            }

            .left {
                flex: 1;
                text-align: right;

                h5 {
                    font-weight: 500;
                    font-size: .13rem;
                    color: #FFCFA1;
                    line-height: 1;
                }

                p {
                    margin-top: 0.05rem;
                    font-weight: 500;
                    line-height: 1;
                    font-size: .1rem;
                    color: #FFFFFF;
                }
            }

            .right {
                width: 2.11rem;
                height: .42rem;
                background: #000000;
                border-radius: .05rem;
                display: flex;
                align-items: center;
                justify-content: space-between;
                padding-left: .07rem;
                gap: .04rem;

                font-weight: 500;
                font-size: .25rem;
                color: #1EFF00;

                img {
                    height: .26rem;
                }

                button {
                    width: .75rem;
                    height: 100%;
                    background: url('../../assets/images/home/133.png') no-repeat center center;
                    background-size: 100% 100%;
                    font-weight: 500;
                    font-size: .15rem;
                    color: #000000;
                }

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
