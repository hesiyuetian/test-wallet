import { defineStore } from 'pinia';
import { ethers } from 'ethers';
import { ElMessage } from 'element-plus';
import 'element-plus/es/components/message/style/css';
import abi_erc20 from './abi_erc20';
import abi_erc721 from './abi_erc721.json';
import abi_mine from './mine-abi.json';
import abi_pair from './pair-abi.json';
import { markRaw } from 'vue';
import abi_multicall from './multicall.json';
import { appKit } from '@/config/appkit';

const infra_key = 'https://node1.pegorpc.com';

// 网络配置
const NETWORK_CONFIG = {
    56: {
        chainId: '0x38',
        chainName: 'BSC Mainnet',
        rpcUrls: ['https://bsc-dataseed.binance.org/'],
        blockExplorerUrls: ['https://bscscan.com'],
        nativeCurrency: {
            name: 'BNB',
            symbol: 'BNB',
            decimals: 18,
        },
    },
    97: {
        chainId: '0x61',
        chainName: 'BSC Testnet',
        rpcUrls: ['https://data-seed-prebsc-1-s1.binance.org:8545/'],
        blockExplorerUrls: ['https://testnet.bscscan.com'],
        nativeCurrency: {
            name: 'BNB',
            symbol: 'BNB',
            decimals: 18,
        },
    },
};

export const sleep = (time = 5000) => {
    return new Promise(resolve => setTimeout(resolve, time));
};

