import type { HardhatUserConfig } from "hardhat/config";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from 'dotenv';

dotenv.config({ debug: false })

let real_accounts = undefined
if (process.env.DEPLOYER_KEY) {
  const deployer = process.env.DEPLOYER_KEY
  const owner = process.env.OWNER_KEY || deployer

  real_accounts = [
    deployer,
    owner,
  ]
}
const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.22",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      }
    ]
  },
  ignition: {
    requiredConfirmations: 1
  },
  networks: {
    xonetest: {
      url: `https://rpc-testnet.xone.plus`,
      chainId: 33772211,
      accounts: real_accounts
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  etherscan: {
    apiKey: {
      'xonetest': 'empty'
    },
    customChains: [
      {
        network: "xonetest",
        chainId: 33772211,
        urls: {
          apiURL: "https://testnet-dev.xscscan.com/api",
          browserURL: "https://testnet-dev.xscscan.com"
        }
      }
    ]
  }
};

export default config;
