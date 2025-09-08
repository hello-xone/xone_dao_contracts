import hre from "hardhat";

async function main() {
    const XOCStakingV6 = await hre.ethers.getContractAt("XOCStaking", "0xa7e2a5ed339113f6640610eDC0f3d3BEbEB18146");
    try {
        const tx = await XOCStakingV6.owner();

        console.log(`owner: ${tx}`);
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