export const getProvider = () => {
    if (!window.ethereum) {
        return new (ethers as any).providers.JsonRpcProvider(infra_key);
    } else {
        return new (ethers as any).providers.Web3Provider(window.ethereum, 'any');
    }
};
export const useBlockChain = defineStore('block-chain-store', {
    state() {
        return {
            // web3
            provider: undefined,
            account: '',
            chainId: 0,
            signer: undefined,
            token: '',

            // base
            contract_address: {
                56: {
                    tokenContract: '0x320741b80108249B2B644171c47333a9ce1b35D1',
                    usdtContract: '0x55d398326f99059fF775485246999027B3197955',
                    mineContract: '0x28A21DF4449f4B02381415b57efB1f1c521C9966',
                    multicall: '0x38ce767d81de3940cfa5020b55af1a400ed4f657',
                },
                97: {
                    tokenContract: '',
                    usdtContract: '',
                    mineContract: '',
                    multicall: '0x7Ff1b4B31afdBC1E76B5edeB73225685fe477a72',
                },
            },
            lange: 'zh',
            link: {
                tg: 'https://t.me/HeartToken_BSC',
                x: 'https://x.com/HeartToken_',
                debox: '',
                github: '',
                website: '',
                web_url: `${window.location.origin}/#`,
            },
            inviter: window.sessionStorage.getItem('inviter') || '',
            startInit: false,

            // process
            timer: null,
            show_process: false,
            process_time: 20,

            // ==================== 转场动画配置 ====================
            // 可选值: 'page-fade' | 'page-slide' | 'page-scale' | 'page-blur' | 'page-flip'
            transitionName: 'page-blur',
        };
    },

    actions: {
        async init_blockChain() {
            // AppKit 会自动初始化，这里保留兼容性
            let provider = getProvider();
            this.provider = markRaw(provider);
        },

        // 使用 AppKit 打开钱包连接模态框
        async connectWallet() {
            try {
                appKit.open();
            } catch (e: any) {
                ElMessage.error(e?.message ?? '连接钱包失败');
            }
        },

        // 使用 AppKit 断开连接
        async disconnect() {
            try {
                // 清除本地状态
                this.account = '';
                this.chainId = 0;
                this.signer = undefined;

                // 清除本地存储
                localStorage.removeItem('walletConnected');
                sessionStorage.removeItem('walletConnected');

                console.log('钱包连接已断开');
            } catch (e: any) {
                ElMessage.error(e?.message ?? '断开连接失败');
            }
        },

        // 同步 AppKit 状态到 store
        syncAppKitState() {
            // 这个方法将在组件中调用，用于同步 AppKit 的状态
            if (this.provider) {
                this.signer = this.provider.getSigner();
            }
        },


        // async connectWallet() {
        //     try {
        //         const _chainId = Number((await this.provider.getNetwork()).chainId);
        //         let accounts = await this.provider.send('eth_requestAccounts', []);
        //         this.signer = this.provider.getSigner();

        //         // // 使用新的网络检查方法
        //         // const isNetworkValid = await this.checkNetwork();
        //         // if (!isNetworkValid) {
        //         //     return;
        //         // }

        //         // await this.signer.signMessage(`Auth XCH at:${Date.now()}`);
        //         this.account = accounts[0].toLowerCase();
        //         // this.account = '0x9Ee20a74588A1D89e028a2be4CCF842ac9352111';
        //         // this.account = '0xec3CfED9CA0CD7BD9D280f0e804431B82C64e222';
        //         this.chainId = Number((await this.provider.getNetwork()).chainId);
        //     } catch (e: any) {
        //         ElMessage.error(e?.message ?? 'error');
        //     }
        // },

        // async disconnect() {
        //     try {
        //         var res = await window.ethereum.request({
        //             method: 'wallet_revokePermissions',
        //             params: [
        //                 {
        //                     eth_accounts: {},
        //                 },
        //             ],
        //         });
        //         this.account = '';
        //         this.chainId = 0;
        //         console.log('连接已断开', res);
        //     } catch (e: any) {
        //         // 清除本地状态
        //         this.account = '';
        //         this.chainId = 0;
        //         this.signer = undefined;

        //         // 清除本地存储（如果有的话）
        //         localStorage.removeItem('walletConnected');
        //         sessionStorage.removeItem('walletConnected');

        //         console.log('钱包连接已断开');
        //     }
        // },

        async switchChain(targetChainId: number) {
            try {
                if (!window.ethereum) {
                    ElMessage.error('请安装MetaMask钱包');
                    return false;
                }

                if (!NETWORK_CONFIG[targetChainId]) {
                    ElMessage.error(`不支持的网络链ID: ${targetChainId}`);
                    return false;
                }

                const networkConfig = NETWORK_CONFIG[targetChainId];

                try {
                    await (window.ethereum as any).request({
                        method: 'wallet_switchEthereumChain',
                        params: [{ chainId: networkConfig.chainId }],
                    });

                    // 更新本地状态
                    this.chainId = targetChainId;

                    ElMessage.success(`已切换到${networkConfig.chainName}`);
                    return true;
                } catch (switchError: any) {
                    // 如果网络不存在，尝试添加网络
                    if (switchError.code === 4902) {
                        try {
                            await (window.ethereum as any).request({
                                method: 'wallet_addEthereumChain',
                                params: [networkConfig],
                            });

                            // 更新本地状态
                            this.chainId = targetChainId;

                            ElMessage.success(`已添加并切换到${networkConfig.chainName}`);
                            return true;
                        } catch (addError: any) {
                            ElMessage.error(`添加网络失败: ${addError.message}`);
                            return false;
                        }
                    } else {
                        ElMessage.error(`切换网络失败: ${switchError.message}`);
                        return false;
                    }
                }
            } catch (e: any) {
                ElMessage.error(`切换网络失败: ${e?.message ?? '未知错误'}`);
                return false;
            }
        },

        async checkNetwork() {
            try {
                if (!window.ethereum) {
                    return false;
                }

                const currentChainId = Number((await this.provider.getNetwork()).chainId);

                if (![56, 97].includes(currentChainId)) {
                    // ElMessage.error({
                    //     message: '请切换到BSC网络',
                    //     duration: 7000,
                    // });
                    try {
                        await this.switchChain(56);
                    } catch (e: any) {
                        console.error(e?.message ?? 'error');
                        return false;
                    }
                }

                this.chainId = currentChainId;
                return true;
            } catch (e: any) {
                ElMessage.error(`检查网络失败: ${e?.message ?? '未知错误'}`);
                return false;
            }
        },

        // 获取当前网络信息
        getCurrentNetworkInfo() {
            if (this.chainId && NETWORK_CONFIG[this.chainId]) {
                return {
                    chainId: this.chainId,
                    chainName: NETWORK_CONFIG[this.chainId].chainName,
                    isSupported: true,
                };
            }
            return {
                chainId: this.chainId,
                chainName: '未知网络',
                isSupported: false,
            };
        },

        setLange(lange: string) {
            this.lange = lange;
        },
        setInviter(address: string) {
            this.inviter = address.toLowerCase();
            window.sessionStorage.setItem('inviter', this.inviter);
        },

        setStartInit(flag: boolean) {
            this.startInit = flag;
        },

        getLpContract() {
            return new ethers.Contract(this.contract_address[this.chainId].lpContract, abi_pair, this.signer);
        },

        getTokenContract() {
            return new ethers.Contract(this.contract_address[this.chainId].tokenContract, abi_erc20, this.signer);
        },

        getMineContract() {
            return new ethers.Contract(this.contract_address[this.chainId].mineContract, abi_mine.abi, this.signer);
        },

        getTargetTokenContract(token_address) {
            return new ethers.Contract(token_address, abi_erc20, this.signer);
        },

        getMulticallContract() {
            return new ethers.Contract(this.contract_address[this.chainId].multicall, abi_multicall, this.provider);
        },

        async awaitTransactionMined(hash) {
            try {
                await sleep(15000);
                const res = await this.provider.getTransactionReceipt(hash);
                if (res.status) {
                    return true;
                } else {
                    return false;
                }
            } catch (e) {
                throw e;
            }
        },

        async approve(contract_address, token_address, amount) {
            try {
                // 确保使用最新的 provider 和 signer（适配新版 MetaMask）
                let provider = getProvider();
                const signer = provider.getSigner(this.account);
                const token = new ethers.Contract(token_address, abi_erc20, signer);
                const transferTx = await token.approve(contract_address, amount);
                const receipt = await transferTx.wait();
                return receipt.status;
            } catch (e: any) {
                throw e;
            }
        },
        async approveNft(contract_address, nft_address) {
            try {
                let provider = getProvider();
                const signer = provider.getSigner(this.account);
                const contract = new ethers.Contract(nft_address, abi_erc721, signer);
                const transferTx = await contract.setApprovalForAll(contract_address, true);
                const receipt = await transferTx.wait();
                return receipt.status;
            } catch (e: any) {
                throw e;
            }
        },

        async getAllowance(token_address, contract_address, user?: string) {
            const token = new ethers.Contract(token_address, abi_erc20, this.signer);
            const allowance = await token.allowance(user || this.account, contract_address);
            return allowance.toString();
        },

        async getNftAllowance(nft_address, contract_address, user?: string) {
            const contract = new ethers.Contract(nft_address, abi_erc721, this.signer);
            const isApprove = await contract.isApprovedForAll(user || this.account, contract_address);
            return isApprove;
        },

        async getNftBalance(nft_address: string, user?: string) {
            // const token = new ethers.Contract(nft_address, abi_nft, this.signer);
            // let balance = await token.balanceOf(user || this.account);
            // return balance.toString();
        },

        async getBalance(token_address: string, user?: string) {
            let balance = 0;
            if (token_address.toLowerCase() === '0x0000000000000000000000000000000000000000') {
                balance = await this.provider.getBalance(user || this.account);
            } else {
                const token = new ethers.Contract(token_address, abi_erc20, this.signer);
                balance = await token.balanceOf(user || this.account);
            }
            return balance.toString();
        },

        async getTokenDecimals(token_address) {
            const token = new ethers.Contract(token_address, abi_erc20, this.signer);
            console.log(await token.decimals());
            return await token.decimals();
        },

        async sendTransaction(toAddress, amount) {
            try {
                let provider = getProvider();
                const signer = provider.getSigner(this.account);
                // const signer = this.provider.getSigner(this.account);
                const tx = {
                    to: toAddress,
                    value: amount,
                };
                const signedTx = await signer.sendTransaction(tx);
                this.handProcess('open');
                const result = await signedTx.wait();
                return result;
            } catch (error) {
                throw error;
            }
        },

        async sendUsdtTransaction(toAddress, amount) {
            try {
                let provider = getProvider();
                const signer = provider.getSigner(this.account);
                // const signer = this.provider.getSigner(this.account);
                const usdtContract = new ethers.Contract(this.contract_address[this.chainId].usdt, abi_erc20, signer);
                const transferTx = await usdtContract.transfer(toAddress, amount);
                this.handProcess('open');
                const result = await transferTx.wait();
                return result;
            } catch (error) {
                throw error;
            }
        },

        handProcess(type: 'open' | 'close', callback?: () => void, time: number = 20) {
            this.show_process = type === 'open' ? true : false;
            this.process_time = type === 'open' ? time : 0;
            clearInterval(this.timer);
            if (type === 'open') {
                this.timer = setInterval(() => {
                    this.process_time -= 1;
                    if (this.process_time <= 0) {
                        clearInterval(this.timer);
                        this.process_time = 0;
                        if (callback) {
                            callback();
                        }
                    }
                }, 1000);
            }
        },
    },
});
