import hre from "hardhat";

async function main() {
    const stakingContract = await hre.ethers.getContractAt("XOCStaking", "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9");

    try {
        const userStakes = await stakingContract.getUserStakes("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266");
        console.log("user stakes:", userStakes);

        // const tx = await stakingContract.unstakeMultiple([0, 1], hre.ethers.parseEther("3.5"));
        // console.log(`transaction submitted! tx hash: ${tx.hash}`);

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
