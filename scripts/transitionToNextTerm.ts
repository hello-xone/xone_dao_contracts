import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV10", "0xDA9Cff45fc77F4faB5eeb77f35D9C741D0B245a8");

    try {
        const tx = await daoLock.transitionToNextTerm([], [9]);

        console.log(`transaction submitted! tx hash: ${tx.hash}`);
    } catch (error) {
        console.error(`transaction failed:`, error);
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
