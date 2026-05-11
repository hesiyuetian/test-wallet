import { createAppKit } from '@reown/appkit/vue';
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi';
import { bsc, bscTestnet, mainnet } from '@reown/appkit/networks';

// 1. 从 https://dashboard.reown.com 获取 projectId
const projectId = 'c19f71a764dc43db72a48897b81e1e01'; // 请替换为您的实际 projectId

// 2. 创建元数据对象
const metadata = {
    name: 'Burn',
    description: 'Burn DeFi Platform',
    url: window.location.origin,
    icons: ['https://avatars.githubusercontent.com/u/179229932'],
};

// 3. 设置支持的网络
const networks = [
    bsc,
    bscTestnet
];

// 4. 创建 Wagmi 适配器
const wagmiAdapter = new WagmiAdapter({
    networks,
    projectId,
});

// 5. 创建 AppKit 实例
export const appKit = createAppKit({
    adapters: [wagmiAdapter],
    networks: networks as any,
    projectId,
    metadata,
    features: {
        email: false,
        socials: false,
        // analytics: true, // 可选 - 默认为您的云配置
    },
    // 禁用自动连接
    // enableNetworkView: false,
    // enableAccountView: false,
});

// 导出 wagmi 配置
export const wagmiConfig = wagmiAdapter.wagmiConfig;

export { networks, projectId, metadata };
