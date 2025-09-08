import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import xXOCModule from "./xXOC";

const XOCStakingUpgradeableModule = buildModule("XOCStakingUpgradeableModule", (m) => {
    // Import xXOC token from the previous module
    const { xXOCToken } = m.useModule(xXOCModule);

    // Deploy the implementation contract
    const xocStakingImpl = m.contract("XOCStaking", [], {
        after: [xXOCToken],
    });

    const initialize = m.encodeFunctionCall(xocStakingImpl, 'initialize', [
        xXOCToken
    ]);

    const xocStakingProxy = m.contract("ERC1967Proxy", [
        xocStakingImpl,
        initialize,
    ], {
        id: "XOCStakingProxy",
        after: [xocStakingImpl],
    });

    return { xocStakingImpl, xocStakingProxy };
});

export default XOCStakingUpgradeableModule;
