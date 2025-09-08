import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("signature", function () {
    it("Should recover signer from signature", async function () {
        const [deployer, keeper, user] = await ethers.getSigners();

        const XOCStakingV3Factory = await ethers.getContractFactory("XOCStakingV3");
        const xocStakingV3 = await upgrades.deployProxy(XOCStakingV3Factory, [deployer.address], {
            initializer: "initialize",
        });
        await deployer.sendTransaction({
            to: await xocStakingV3.getAddress(),
            value: ethers.parseEther("10"),
        });

        await xocStakingV3.connect(deployer).setKeeper(keeper.address);

        const signData = {
            to: user.address,
            value: ethers.parseEther("1"),
            nonce: 1,
        };

        const CLAIM_REWARD_TYPEHASH = ethers.keccak256(
            ethers.toUtf8Bytes("ClaimReward(address to,uint256 value,uint256 nonce)")
        );
        console.log("CLAIM_REWARD_TYPEHASH", CLAIM_REWARD_TYPEHASH);

        const packedMsg = ethers.solidityPacked(
            ["bytes32", "address", "uint256", "uint256"],
            [CLAIM_REWARD_TYPEHASH, signData.to, signData.value, signData.nonce]
        )
        console.log("packed", packedMsg);

        const hash = ethers.keccak256(
            packedMsg
        );
        console.log("hash", hash);

        const signature = await keeper.signMessage(ethers.getBytes(hash));
        console.log("signature", signature);

        const tx = await xocStakingV3.connect(user).claimReward(signData, signature);
        await tx.wait();
    });
});