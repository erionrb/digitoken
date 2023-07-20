import { ethers } from "hardhat";
import { AbiCoder, Wallet } from "ethers";
import { Digitoken } from "../typechain-types";

import dotenv from "dotenv";
dotenv.config();

const coder = AbiCoder.defaultAbiCoder();
const certificateURI = "" + process.env.CERTIFICATE_URI;

let digitoken: Digitoken;

const getSignedData = async (signer: Wallet, nonce?: number) => {
    const __nonce = nonce || 1;
    const url = certificateURI;
    const digest = ethers.keccak256(ethers.toUtf8Bytes(__nonce.toString()));
    const signature = ethers.hexlify(await signer.signMessage(ethers.getBytes(digest)));
    return { url, digest, signature, encoded: coder.encode(["string", "bytes32", "bytes"], [url, digest, signature]) };
};

const grantRole = async (role: string[], owner: Wallet, recipient: Wallet) => {
    for (let i = 0; i < role.length; i++) {
        await digitoken.connect(owner).grantRole(role[i], recipient.getAddress());
    }
};

const mint = async (owner: Wallet, minter: Wallet, recipient: Wallet, amount: bigint, nonce: number) => {
    const issuerData = await getSignedData(owner, nonce);
    return digitoken.connect(minter).issueByPartition(issuerData.digest, await recipient.getAddress(), amount, issuerData.encoded);
};

async function main() {
    // Wallets _______________________________________________________________
    const user1_pk = "" + process.env.USER1_PK;
    const user2_pk = "" + process.env.USER2_PK;
    const user3_pk = "" + process.env.USER3_PK;
    const owner_pk = "" + process.env.OWNER_PK;
    const minter_pk = "" + process.env.MINTER_PK;

    const user1 = new ethers.Wallet(user1_pk).connect(ethers.provider);
    const user2 = new ethers.Wallet(user2_pk).connect(ethers.provider);
    const user3 = new ethers.Wallet(user3_pk).connect(ethers.provider);
    const owner = new ethers.Wallet(owner_pk).connect(ethers.provider);
    const minter = new ethers.Wallet(minter_pk).connect(ethers.provider);

    // Deployment _____________________________________________________________
    const Digitoken = await ethers.getContractFactory("Digitoken");
    digitoken = (await Digitoken.connect(owner).deploy("Digitoken", "DTK", await owner.getAddress())) as Digitoken;
    await digitoken.waitForDeployment();

    console.log("Digitoken deployed to:", await digitoken.getAddress());

    // Roles _________________________________________________________________
    const WHITE_LISTED = await digitoken.WHITE_LISTED();
    const ADMIN = await digitoken.DEFAULT_ADMIN_ROLE();
    const MINTER = await digitoken.MINTER();
    const TRANSFER_AGENT = await digitoken.TRANSFER_AGENT();

    // Whitelist ______________________________________________________________
    const whitelistRole = [WHITE_LISTED, TRANSFER_AGENT];
    const minterRole = [MINTER, TRANSFER_AGENT];
    await grantRole(whitelistRole, owner, user1);
    await grantRole(whitelistRole, owner, user2);
    await grantRole(whitelistRole, owner, minter);
    await grantRole(minterRole, owner, minter);

    console.log(`\nDoes user1(${await user1.getAddress()}) has whitelisted? ${await digitoken.hasRole(WHITE_LISTED, await user1.getAddress())}`);
    console.log(`Does user2(${await user2.getAddress()}) has whitelisted? ${await digitoken.hasRole(WHITE_LISTED, await user2.getAddress())}`);
    console.log(`Does user3(${await user3.getAddress()}) has whitelisted? ${await digitoken.hasRole(WHITE_LISTED, await user3.getAddress())}`);

    // Mint _________________________________________________________________
    const amount = ethers.parseEther("1000000");
    let nonce = 0;
    await mint(owner, minter, user1, amount, nonce++);

    console.log(`\nBalance of user1(${await user1.getAddress()}) is ${ethers.formatEther(await digitoken.balanceOf(await user1.getAddress()))}`);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
