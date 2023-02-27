// SPDX-License-Identifier: MIT

import "./lib/EggChefLib.sol";

// File: contracts/EggChef.sol

pragma solidity ^0.8.0;

interface IUniswapPair {
    event Sync(uint112 reserve0, uint112 reserve1);

    function sync() external;
}

interface IEggsToken {
    function mint(address to, uint256 amount) external;

    function rebase(
        uint256 epoch,
        uint256 indexDelta,
        bool positive
    ) external returns (uint256);

    function totalSupply() external view returns (uint256);

    function transferUnderlying(address to, uint256 value)
        external
        returns (bool);

    function fragmentToEggs(uint256 value) external view returns (uint256);

    function eggsToFragment(uint256 eggs) external view returns (uint256);

    function balanceOfUnderlying(address who) external view returns (uint256);
}

contract EggChef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Address for address;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockEndedTimestamp;
        //
        //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRewardPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardBlock; // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share.
    }

    // EGGS
    IEggsToken public eggs;
    // EGGS LP address
    IUniswapPair public eggsLp;
    // EGGS tokens reward per block.
    uint256 public rewardPerBlock;
    // Compound ratio which is 0.001% (will be used to decrease supply)
    uint256 public compoundRatio = 1e13;
    // Start rebase from first Ethereum PoS block
    uint256 public lastBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // user's withdrawable rewards
    mapping(uint256 => mapping(address => uint256)) private userRewards;
    // Lock duration in seconds
    mapping(uint256 => uint256) public lockDurations;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when EGGS mining starts.
    uint256 public startBlock;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 amount);
    event LogRewardPerBlock(uint256 amount);
    event LogPoolAddition(
        uint256 indexed pid,
        uint256 allocPoint,
        IERC20 indexed lpToken
    );
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardBlock,
        uint256 lpSupply,
        uint256 accRewardPerShare
    );
    event LogSetLockDuration(uint256 indexed pid, uint256 lockDuration);

    constructor(
        IEggsToken _eggs,
        IUniswapPair _eggsLp,
        uint256 _rewardPerBlock,
        uint256 _startBlock
    ) Ownable() ReentrancyGuard() {
        eggs = _eggs;
        eggsLp = _eggsLp;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        lastBlock = _startBlock;
    }

    function pow(int128 x, uint256 n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt(1);
        while (n > 0) {
            if (n % 2 == 1) {
                r = ABDKMath64x64.mul(r, x);
                n -= 1;
            } else {
                x = ABDKMath64x64.mul(x, x);
                n /= 2;
            }
        }
    }

    function compound(
        uint256 principal,
        uint256 ratio,
        uint256 n
    ) public pure returns (uint256) {
        return
            ABDKMath64x64.mulu(
                pow(
                    ABDKMath64x64.add(
                        ABDKMath64x64.fromUInt(1),
                        ABDKMath64x64.divu(ratio, 10**18)
                    ),
                    n
                ),
                principal
            );
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setLockDuration(uint256 _pid, uint256 _lockDuration)
        external
        onlyOwner
    {
        lockDurations[_pid] = _lockDuration;
        emit LogSetLockDuration(_pid, _lockDuration);
    }

    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        massUpdatePools();
        rewardPerBlock = _rewardPerBlock;
        emit LogRewardPerBlock(_rewardPerBlock);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accRewardPerShare: 0
            })
        );

        emit LogPoolAddition(poolInfo.length - 1, _allocPoint, _lpToken);
    }

    // Update the given pool's EGGS allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogSetPool(_pid, _allocPoint);
    }

    // View function to see pending Eggs on frontend.
    function pendingReward(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (address(pool.lpToken) == address(eggs)) {
            lpSupply = eggs.balanceOfUnderlying(address(this));
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 eggsReward = ((block.number - pool.lastRewardBlock) *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (eggsReward * 1e12) / lpSupply;
        }
        return
            userRewards[_pid][_user] +
            (user.amount * accRewardPerShare) /
            1e12 -
            user.rewardDebt;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (address(pool.lpToken) == address(eggs)) {
            lpSupply = eggs.balanceOfUnderlying(address(this));
        }
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 eggsReward = ((block.number - pool.lastRewardBlock) *
            rewardPerBlock *
            pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare += (eggsReward * 1e12) / lpSupply;
        pool.lastRewardBlock = block.number;

        emit LogUpdatePool(
            _pid,
            pool.lastRewardBlock,
            lpSupply,
            pool.accRewardPerShare
        );
    }

    // Deposit tokens to EggsChef for EGGS allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, "invalid amount");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.lockEndedTimestamp = block.timestamp + lockDurations[_pid];
        updatePool(_pid);
        queueRewards(_pid, msg.sender);

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        emit Deposit(msg.sender, _pid, _amount);

        if (address(pool.lpToken) == address(eggs)) {
            _amount = eggs.fragmentToEggs(_amount);
        }

        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
    }

    // Withdraw tokens from EggChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_amount > 0, "invalid amount");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lockEndedTimestamp <= block.timestamp, "still locked");
        require(user.amount >= _amount, "invalid amount");

        updatePool(_pid);
        queueRewards(_pid, msg.sender);

        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
        if (address(pool.lpToken) == address(eggs)) {
            _amount = eggs.eggsToFragment(_amount);
        }
        pool.lpToken.safeTransfer(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Claim EGGS from EggChef
    function claim(uint256 _pid, address _account) external nonReentrant {
        updatePool(_pid);
        queueRewards(_pid, _account);

        uint256 pending = userRewards[_pid][_account];
        require(pending > 0, "no pending rewards");

        UserInfo storage user = userInfo[_pid][msg.sender];
        user.lockEndedTimestamp = block.timestamp + lockDurations[_pid];

        userRewards[_pid][_account] = 0;
        userInfo[_pid][_account].rewardDebt =
            (userInfo[_pid][_account].amount *
                poolInfo[_pid].accRewardPerShare) /
            (1e12);

        eggs.mint(_account, pending);
        if (lastBlock != block.number) {
            eggs.rebase(
                block.number,
                compound(1e18, compoundRatio, block.number - lastBlock) - 1e18,
                false
            );
            lastBlock = block.number;
            eggsLp.sync();
        }
        emit RewardPaid(_account, _pid, pending);
    }

    // Queue rewards - increase pending rewards
    function queueRewards(uint256 _pid, address _account) internal {
        UserInfo memory user = userInfo[_pid][_account];
        uint256 pending = (user.amount * poolInfo[_pid].accRewardPerShare) /
            (1e12) -
            user.rewardDebt;
        if (pending > 0) {
            userRewards[_pid][_account] += pending;
        }
    }
}