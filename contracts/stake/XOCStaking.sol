// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IxXOC {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title XOC Staking Contract
 * @dev Contract for staking native XOC tokens and minting xXOC tokens
 */
contract XOCStaking is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    // Staking periods and their corresponding multipliers (scaled by 1000)
    struct StakingTier {
        uint256 duration; // Duration in seconds
        uint256 multiplier; // Multiplier scaled by 1000 (e.g., 1300 = 1.3x)
    }

    struct StakeInfo {
        uint256 amount; // Amount of XOC staked
        uint256 xXOCAmount; // Amount of xXOC tokens earned but not yet claimed
        uint256 stakingTime; // When the stake was created
        uint256 duration; // Staking duration in seconds
        uint256 multiplier; // Multiplier used for this stake
        bool active; // Whether the stake is active
    }

    // Contract state
    IxXOC public xXOCToken;

    // Staking tiers
    StakingTier[5] public stakingTiers;

    // User data
    mapping(address => uint256) public userxXOCBalance;
    mapping(address => StakeInfo[]) public userStakes;
    mapping(address => uint256) public lastStake365Time; // Track last 365-day stake time for each user

    // Events
    event Staked(
        address indexed user,
        uint256 stakeIndex,
        uint256 amount,
        uint256 duration,
        uint256 multiplier,
        uint256 xXOCEarned
    );
    event Unstaked(
        address indexed user,
        uint256 stakeIndex,
        uint256 xocAmount,
        uint256 xXOCBurned,
        bool fullUnstake
    );
    event EarlyUnstaked(
        address indexed user,
        uint256 stakeIndex,
        uint256 xocAmount,
        uint256 penalty,
        bool fullUnstake
    );
    event xXOCClaimed(address indexed user,  uint256[] stakeIndexes, uint256 amount);
    event RewardClaimed(address indexed signer, address indexed to, uint256 value, uint256 nonce);
    event UpdateStakingTierMultiplier(uint256[] tierIndexes, uint256[] newMultiplier);
    event UpdatexXOC(address indexed xXOC);

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract (replaces constructor for upgradeable contracts)
     * @param _xXOCToken Address of the xXOC token contract
     */
    function initialize(address _xXOCToken) public initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
        
        xXOCToken = IxXOC(_xXOCToken);

        // Initialize staking tiers
        stakingTiers[0] = StakingTier(0 days, 0); // 0 days, 0x multiplier ,not xXOC
        stakingTiers[1] = StakingTier(30 days, 1300); // 30 days, 1.3x multiplier
        stakingTiers[2] = StakingTier(90 days, 1900); // 90 days, 1.9x multiplier
        stakingTiers[3] = StakingTier(180 days, 3250); // 180 days, 3.25x multiplier
        stakingTiers[4] = StakingTier(365 days, 6475); // 365 days, 6.475x multiplier
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract.
     * Called by {upgradeTo} and {upgradeToAndCall}.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {
        require(newImplementation != address(0), "new implementation address is zero");
    }

    // modifier onlyOwner() {
    //     require(owner() == msg.sender, "Only owner can call this function");
    //     _;
    // }
    function setxXOCToken(address _xXOCToken) external onlyOwner {
        require(_xXOCToken != address(0), "Invalid xXOC token address");
        xXOCToken = IxXOC(_xXOCToken);

        emit UpdatexXOC(_xXOCToken);
    }

    function setStakingTiers(uint256[] calldata tierIndexes, uint256[] calldata newMultipliers) external onlyOwner {
        uint256 tierIndexLength = tierIndexes.length;
        require(tierIndexLength == newMultipliers.length, "Invalid input lengths");

        for (uint256 i = 0; i < tierIndexLength; i++) {
            uint256 tierIndex = tierIndexes[i];
            require(tierIndex < 5, "Invalid tier index");

            stakingTiers[tierIndex].multiplier = newMultipliers[i];
        }
        emit UpdateStakingTierMultiplier(tierIndexes, newMultipliers);
    }

    function getStakingTiers() external view returns (StakingTier[5] memory) {
        return stakingTiers;
    }

    /**
     * @dev Stake XOC tokens for a specific duration
     * @param tierIndex Index of the staking tier (0-3)
     */
    function stake(uint256 tierIndex) external payable {
        require(msg.value > 0, "Cannot stake 0 XOC");
        require(tierIndex < 5, "Invalid tier index");

        StakingTier memory tier = stakingTiers[tierIndex];
        uint256 xXOCAmount = (msg.value * tier.multiplier) / 1000;
        if (tierIndex == 0) {
           xXOCAmount = 0;
        }

        // Create stake record - xXOC is earned but not automatically minted
        StakeInfo memory newStake = StakeInfo({
            amount: msg.value,
            xXOCAmount: xXOCAmount,
            stakingTime: block.timestamp,
            duration: tier.duration,
            multiplier: tier.multiplier,
            active: true
        });
        userxXOCBalance[_msgSender()] += xXOCAmount;

        userStakes[_msgSender()].push(newStake);

        emit Staked(
            _msgSender(),
            userStakes[_msgSender()].length - 1,
            msg.value,
            tier.duration,
            tier.multiplier,
            xXOCAmount
        );
    }

    /**
     * @dev Unstake XOC tokens after the staking period has ended
     * @param stakeIndex Index of the stake to unstake
     * @param amount Amount of XOC to unstake (0 means unstake all)
     */
    function unstake(uint256 stakeIndex, uint256 amount) public {
        require(
            stakeIndex < userStakes[_msgSender()].length,
            "Invalid stake index"
        );

        StakeInfo storage stakeInfo = userStakes[_msgSender()][stakeIndex];
        require(stakeInfo.active, "Stake is not active");
        require(
            block.timestamp >= stakeInfo.stakingTime + stakeInfo.duration,
            "Staking period not ended"
        );

        // If amount is 0, unstake all
        uint256 unstakeAmount = amount == 0 ? stakeInfo.amount : amount;
        require(unstakeAmount > 0, "Cannot unstake 0 XOC");
        require(
            unstakeAmount <= stakeInfo.amount,
            "Insufficient staked amount"
        );

        stakeInfo.amount -= unstakeAmount;
        if (stakeInfo.amount == 0){
            stakeInfo.active = false;
        }

        uint256 xXOCToBurn = (stakeInfo.multiplier * unstakeAmount) / 1000;
        uint256 xXOCToSub = userxXOCBalance[_msgSender()] > xXOCToBurn ? xXOCToBurn : userxXOCBalance[_msgSender()];
        userxXOCBalance[_msgSender()] -= xXOCToSub;
        xXOCToBurn -= xXOCToSub;

        if (xXOCToBurn > 0){
            xXOCToken.burn(_msgSender(), xXOCToBurn);
        }
        // Return staked XOC
        (bool success, ) = _msgSender().call{value: unstakeAmount}("");
        require(success, "Transfer failed");

        emit Unstaked(
            _msgSender(),
            stakeIndex,
            unstakeAmount,
            xXOCToSub,
            stakeInfo.active == false
        );
    }

    function unstakeMultiple(uint256[] calldata stakeIndexes, uint256 amount) external {
        uint256 stakeIndexLength = stakeIndexes.length;
        require(
            stakeIndexLength > 0,
            "Must provide at least one stake index"
        );

        StakeInfo[] storage stakes = userStakes[_msgSender()];
        uint256 totalUnstaked = 0;
        for (uint256 i = 0; i < stakeIndexLength; i++) {
            uint256 stakeIndex = stakeIndexes[i];
            StakeInfo storage stakeInfo = stakes[stakeIndex];
            if (!stakeInfo.active || stakeInfo.amount == 0) continue;

            uint256 unstakeAmount = amount == 0
                ? stakeInfo.amount
                : amount - totalUnstaked;

            unstakeAmount = unstakeAmount > stakeInfo.amount
                ? stakeInfo.amount
                : unstakeAmount;

            if (unstakeAmount > 0) {
                unstake(stakeIndex, unstakeAmount);
                totalUnstaked += unstakeAmount;
            }

            if (totalUnstaked >= amount) break;
        }

        require(totalUnstaked > 0, "No XOC to unstake");
    }

    /**
     * @dev Claim earned xXOC tokens from stakes
     * @param stakeIndexes Array of stake indexes to claim xXOC from
     */
    function claimxXOC(uint256[] calldata stakeIndexes) external {
        uint256 totalxXOCToClaim = userxXOCBalance[_msgSender()];
        require(totalxXOCToClaim > 0, "No xXOC to claim");

        userxXOCBalance[_msgSender()] = 0;
        for(uint i = 0; i < stakeIndexes.length; i++) {
            uint256 stakeIndex = stakeIndexes[i];
            require(
                stakeIndex < userStakes[_msgSender()].length,
                "Invalid stake index"
            );
            StakeInfo storage stakeInfo = userStakes[_msgSender()][stakeIndex];
            require(stakeInfo.active, "Stake is not active");
            stakeInfo.xXOCAmount = 0; // Reset xXOCAmount in each stake
        }

        // Mint xXOC tokens to user
        xXOCToken.mint(_msgSender(), totalxXOCToClaim);

        emit xXOCClaimed(_msgSender(), stakeIndexes, totalxXOCToClaim);
    }

    /**
     * @dev Get user's stake information
     * @param user Address of the user
     * @return Array of stake information
     */
    function getUserStakes(
        address user
    ) external view returns (StakeInfo[] memory) {
        return userStakes[user];
    }

    /**
     * @dev Get total claimable xXOC for a user
     * @param user Address of the user
     * @return Total xXOC amount that can be claimed
     */
    function getClaimablexXOC(address user) external view returns (uint256) {
        return userxXOCBalance[user];
    }

    /**
     * @dev Unstake all XOC tokens from a specific stake (convenience function)
     * @param stakeIndex Index of the stake to fully unstake
     */
    function unstakeAll(uint256 stakeIndex) external {
        unstake(stakeIndex, 0);
    }

    /**
     * @dev Get maximum unstakeable amount for a specific stake
     * @param user Address of the user
     * @param stakeIndex Index of the stake
     * @return Maximum amount that can be unstaked
     */
    function getUnstakeableAmount(
        address user,
        uint256 stakeIndex
    ) external view returns (uint256) {
        require(stakeIndex < userStakes[user].length, "Invalid stake index");
        StakeInfo memory stakeInfo = userStakes[user][stakeIndex];

        return stakeInfo.amount;
    }

    /**
     * @dev Emergency withdraw function (only owner)
     */
    function emergencyWithdraw() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev Transfer ownership
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        _transferOwnership(newOwner);
    }

    // Receive function to accept XOC deposits
    receive() external payable {}
}
