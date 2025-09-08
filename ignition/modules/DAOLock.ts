import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import xXOCModule from "./xXOC";

const DAOLockModule = buildModule("DAOLockModule", (m) => {
    // Import xXOC token from the previous module
    const { xXOCToken } = m.useModule(xXOCModule);

    // Deploy the implementation contract
    const DAOLockImpl = m.contract("DAOLock", [], {
        after: [xXOCToken],
    });

    const initialize = m.encodeFunctionCall(DAOLockImpl, 'initialize', [
        xXOCToken
    ]);

    const DAOLockProxy = m.contract("ERC1967Proxy", [
        DAOLockImpl,
        initialize,
    ], {
        id: "DAOLockProxy",
        after: [DAOLockImpl],
    });

    return { DAOLockImpl, DAOLockProxy };
});

export default DAOLockModule;