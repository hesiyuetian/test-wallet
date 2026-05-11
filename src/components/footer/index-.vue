<template>
    <footer>
        <div class="top">
            <div>
                <img @click="() => open(blockChain.link.x)" src="~/images/x.png" alt="" />
                <img @click="() => open(blockChain.link.tg)" src="~/images/tg.png" alt="" />
            </div>
            <!-- <p>Copyright © 2025 Dogecoin. All rights reserved.</p> -->
        </div>
        <!-- <div class="bottom">
            <div class="left">
                <img @click="() => open(blockChain.link.tg)" src="~/images/tg.png" alt="" />
                <img @click="() => open(blockChain.link.tw)" src="~/images/x.png" alt="" />
                <img @click="() => open(blockChain.link.github)" src="~/images/github.png" alt="" />
            </div>
            <span>Light Token</span>
        </div> -->
    </footer>
</template>

<script setup lang="ts">
import { useBlockChain } from '@/store/chain';
const blockChain = useBlockChain();
const open = (href: string) => {
    if (!href) return;
    window.open(href);
};
</script>

<style scoped lang="scss">
footer {
    width: 100%;
    padding: 0.35rem 0.3rem 0.4rem;

    .top {
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 0.1rem;

        div {
            display: flex;
            align-items: center;
            gap: 0.6rem;

            img {
                height: 0.24rem;
            }
        }

        p {
            font-size: 0.1rem;
            color: #757575;
            line-height: 1.5;
        }
    }

    .bottom {
        margin-top: 0.3rem;
        display: flex;
        align-items: center;
        justify-content: space-between;

        .left {
            display: flex;
            align-items: center;
            gap: 0.1rem;

            img {
                width: 0.23rem;
            }
        }

        span {
            font-weight: 700;
            font-size: 0.15rem;
            color: #3d3d3d;
        }
    }
}
</style>
