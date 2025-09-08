import { upgrades, ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    const XOCStakingFactory = await ethers.getContractFactory("XOCStaking");
    const XOCStaking = await upgrades.deployProxy(XOCStakingFactory, ["0x5FbDB2315678afecb367f032d93F642f64180aa3"], { initializer: 'initialize' })

    const XOCStakingAddress = await XOCStaking.getAddress();

    console.log(`XOCStaking deployed at ${XOCStakingAddress}`);
};

main()
    .then(() => {
        process.exit(0);
    })
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    });