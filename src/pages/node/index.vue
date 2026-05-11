<template>
    <div class="home main">
        <!-- Banner -->
        <img class="banner" src="~images/node/301.jpg" alt="">

        <img class="title" src="~images/mint-nft/202.png" alt="">
        <div class="info">
            <div class="label">
                向官方地址转账<span>2000</span>USDT，获得心币的种子节点资格
            </div>
            <div class="cont">
                <div class="left">
                    <img src="~images/node/304.png" alt="">
                    {{ $hash('0x0916219AC041eF2D66c5952AE14aB446f8439334', 20, 10) }}
                </div>
                <img class="copy" src="~images/node/copy.png"
                    @click="$copy('0x0916219AC041eF2D66c5952AE14aB446f8439334')" alt="">
            </div>
        </div>

        <img class="deco-img" src="~images/node/310.jpg" alt="">
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
    amount: '' as any,
    bnbBalance: '--' as any,
    tokenBalance: '--' as any,
    allowance: 0 as any,
    approveLoading: false,

    list: [1, 1, 2] as any,

    // 
    usdtBalance: '--' as any,
    isApproved: false,
    totalDividendSubToken: '--' as any,
    totalStaked: '--' as any,
    totalStakedValue: '--' as any,
    usersNum: '--' as any,
    maxReturn: '--' as any,
    nftCount: '--' as any,
    progressPercent: 20,
    pendingRelease: '--' as any,
    pendingRewards: '--' as any,
    directReferralNum: '--' as any,
    refRewards: '--' as any,
    inviter: '--' as any,
    stakeLoading: false,
    claimReleaseLoading: false,
    claimRewardsLoading: false,
    userInfo: {
        amountIn: '--',
        valueIn: '--',
        claimedTotal: '--',
        score: '--',
    } as any,
    top10: [] as any[],
    last10: [] as any[],
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


const stakeDisabled = computed(() => {
    return false;
})

const handleAmountChange = () => {
    state.amount = $onlyNumber(state.amount);
};

const showBindDialog = () => {
    ElMessage.info('请在弹窗中绑定上级地址');
};

