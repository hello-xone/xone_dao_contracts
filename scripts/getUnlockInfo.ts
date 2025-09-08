import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV10", "0x209313252543E499f4C30F4525Fe3F49397f039E");

    try {
        const unlockInfo = await daoLock.unlocks(8);
        console.log(`unlock info: ${unlockInfo}`);
    } catch (error) {
        console.error(`query failed:`, error);
    }
}

main()
    .then(() => {
        process.exit(0);
    })
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    });
