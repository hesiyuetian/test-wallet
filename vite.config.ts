import { defineConfig, loadEnv } from 'vite';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

export default ({ mode }) => {
    const env = loadEnv(mode, process.cwd());

    return defineConfig({
        plugins: [vue()],
        base: '/',
        optimizeDeps: {
            include: ['@reown/appkit', '@reown/appkit-adapter-wagmi', '@wagmi/vue', 'viem'],
        },
        build: {
            target: 'esnext',
            rollupOptions: {
                external: [],
            },
        },
        resolve: {
            alias: [
                {
                    find: '@',
                    replacement: resolve(__dirname, '/src'),
                },
                {
                    find: 'components',
                    replacement: resolve(__dirname, '/src/components'),
                },
                {
                    find: 'pages',
                    replacement: resolve(__dirname, '/src/pages'),
                },
                {
                    find: 'plugins',
                    replacement: resolve(__dirname, '/src/plugins'),
                },
                {
                    find: 'store',
                    replacement: resolve(__dirname, '/src/store'),
                },
                {
                    find: 'utils',
                    replacement: resolve(__dirname, '/src/utils'),
                },
                {
                    find: 'images',
                    replacement: resolve(__dirname, '/src/assets/images'),
                },
            ],
            extensions: ['.js', '.json', '.ts'],
        },
        server: {
            cors: true,
            open: true,
            host: '0.0.0.0',
            port: 5177,
            proxy: {
                '/apis': {
                    target: 'http://localhost:3009',
                    rewrite: path => path.replace(/^\/apis/, ''),
                },

                '/api_wss': {
                    target: 'http://localhost:3009',
                    // changeOrigin: true,
                    // secure: false, //target是否为https接口
                    ws: true, // 允许websocket代理
                    // rewrite: path => path.replace(/^\/api_wss/, ''),
                },
            },
            allowedHosts: ['64fdfbc3e7d2.ngrok-free.app'],
        },
    });
};
