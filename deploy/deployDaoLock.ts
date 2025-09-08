import { upgrades, ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();

    const DAOLockFactory = await ethers.getContractFactory("DAOLock");
    const DAOLock = await upgrades.deployProxy(DAOLockFactory, ["0x5FbDB2315678afecb367f032d93F642f64180aa3"], { initializer: 'initialize' })

    const DAOLockAddress = await DAOLock.getAddress();

    console.log(`DAOLock deployed at ${DAOLockAddress}`);
};

main()
    .then(() => {
        process.exit(0);
    })
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    });