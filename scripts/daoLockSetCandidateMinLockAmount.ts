import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV12", "0x209313252543E499f4C30F4525Fe3F49397f039E");
    const unlockDuration = await daoLock.candidateMinLockAmount();
    console.log(`current unlock duration: ${unlockDuration}`);

    try {
        const tx = await daoLock.setUnlockDuration(60 * 60);

        console.log(`transaction submitted! tx hash: ${tx.hash}`)

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
