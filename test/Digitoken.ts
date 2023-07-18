import { ethers } from "hardhat";
import { AbiCoder, BytesLike, encodeBytes32String } from "ethers";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Digitoken } from "../typechain-types";
const coder = AbiCoder.defaultAbiCoder();

describe("Digitoken", () => {
    let digitoken: Digitoken;

    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, minter: SignerWithAddress, transferAgent: SignerWithAddress, burner: SignerWithAddress;
    let ownerAddress: string, user1Address: string, user2Address: string, minterAddress: string, transferAgentAddress: string, burnerAddress: string;

    let WHITE_LISTED: BytesLike, ADMIN: BytesLike, MINTER: BytesLike, TRANSFER_AGENT: BytesLike;

    before(async () => {
        [owner, minter, transferAgent, burner, user1, user2] = await ethers.getSigners();
        ownerAddress = await owner.getAddress();
        user1Address = await user1.getAddress();
        user2Address = await user2.getAddress();
        minterAddress = await minter.getAddress();
        transferAgentAddress = await transferAgent.getAddress();
        burnerAddress = await burner.getAddress();

        const Digitoken = await ethers.getContractFactory("Digitoken");

        digitoken = (await Digitoken.deploy("Digitoken", "DTK", ownerAddress)) as Digitoken;
        await digitoken.waitForDeployment();

        WHITE_LISTED = await digitoken.WHITE_LISTED();
        ADMIN = await digitoken.DEFAULT_ADMIN_ROLE();
        MINTER = await digitoken.MINTER();
        TRANSFER_AGENT = await digitoken.TRANSFER_AGENT();
    });

    describe("Deployment", () => {
        it("should set the correct owner", async () => {
            const contractOwner = await digitoken.owner();
            expect(contractOwner).to.equal(await owner.getAddress());
        });

        it("should whitelist & admin the owner", async () => {
            const isAdminRole = await digitoken.connect(owner).hasRole(ADMIN, await ownerAddress);
            const isWhitelisted = await digitoken.connect(owner).hasRole(WHITE_LISTED, owner);
            expect(isWhitelisted, "Owner is not WHITELISTED").to.be.true;
            expect(isAdminRole, "Owner is not ADMIM").to.be.true;
        });
    });

    describe("Role Access", () => {
        it("should allow admin to whitelist a user1", async () => {
            expect(await digitoken.connect(owner).hasRole(ADMIN, owner), `owner[${ownerAddress}] is not ADMIN`).to.be.true;
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, owner), `owner[${ownerAddress}] is not WHITELISTED`).to.be.true;
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, user1), `user1[${user1Address}] is WHITELISTED`).to.be.false;

            await digitoken.connect(owner).grantRole(WHITE_LISTED, user1Address);
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, user1), `user1[${user1Address}] has not WHITELISTED by owner[${ownerAddress}]`).to.be.true;
        });

        it("should allow admin to whitelist a user2", async () => {
            expect(await digitoken.connect(owner).hasRole(ADMIN, owner), `owner[${ownerAddress}] is not ADMIN`).to.be.true;
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, owner), `owner[${ownerAddress}] is not WHITELISTED`).to.be.true;
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, user2), `user2[${user2Address}] is WHITELISTED`).to.be.false;

            await digitoken.connect(owner).grantRole(WHITE_LISTED, user2Address);
            expect(await digitoken.connect(owner).hasRole(WHITE_LISTED, user2), `user2[${user2Address}] has not WHITELISTED by owner[${ownerAddress}]`).to.be.true;
        });
    });

    describe("Mint", () => {
        it("should not allow minter to mint tokens when not whitelisted yet", async () => {
            const amount = ethers.parseEther("100");

            expect(await digitoken.connect(minter).hasRole(MINTER, minter), `minter[${minterAddress}] is MINTER`).to.be.false;

            await digitoken.connect(owner).grantRole(MINTER, minterAddress);

            const message = "Mint certificate";
            const digest = ethers.keccak256(ethers.toUtf8Bytes(message));
            const signature = await owner.signMessage(ethers.getBytes(digest));

            const certificate = {
                url: "https://example.com/mint-certificate/384734785-fdg1",
                digest,
                signature: ethers.hexlify(signature),
            };
            const data = coder.encode(["string", "bytes32", "bytes"], [certificate.url, certificate.digest, certificate.signature]);

            await expect(digitoken.connect(minter).issueByPartition(certificate.digest, user1Address, amount, data)).to.be.revertedWith("Sender has not whitelisted");
        });

        it("should allow minter to mint tokens", async () => {
            const amount = ethers.parseEther("100");

            await digitoken.connect(owner).grantRole(MINTER, minterAddress);
            await digitoken.connect(owner).grantRole(WHITE_LISTED, minterAddress);
            await digitoken.connect(owner).grantRole(TRANSFER_AGENT, minterAddress);

            await digitoken.connect(owner).grantRole(WHITE_LISTED, user1Address);
            await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user1Address);

            const message = "Mint certificate";
            const digest = ethers.keccak256(ethers.toUtf8Bytes(message));
            const signature = await owner.signMessage(ethers.getBytes(digest));

            const certificate = {
                url: "https://example.com/mint-certificate/384734785-fdg1",
                digest,
                signature: ethers.hexlify(signature),
            };
            const data = coder.encode(["string", "bytes32", "bytes"], [certificate.url, certificate.digest, certificate.signature]);

            await digitoken.connect(minter).issueByPartition(certificate.digest, user1Address, amount, data);

            expect(await digitoken.balanceOf(user1Address)).to.equal(amount);
        });
    });

    describe("Transfer", () => {
        before(async () => {
            await digitoken.connect(owner).revokeRole(WHITE_LISTED, user1Address);
            await digitoken.connect(owner).revokeRole(WHITE_LISTED, user2Address);

            await digitoken.connect(owner).revokeRole(TRANSFER_AGENT, user1Address);
            await digitoken.connect(owner).revokeRole(TRANSFER_AGENT, user2Address);
        });

        it("should not allow transfer when Recipient not whitelisted yet", async () => {
            const amount = ethers.parseEther("100");
            await expect(digitoken.connect(user1).transfer(user2Address, amount)).to.be.revertedWith("Recipient has not whitelisted");
        });

        it("should not allow transfer when Sender not whitelisted yet", async () => {
            const amount = ethers.parseEther("100");
            await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user2Address);
            await digitoken.connect(owner).grantRole(WHITE_LISTED, user2Address);

            await expect(digitoken.connect(user1).transfer(user2Address, amount)).to.be.revertedWith("Sender has not whitelisted");
        });

        it("should transfer when Sender & Reciver are whitelisted", async () => {
            const amount = ethers.parseEther("100");
            await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user1Address);
            await digitoken.connect(owner).grantRole(WHITE_LISTED, user1Address);

            await digitoken.connect(user1).transfer(user2Address, amount);
            expect(await digitoken.balanceOf(user1Address)).to.equal(ethers.parseEther("0"));
            expect(await digitoken.balanceOf(user2Address)).to.equal(amount);
        });
    });
});
