import hre from "hardhat";


async function main() {
    const stakingContract = await hre.ethers.getContractAt("XOCStaking", "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9");

    try {
        const tx = await stakingContract.stake(2, { value: hre.ethers.parseEther("3") });

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
