import hre from "hardhat";

async function main() {
    const stakeReward = await hre.ethers.getContractAt("StakingReward", "0xe0ce5A9966B468708B6078f054997b5E0425640C");

    const reward = await stakeReward.rewards("0x4f109d3826BD73048D55307D61391CEf6E710E85");
    console.log(`reward amount: ${hre.ethers.formatEther(reward)} ETH`);
    // try {
    //     const tx = await stakeReward.withdraw();

    //     console.log(`transaction submitted! tx hash: ${tx.hash}`);

    //     // await stakingContract.

    // } catch (error) {
    //     console.error(`transaction failed:`, error);
    // }
}

main()
    .then(() => {
        process.exit(0);
    })
    .catch((ex) => {
        console.error(ex);
        process.exit(1);
    });
