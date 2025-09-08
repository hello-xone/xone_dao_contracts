import hre from "hardhat";

async function main() {
    const xXOCToken = await hre.ethers.getContractAt("xXOC", "0x11C0A07fba01b20F288423f5d4DF2712Dff6D73f");


    try {
        const tx = await xXOCToken.mint("0x41616A456f1C5E3Ad8e5b7375fB2a8eD28D3A8eE", hre.ethers.parseEther("1000000000"));
        console.log(`transaction submitted! tx hash: ${tx.hash}`);

        const balance = await xXOCToken.balanceOf("0x41616A456f1C5E3Ad8e5b7375fB2a8eD28D3A8eE");
        console.log(`current xXOC balance: ${hre.ethers.formatEther(balance)} xXOC`);

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
