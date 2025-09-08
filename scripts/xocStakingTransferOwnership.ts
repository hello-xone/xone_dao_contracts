import hre from "hardhat";

async function main() {
    const XOCStakingV6 = await hre.ethers.getContractAt("XOCStakingV6", "0xa7e2a5ed339113f6640610eDC0f3d3BEbEB18146");
    try {
        const tx = await XOCStakingV6.transferOwnership("0x052dc7fFdDdAb26D2851042eD4bE9FDc0B1Cdf64");

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
