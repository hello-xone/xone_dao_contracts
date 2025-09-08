import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakingRewardModule = buildModule("StakingRewardModule", (m) => {

    // Deploy the implementation contract
    const StakingRewardImpl = m.contract("StakingReward", [], {
        id: "StakingRewardImpl",
    });

    const initialize = m.encodeFunctionCall(StakingRewardImpl, 'initialize', []);

    const StakingRewardProxy = m.contract("ERC1967Proxy", [
        StakingRewardImpl,
        initialize,
    ], {
        id: "StakingRewardProxy",
        after: [StakingRewardImpl],
    });

    const stakingReward = m.contractAt("StakingReward", StakingRewardProxy, {
        id: "StakingReward",
    });
    m.call(stakingReward, "setKeeper", [process.env.KEEPER_ADDRESS as string], {
        after: [StakingRewardProxy],
    });

    return { StakingRewardImpl, StakingRewardProxy };
});

export default StakingRewardModule;