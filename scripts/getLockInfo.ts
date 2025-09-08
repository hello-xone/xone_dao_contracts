import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV11", "0xDA9Cff45fc77F4faB5eeb77f35D9C741D0B245a8");

    try {
        const lockInfo = await daoLock.locks(63);
        console.log(`lock: ${lockInfo}`);
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
