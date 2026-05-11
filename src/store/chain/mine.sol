//SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
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
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
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

interface IToken {
    function mintTo(address to, uint amount) external;
}

interface INft {
    function mintTo(address to) external;
    function balanceOf(address owner) external view returns (uint256);
}

contract Pool is Ownable {
    struct UserInfo {
        address inviter;
        uint score;
        uint amountIn;
        uint refRewards;
        uint rewardsForUSDT;
        uint rewardsForToken;
        uint realizedRewards;
        uint rewardNftNums;
        uint mintNftNums;

        uint directReferralNum;
        mapping (address => bool) isSonExist;
    }
    mapping(address => UserInfo) public userInfo;
    
    address constant public ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address constant public USDT = 0x55d398326f99059fF775485246999027B3197955;
    
    address public firstAddr = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public marketingAddrA = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public marketingAddrB = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public marketingAddrC = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public tokenVault1 = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public tokenVault2 = 0x5981D4C5b2621F51D337B1DB252f9b78550AfC70;
    address public TOKEN;
    address[5] public NFTS;
    uint[5] public ratios = [40,30,20,8,2];

    uint public startTime;
    uint public totalStakedNet;

    uint public minAmount = 200 * 1e18;
    uint public basePrice = 1 * 1e18;
    uint public tokenRatio = 30;
    uint public nftPrice = 33 * 1e18;

    struct Record {
        uint time;
        uint amount;
    }
    mapping (address => Record[10]) public stakeRecord;
    mapping (address => uint) public lastStakeIndex; 

    mapping (address => Record[10]) public nftRecord;
    mapping (address => uint) public lastNftIndex; 

    function init(address token, address[5] memory nfts) public onlyOwner {
        TOKEN = token;
        NFTS = nfts;
    }

    function setStartTime(uint _timeStamp) external onlyOwner {
        startTime = _timeStamp;
    }

    function setBasePrice(uint _basePrice) external onlyOwner {
        basePrice = _basePrice;
    }

    function setRatios(uint[5] memory _ratios) external onlyOwner {
        ratios = _ratios;
    }

    function setTokenRatio(uint _tokenRatio) external onlyOwner {
        tokenRatio = _tokenRatio;
    }

    function setNftPrice(uint _nftPrice) external onlyOwner {
        nftPrice = _nftPrice;
    }

    function setMinAmount(uint _minAmount) external onlyOwner {
        minAmount = _minAmount;
    }

    function setMarketingAddr(address a, address b, address c) external onlyOwner {
        marketingAddrA = a;
        marketingAddrB = b;
        marketingAddrC = c;
    }

    
    function setTokenVault(address _tokenVault1, address _tokenVault2) external onlyOwner {
        tokenVault1 = _tokenVault1;
        tokenVault2 = _tokenVault2;
    }

    function isValidInviter(address inviter) public view returns (bool) {
        if (inviter == firstAddr || (userInfo[inviter].inviter != address(0))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function bind(address inviter) external {
        require(isValidInviter(inviter));
        require(msg.sender != firstAddr);
        UserInfo storage ui = userInfo[msg.sender];
        require(ui.inviter == address(0));
        ui.inviter = inviter;
    }

    function stake(uint usdtAmount) external {
        require(msg.sender == tx.origin, "Only EOA allowed");
        require(msg.sender.code.length == 0);
        require(startTime > 0);
        require(usdtAmount >= minAmount && usdtAmount % minAmount == 0);

        UserInfo storage ui = userInfo[msg.sender];
        address inviter = ui.inviter;
        require(inviter != address(0));
        require(ui.amountIn == 0);
        IERC20(USDT).transferFrom(msg.sender, address(this), usdtAmount);

        address cur = msg.sender;
        UserInfo storage uiI = userInfo[inviter];
        if (!uiI.isSonExist[cur]) {
            uiI.isSonExist[cur] = true;
            uiI.directReferralNum++;
        }

        address _inviter = inviter;
        uint spend = 0;
        uint rewardPer = usdtAmount / 10;
        IERC20(USDT).transfer(marketingAddrB, rewardPer);
        for (uint8 i; i < 9; i++) {
            if (_inviter == address(0)) break;
            UserInfo storage uiOf = userInfo[_inviter];
            uiOf.score += usdtAmount;

            if (uiOf.amountIn > 0) {
                uiOf.rewardsForUSDT += rewardPer * 60 / 100;
                uiOf.rewardsForToken += rewardPer * 40 / 100;
                uiOf.refRewards += rewardPer;
                spend += rewardPer;
            }
            
            _inviter = uiOf.inviter;
        }
        uint left = usdtAmount * 90 / 100 - spend;
        if (left > 0) {
            IERC20(USDT).transfer(firstAddr, left);
        }

        ui.amountIn = usdtAmount;
        totalStakedNet += usdtAmount;

        uint nftNum = usdtAmount / minAmount;
        ui.rewardNftNums += nftNum;
        _mintNft(msg.sender, nftNum);

        Record memory record;
        record.time = block.timestamp;
        record.amount = usdtAmount;
        uint index = lastStakeIndex[msg.sender];
        stakeRecord[msg.sender][index] = record;
        lastStakeIndex[msg.sender]++;
        if (lastStakeIndex[msg.sender] >= 10) {
            lastStakeIndex[msg.sender] = 0;
        }
	}

    function _mintNft(address to, uint num) private {
        for (uint i; i < num; i++) {
            uint random = uint256(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender, i)));
            random = random % 100 + 1;
            address nft = NFTS[0];
            if (random > 100 - ratios[4]) {
                nft = NFTS[4];
            } else if (random > 100 - (ratios[4] + ratios[3])) {
                nft = NFTS[3];
            } else if (random > 100 - (ratios[4] + ratios[3] + ratios[2])) {
                nft = NFTS[2];
            } else if (random > 100 - (ratios[4] + ratios[3] + ratios[2] + ratios[1])) {
                nft = NFTS[1];
            }

            INft(nft).mintTo(to);
        }
    }

    function claimUsdt() external {
        require(msg.sender == tx.origin, "Only EOA allowed");
        require(msg.sender.code.length == 0);

        UserInfo storage ui = userInfo[msg.sender];
        uint amount = ui.rewardsForUSDT;
        require(amount > 0);
        ui.rewardsForUSDT = 0;

        uint leftMaxReward = ui.amountIn * 3 - ui.realizedRewards;
        if (amount < leftMaxReward) {
            ui.realizedRewards += amount;
        } else {
            amount = leftMaxReward;
            _quit(msg.sender);
        }

        uint toUser = amount * 95 / 100;
        IERC20(USDT).transfer(msg.sender, toUser);
        IERC20(USDT).transfer(marketingAddrB, amount - toUser);
    }

    function claimToken() external {
        require(msg.sender == tx.origin, "Only EOA allowed");
        require(msg.sender.code.length == 0);

        UserInfo storage ui = userInfo[msg.sender];
        uint amount = ui.rewardsForToken;
        require(amount > 0);
        ui.rewardsForToken = 0;
        IERC20(USDT).transfer(marketingAddrC, amount);

        uint leftMaxReward = ui.amountIn * 3 - ui.realizedRewards;
        if (amount < leftMaxReward) {
            ui.realizedRewards += amount;
        } else {
            amount = leftMaxReward;
            _quit(msg.sender);
        }

        uint toUser = amount * 1e18 / tokenPrice();
        uint toVault = toUser * tokenRatio / 100;
        IToken(TOKEN).mintTo(msg.sender, toUser);
        IToken(TOKEN).mintTo(tokenVault1, toVault);
    }

    function tokenPrice() public view returns (uint) {
        if (basePrice > 0) {
            return basePrice;
        } else {
            address[] memory path = new address[](2);
            path[0] = TOKEN;
            path[1] = USDT;
            uint[] memory amountsOut = IRouter(ROUTER).getAmountsOut(1e18, path);
            return amountsOut[1];
        }
    }

    function _quit(address user) private {
        UserInfo storage ui = userInfo[user];
        ui.amountIn = 0;
        ui.rewardsForUSDT = 0;
        ui.rewardsForToken = 0;
        ui.realizedRewards = 0;
    }

    function equalToken(address user) public view returns (uint) {
        UserInfo storage ui = userInfo[user];
        return ui.rewardsForToken * 1e18 / tokenPrice();
    }

    function rescueToken(address token, address to, uint amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function rescueETH(address to, uint amount) external onlyOwner {
        (bool success,) = address(to).call{value: amount}("");
        require(success);
    }

    function getUserStakeRecords(address user) public view returns (Record[10] memory) {
        return stakeRecord[user];
    }

    function equalTokenPerNFT() public view returns (uint) {
        return nftPrice * 1e18 / tokenPrice();
    }

    function mintNFT(uint num) external {
        require(msg.sender == tx.origin, "Only EOA allowed");
        require(msg.sender.code.length == 0);

        uint tokenAmount = num * equalTokenPerNFT();
        IERC20(TOKEN).transferFrom(msg.sender, tokenVault2, tokenAmount);
        _mintNft(msg.sender, num);
        userInfo[msg.sender].mintNftNums += num;

        Record memory record;
        record.time = block.timestamp;
        record.amount = num;
        uint index = lastNftIndex[msg.sender];
        nftRecord[msg.sender][index] = record;
        lastNftIndex[msg.sender]++;
        if (lastNftIndex[msg.sender] >= 10) {
            lastNftIndex[msg.sender] = 0;
        }
    }

    function getUserNftRecords(address user) public view returns (Record[10] memory) {
        return nftRecord[user];
    }

    function getUserNftBalance(address user) public view returns (uint) {
        uint all = 0;
        for (uint i; i < 5; i++) {
            all += INft(NFTS[i]).balanceOf(user);
        }
        return all;
    }
}