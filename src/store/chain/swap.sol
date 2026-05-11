//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract SWAP is Ownable {
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public constant USDT = 0x55d398326f99059fF775485246999027B3197955;
    address public constant T = 0xf108D862d15839C29797C7Ca4d500C29Aa51701f;
    uint public slippage = 10;

    function setSlippage(uint _slippage) external onlyOwner {
        slippage = _slippage;
    }

    function getAmountOut(address from, address to, uint amountIn) external view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(amountIn, path);
        return amountsOut[1];
    }

    function swapExactTokenForTokens(address from, address to, uint amountIn) external {
        IERC20(from).transferFrom(msg.sender, address(this), amountIn);
        
        if (IERC20(from).allowance(address(this), ROUTER) < amountIn) {
            IERC20(from).approve(ROUTER, type(uint).max);
        }
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(amountIn, path);
        uint amountOutMin = amountsOut[1] * (100 - slippage) / 100;

        // make the swap
        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMin, // accept any amount of USDT
            path,
            msg.sender,
            block.timestamp
        );
    }

    function addLiquidityWithUSDT(uint usdtAmount) external {
        IERC20(USDT).transferFrom(msg.sender, address(this), usdtAmount);
        uint half = usdtAmount / 2;

        if (IERC20(USDT).allowance(address(this), ROUTER) < usdtAmount) {
            IERC20(USDT).approve(ROUTER, type(uint).max);
        }
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = T;

        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(half, path);
        uint amountOutMin = amountsOut[1] * (100 - slippage) / 100;

        uint bb = IERC20(T).balanceOf(address(this));
        // make the swap
        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            half,
            amountOutMin, // accept any amount of USDT
            path,
            address(this),
            block.timestamp
        );
        uint tokenIn = IERC20(T).balanceOf(address(this)) - bb;
        if (IERC20(T).allowance(address(this), ROUTER) < tokenIn) {
            IERC20(T).approve(ROUTER, type(uint).max);
        }
        
        IRouter(ROUTER).addLiquidity(
            T,
            USDT,
            tokenIn,
            half,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    function addLiquidityWithT(uint tokenAmount) external {
        IERC20(T).transferFrom(msg.sender, address(this), tokenAmount);
        uint half = tokenAmount / 2;

        if (IERC20(T).allowance(address(this), ROUTER) < tokenAmount) {
            IERC20(T).approve(ROUTER, type(uint).max);
        }
        address[] memory path = new address[](2);
        path[0] = T;
        path[1] = USDT;

        uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(half, path);
        uint amountOutMin = amountsOut[1] * (100 - slippage) / 100;

        uint bb = IERC20(USDT).balanceOf(address(this));
        // make the swap
        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            half,
            amountOutMin, // accept any amount of USDT
            path,
            address(this),
            block.timestamp
        );
        uint usdtIn = IERC20(USDT).balanceOf(address(this)) - bb;
        if (IERC20(USDT).allowance(address(this), ROUTER) < usdtIn) {
            IERC20(USDT).approve(ROUTER, type(uint).max);
        }
        
        IRouter(ROUTER).addLiquidity(
            T,
            USDT,
            half,
            usdtIn,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            msg.sender,
            block.timestamp
        );
    }

    function rescurToken(address token, uint amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    function rescueETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }
}