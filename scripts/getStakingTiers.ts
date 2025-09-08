import hre from "hardhat";

async function main() {
    const stakingContract = await hre.ethers.getContractAt("XOCStakingV6", "0x0325145618a51a67b38CA408A36547765Cd6B2e8");
    try {
        const tiers = await stakingContract.getStakingTiers();

        console.log(tiers);
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
