import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

import xXOCModule from "./xXOC";
import XOCStakingUpgradeableModule from "./XOCStakingUpgradeable";
import DAOLockModule from "./DAOLock";

const DeploymentModule = buildModule("DeploymentModule", (m) => {
    // Use the XOC Staking module which includes xXOC token
    const { xXOCToken } = m.useModule(xXOCModule);

    const { xocStakingImpl, xocStakingProxy } = m.useModule(XOCStakingUpgradeableModule);
    // Set the staking contract address in xXOC token
    m.call(xXOCToken, "updateWhitelist", [xocStakingProxy, true], {
        id: "addStakingToWhitelist",
        after: [xocStakingProxy],
    });

    const { DAOLockImpl, DAOLockProxy } = m.useModule(DAOLockModule);
    m.call(xXOCToken, "updateWhitelist", [DAOLockProxy, true], {
        id: "addLockToWhitelist",
        after: [DAOLockProxy],
    });

    return {
        xXOCToken,
        xocStakingImpl, xocStakingProxy,
        DAOLockImpl, DAOLockProxy,
    };
});

export default DeploymentModule;
