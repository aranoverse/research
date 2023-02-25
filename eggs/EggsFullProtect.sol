// SPDX-License-Identifier: MIT

// File: contracts/EggsFullProtec.sol

import "./lib/EggsFullProtectLib.sol";

pragma solidity ^0.8.0;

interface IEggsToken {
    function mint(address to, uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function transferUnderlying(address to, uint256 value) external returns (bool);
    function fragmentToEggs(uint256 value) external view returns (uint256);
    function eggsToFragment(uint256 eggs) external view returns (uint256);
    function balanceOfUnderlying(address who) external view returns (uint256);
    function burn(uint256 amount) external;
}

contract EggsFullProtec is Ownable {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 lockEndedTimestamp;
    }

    IEggsToken public eggs;
    uint256 public lockDuration;
    uint256 public totalStaked;
    bool public depositsEnabled;

    // Info of each user.
    mapping(address => UserInfo) public userInfo;

    // Events
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event LogSetLockDuration(uint256 lockDuration);
    event LogSetDepositsEnabled(bool enabled);

    constructor(IEggsToken _eggs, uint256 _lockDuration, bool _depositsEnabled) {
        eggs = _eggs;
        lockDuration = _lockDuration;
        depositsEnabled = _depositsEnabled;
    }

    function setDepositsEnabled(bool _enabled) external onlyOwner {
        depositsEnabled = _enabled;
        emit LogSetDepositsEnabled(_enabled);
    }

    function setLockDuration(uint256 _lockDuration) external onlyOwner {
      lockDuration = _lockDuration;
      emit LogSetLockDuration(_lockDuration );
    }

    function deposit(uint256 _amount) external {
        require(depositsEnabled, "deposits disabled");
        require(_amount > 0, "invalid amount");

        UserInfo storage user = userInfo[msg.sender];
        user.lockEndedTimestamp = block.timestamp + lockDuration;
        IERC20(address(eggs)).safeTransferFrom(address(msg.sender), address(this), _amount);
        eggs.burn(_amount);

        totalStaked += _amount;
        user.amount += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "invalid amount");

        UserInfo storage user = userInfo[msg.sender];
        require(user.lockEndedTimestamp <= block.timestamp, "still locked");
        require(user.amount >= _amount, "invalid amount");

        user.lockEndedTimestamp = block.timestamp + lockDuration;
        user.amount -= _amount;
        totalStaked -= _amount;
        eggs.mint(address(msg.sender), _amount);

        emit Withdraw(msg.sender, _amount);
    }
}