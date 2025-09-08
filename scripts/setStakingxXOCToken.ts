import hre from "hardhat";

async function main() {
    const XOCStakingV4 = await hre.ethers.getContractAt("XOCStakingV4", "0xaAE84C72fA112274540A94de0F58A1f1987c4728");
    try {
        const tx = await XOCStakingV4.setxXOCToken("0x11C0A07fba01b20F288423f5d4DF2712Dff6D73f");

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
