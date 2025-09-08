import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV11", "0x209313252543E499f4C30F4525Fe3F49397f039E");

    try {
        const candidateLockInfo = await daoLock.candidateLocks(10, 0);
        console.log(`candidate lock info:`, candidateLockInfo);
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
