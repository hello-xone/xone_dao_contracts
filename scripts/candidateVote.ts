import hre from "hardhat";

async function main() {
    const daoLock = await hre.ethers.getContractAt("DAOLockV10", "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");

    try {
        const tx = await daoLock.voteForCandidate(hre.ethers.parseEther("100"), 0);
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