const getBaseInfo = async () => {
    try {
        const multicallContract = blockChain.getMulticallContract(),
            tokenContract = blockChain.contract_address[blockChain.chainId].tokenContract,
            mineAddress = blockChain.contract_address[blockChain.chainId].mineContract,
            mineContract = blockChain.getMineContract();
        const calls = [
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('userInfo', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('totalDividendSubToken', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('totalStaked', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('usersNum', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('getTop10', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('getLast10', []) },
            { target: tokenContract, callData: blockChain.getTargetTokenContract(tokenContract).interface.encodeFunctionData('balanceOf', ['0x000000000000000000000000000000000000dead']) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('totalStakedValue', []) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('pendingReleaseAll', [blockChain.account]) },
            { target: mineAddress, callData: mineContract.interface.encodeFunctionData('pendingRewardsAll', [blockChain.account]) },
        ];
        const [, returnData] = await multicallContract.callStatic.aggregate(calls);

        const userInfo = mineContract.interface.decodeFunctionResult('userInfo', returnData[0]);
        const totalDividendSubToken = mineContract.interface.decodeFunctionResult('totalDividendSubToken', returnData[1])[0];
        const totalStaked = mineContract.interface.decodeFunctionResult('totalStaked', returnData[2])[0];
        const usersNum = mineContract.interface.decodeFunctionResult('usersNum', returnData[3])[0];
        const top10 = mineContract.interface.decodeFunctionResult('getTop10', returnData[4])[0];
        const last10 = mineContract.interface.decodeFunctionResult('getLast10', returnData[5])[0];
        const tokenBalance = blockChain.getTargetTokenContract(tokenContract).interface.decodeFunctionResult('balanceOf', returnData[6]);
        const totalStakedValue = mineContract.interface.decodeFunctionResult('totalStakedValue', returnData[7])[0];
        const pendingRelease = mineContract.interface.decodeFunctionResult('pendingReleaseAll', returnData[8])[0];
        const pendingRewards = mineContract.interface.decodeFunctionResult('pendingRewardsAll', returnData[9])[0];

        state.totalDividendSubToken = $shiftedByFixed(totalDividendSubToken.toString(), -18, 4);
        state.totalStaked = $shiftedByFixed(totalStaked.toString(), -18, 4);
        state.usersNum = Number(usersNum.toString());
        state.tokenBalance = $shiftedByFixed(tokenBalance.toString(), -18, 4);
        state.totalStakedValue = $shiftedByFixed(totalStakedValue.toString(), -18, 4);
        state.pendingRelease = $shiftedByFixed(pendingRelease.toString(), -18, 4);
        state.pendingRewards = $shiftedByFixed(pendingRewards.toString(), -18, 4);

        const amountIn = $shiftedByFixed(userInfo.amountIn.toString(), -18, 4);
        const claimedTotal = $shiftedByFixed(userInfo.claimedTotal.toString(), -18, 4);
        const score = Number(userInfo.score.toString());
        state.userInfo = { amountIn, valueIn: $shiftedByFixed(userInfo.valueIn.toString(), -18, 4), claimedTotal, score };
        state.maxReturn = $shiftedByFixed($BigNumber(userInfo.amountIn.toString()).multipliedBy(3).toFixed(), -18, 4);
        state.nftCount = score;
        state.inviter = userInfo.inviter === '0x0000000000000000000000000000000000000000' ? '--' : userInfo.inviter;
        state.directReferralNum = Number(userInfo.directReferralNum.toString());
        state.refRewards = $shiftedByFixed(userInfo.refRelease.toString(), -18, 4);

        const maxVal = Number(state.maxReturn);
        const claimed = Number(claimedTotal);
        state.progressPercent = maxVal > 0 ? Math.min((claimed / maxVal) * 100, 100) : 0;

        state.top10 = top10.filter(ele => ele.user !== '0x0000000000000000000000000000000000000000').map(ele => ({
            addr: ele.user,
            amount: $shiftedByFixed(ele.amount.toString(), -18, 4),
            value: $shiftedByFixed(ele.bnbValue.toString(), -18, 4),
            tokenAmount: $shiftedByFixed(ele.rewards.toString(), -18, 4),
        }));
        state.last10 = last10.filter(ele => ele.user !== '0x0000000000000000000000000000000000000000').map(ele => ({
            addr: ele.user,
            amount: $shiftedByFixed(ele.amount.toString(), -18, 4),
            value: $shiftedByFixed(ele.bnbValue.toString(), -18, 4),
            tokenAmount: $shiftedByFixed(ele.rewards.toString(), -18, 4),
        }));
    } catch (e: any) { }
};

const getUsdtBalance = async () => {
    try {
        const tokenContract = blockChain.contract_address[blockChain.chainId].tokenContract;
        const balance = await blockChain.getBalance(tokenContract);
        state.usdtBalance = $shiftedByFixed(balance, -18, 4);
    } catch (e: any) { }
};


const stake = async () => {
    if (state.stakeLoading) return;
    if (!blockChain.account) { ElMessage.warning('请先连接钱包'); return; }
    try {
        state.stakeLoading = true;
        const tokenContract = blockChain.contract_address[blockChain.chainId].tokenContract;
        const mineAddress = blockChain.contract_address[blockChain.chainId].mineContract;
        const amount = $BigNumber(state.inputAmount).shiftedBy(18).toFixed();
        const allowance = await blockChain.getAllowance(tokenContract, mineAddress);
        if ($BigNumber(allowance).lt(amount)) {
            const approveResult = await blockChain.approve(mineAddress, tokenContract, '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff');
            if (!approveResult) { ElMessage.error('授权失败'); return; }
            ElMessage.success('授权成功');
            state.isApproved = true;
        }
        const contract = blockChain.getMineContract();
        const tx = await contract.stake(amount);
        blockChain.handProcess('open');
        const receipt = await tx.wait();
        if (receipt.status) { ElMessage.success('铸造成功'); getBaseInfo(); getUsdtBalance(); }
        else { ElMessage.error('铸造失败'); }
    } catch (e: any) {
        ElMessage.error(e?.reason ?? e?.message ?? '操作失败');
    } finally { state.stakeLoading = false; blockChain.handProcess('close'); }
};

const handleClaimRelease = async () => {
    if (state.claimReleaseLoading) return;
    if (!blockChain.account) { ElMessage.warning('请先连接钱包'); return; }
    try {
        state.claimReleaseLoading = true;
        const contract = blockChain.getMineContract();
        const tx = await contract.claimRelease();
        blockChain.handProcess('open');
        const receipt = await tx.wait();
        if (receipt.status) { ElMessage.success('领取成功'); getBaseInfo(); }
        else { ElMessage.error('领取失败'); }
    } catch (e: any) {
        ElMessage.error(e?.reason ?? e?.message ?? '领取失败');
    } finally { state.claimReleaseLoading = false; blockChain.handProcess('close'); }
};

const handleClaimRewards = async () => {
    if (state.claimRewardsLoading) return;
    if (!blockChain.account) { ElMessage.warning('请先连接钱包'); return; }
    try {
        state.claimRewardsLoading = true;
        const contract = blockChain.getMineContract();
        const tx = await contract.claimRewards();
        blockChain.handProcess('open');
        const receipt = await tx.wait();
        if (receipt.status) { ElMessage.success('领取成功'); getBaseInfo(); }
        else { ElMessage.error('领取失败'); }
    } catch (e: any) {
        ElMessage.error(e?.reason ?? e?.message ?? '领取失败');
    } finally { state.claimRewardsLoading = false; blockChain.handProcess('close'); }
};

const init = async () => {
    if (blockChain.account && blockChain.chainId && blockChain.startInit) {
        if (![97, 56].includes(Number(blockChain.chainId))) {
            ElMessage.error({ message: t('change network'), duration: 7000 });
            return;
        }
        getBaseInfo();
        getUsdtBalance();
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

    .title {
        height: .57rem;
    }


    .info {
        background: url('../../assets/images/home/120.png') no-repeat center center;
        background-size: 100% 100%;
        margin-top: .14rem;
        padding: .2rem 0.05rem .29rem;


        .label {
            font-weight: 500;
            font-size: .13rem;
            color: #FFCFA1;
            line-height: 1.2;
            text-align: center;

            span {
                color: #1EFF00;
            }
        }

        .cont {
            width: calc(100% - .2rem);
            margin-inline: auto;
            height: .45rem;
            background: #000000;
            border-radius: .05rem;
            margin-top: .24rem;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding-right: .15rem;

            .left {
                display: flex;
                align-items: center;
                gap: .1rem;
                font-weight: 500;
                font-size: .12rem;
                color: #FFFFFF;

                img {
                    height: .45rem;
                }
            }

            .copy {
                height: .16rem;
            }

        }


    }

    .deco-img {
        width: 100%;
        margin-top: .3rem;
    }
}
</style>
