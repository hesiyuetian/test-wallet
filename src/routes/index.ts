import { createRouter, createWebHistory, Router, createWebHashHistory } from 'vue-router';

const router: Router = createRouter({
    history: createWebHashHistory(),
    routes: [
        {
            path: '/',
            component: () => import('@/components/layout/index.vue'),
            children: [
                // {
                //     path: '/',
                //     component: () => import('@/components/banner/index.vue'),
                //     children: [
                {
                    path: '/',
                    component: () => import('@/pages/home/index.vue'),
                },
                {
                    path: '/mint-nft',
                    component: () => import('@/pages/mintNft/index.vue'),
                },
                {
                    path: '/node',
                    component: () => import('@/pages/node/index.vue'),
                },
                {
                    path: '/nft',
                    component: () => import('@/pages/nft/index.vue'),
                },
            ],
        },
    ],
});

export default router;
