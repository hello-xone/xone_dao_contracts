import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const xXOCModule = buildModule("xXOCModule", (m) => {
    // Deploy xXOC token contract
    const xXOCToken = m.contract("xXOC", []);

    return { xXOCToken };
});

export default xXOCModule;
