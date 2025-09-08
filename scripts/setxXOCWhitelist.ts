import hre from "hardhat";

async function main() {
    const xXOCToken = await hre.ethers.getContractAt("xXOC", "0x5FbDB2315678afecb367f032d93F642f64180aa3");
    try {
        const tx = await xXOCToken.updateWhitelist("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266", true);

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
