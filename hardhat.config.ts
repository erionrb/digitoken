import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY = "" + process.env.PRIVATE_KEY;
const MUMBAI_RPC = "" + process.env.MUMBAI_RPC;

const config: HardhatUserConfig = {
    solidity: "0.8.19",
    networks: {
        hardhat: {},
        mumbai: {
            url: MUMBAI_RPC,
            accounts: [PRIVATE_KEY],
        },
    },
};

export default config;
