// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract StakingReward is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    event DistributeUserRewards(uint256 users, uint256 totalAmount);
    event Withdraw(address indexed user, uint256 amount);
    event SetKeeper(address indexed keeper, bool status);

    mapping(address => bool) public keepers;
    mapping(address => uint256) public rewards;
    
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {
        require(newImplementation != address(0), "new implementation address is zero");
    }

    function setKeeper(address keeper, bool status) external onlyOwner {
        keepers[keeper] = status;

        emit SetKeeper(keeper, status);
    }

    function distributeRewards(address[] calldata users, uint256[] calldata amounts) external payable{
        require(keepers[_msgSender()], "only keeper can distribute rewards");
        uint256 userLength = users.length;
        require(userLength == amounts.length, "users and amounts length not match");

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < userLength; i++) {
            rewards[users[i]] += amounts[i];
            totalAmount += amounts[i];
        }

        emit DistributeUserRewards(users.length, totalAmount);
    }

    function withdraw() external {
        uint256 amount = rewards[_msgSender()];
        require(amount > 0, "no rewards to withdraw");

        rewards[_msgSender()] = 0;

        (bool success, ) = _msgSender().call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(_msgSender(), amount);
    }

    function ownerWithdraw() external onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Transfer failed");
    }
}