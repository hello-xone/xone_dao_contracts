import hre from "hardhat";

async function main() {
    const stakingContract = await hre.ethers.getContractAt("XOCStaking", "0x0325145618a51a67b38CA408A36547765Cd6B2e8");
    try {
        const tx = await stakingContract.claimxXOC([0, 1]);

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
