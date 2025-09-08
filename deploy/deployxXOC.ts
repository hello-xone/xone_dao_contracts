import { upgrades, ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    const xXOCFactory = await ethers.getContractFactory("xXOC");
    const xXOC = await xXOCFactory.deploy();

    const xXOCAddress = await xXOC.getAddress();

    console.log(`xXOC deployed at ${xXOCAddress}`);
};

main()
    .then(() => {
        process.exit(0);
    })
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    });