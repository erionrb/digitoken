import { ethers } from "hardhat";
import { AbiCoder, BytesLike } from "ethers";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import { Digitoken } from "../typechain-types";
const coder = AbiCoder.defaultAbiCoder();

let _nonce: number = 0;
const getNewNonce = () => {
    _nonce += 1;
    return _nonce;
};

const getCurrentNonce = () => {
    return _nonce;
};

const getSignedData = async (signer: SignerWithAddress, nonce?: number) => {
    const __nonce = nonce || getNewNonce();
    const url = "https://example.com/mint-certificate/384734785-fdg1";
    const digest = ethers.keccak256(ethers.toUtf8Bytes(__nonce.toString()));
    const signature = ethers.hexlify(await signer.signMessage(ethers.getBytes(digest)));
    return { url, digest, signature, encoded: coder.encode(["string", "bytes32", "bytes"], [url, digest, signature]) };
};

describe("Digitoken", () => {
    let digitoken: Digitoken;

    let owner: SignerWithAddress, user1: SignerWithAddress, user2: SignerWithAddress, minter: SignerWithAddress, transferAgent: SignerWithAddress, burner: SignerWithAddress;
    let ownerAddress: string, user1Address: string, user2Address: string, minterAddress: string, transferAgentAddress: string, burnerAddress: string;

    let WHITE_LISTED: BytesLike, ADMIN: BytesLike, MINTER: BytesLike, TRANSFER_AGENT: BytesLike;

    describe("Deployment", () => {
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

                const issuerData = await getSignedData(owner, 1);
                await expect(digitoken.connect(minter).issueByPartition(issuerData.digest, user1Address, amount, issuerData.encoded)).to.be.revertedWith("Digitoken: Sender has not whitelisted");
            });

            it("should not mint when signature has different signer", async () => {
                const amount = ethers.parseEther("100");

                await digitoken.connect(owner).grantRole(MINTER, minterAddress);
                await digitoken.connect(owner).grantRole(WHITE_LISTED, minterAddress);
                await digitoken.connect(owner).grantRole(TRANSFER_AGENT, minterAddress);

                await digitoken.connect(owner).grantRole(WHITE_LISTED, user1Address);
                await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user1Address);

                const issuerData = await getSignedData(user1, 1);
                await expect(digitoken.connect(minter).issueByPartition(issuerData.digest, user1Address, amount, issuerData.encoded)).to.be.revertedWith("Digitoken: Invalid certificate signer");
            });

            it("should not mint when nonce is incorrect", async () => {
                const amount = ethers.parseEther("100");

                const issuerData = await getSignedData(owner, 10);
                await expect(digitoken.connect(minter).issueByPartition(issuerData.digest, user1Address, amount, issuerData.encoded)).to.be.revertedWith("Digitoken: Invalid certificate signer");
            });

            it("should allow minter to mint tokens", async () => {
                const amount = ethers.parseEther("100");

                const issuerData = await getSignedData(owner);
                await digitoken.connect(minter).issueByPartition(issuerData.digest, user1Address, amount, issuerData.encoded);

                expect(await digitoken.balanceOf(user1Address)).to.equal(amount);
            });
        });

        describe("Burn", () => {
            it("should not allow burn when issuer signature failed", async () => {
                const amount = ethers.parseEther("10");

                const myNonce = getCurrentNonce() + 1;
                const holderData = await getSignedData(user1, myNonce);
                const issuerData = await getSignedData(user2, myNonce);

                await expect(digitoken.connect(owner).burn(user1Address, amount, holderData.encoded, issuerData.encoded)).to.be.revertedWith("Digitoken: Invalid certificate signer");
            });

            it("should not allow burn when holder signature failed", async () => {
                const amount = ethers.parseEther("10");

                const holderData = await getSignedData(user1, getCurrentNonce() + 2);
                const issuerData = await getSignedData(owner, getCurrentNonce() + 1);

                await expect(digitoken.connect(owner).burn(user1Address, amount, holderData.encoded, issuerData.encoded)).to.be.revertedWith("Digitoken: Invalid certificate signer");
            });

            it("should allow burn", async () => {
                const amount = ethers.parseEther("10");

                let issuerData = await getSignedData(owner);

                await digitoken.connect(minter).issueByPartition(issuerData.digest, user1Address, amount, issuerData.encoded);
                expect(await digitoken.balanceOf(user1Address)).to.equal(ethers.parseEther("110"));
                expect(await digitoken.balanceOfByPartition(issuerData.digest, user1Address)).to.equal(ethers.parseEther("10"));

                const myNonce = getNewNonce();
                const holderData = await getSignedData(user1, myNonce);
                issuerData = await getSignedData(owner, myNonce);

                await digitoken.connect(owner).burn(user1Address, amount, holderData.encoded, issuerData.encoded);
                expect(await digitoken.balanceOf(user1Address)).to.equal(ethers.parseEther("100"));
                expect(await digitoken.balanceOfByPartition(issuerData.digest, user1Address)).to.equal(ethers.parseEther("0"));
            });
        });

        describe("Transfer", () => {
            before(async () => {
                await digitoken.connect(owner).revokeRole(WHITE_LISTED, user1Address);
                await digitoken.connect(owner).revokeRole(WHITE_LISTED, user2Address);

                await digitoken.connect(owner).revokeRole(TRANSFER_AGENT, user1Address);
                await digitoken.connect(owner).revokeRole(TRANSFER_AGENT, user2Address);
            });

            it("should not allow transfer when Digitoken: Recipient not whitelisted yet", async () => {
                const amount = ethers.parseEther("100");
                await expect(digitoken.connect(user1).transfer(user2Address, amount)).to.be.revertedWith("Digitoken: Recipient has not whitelisted");
            });

            it("should not allow transfer when Digitoken: Sender not whitelisted yet", async () => {
                const amount = ethers.parseEther("100");
                await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user2Address);
                await digitoken.connect(owner).grantRole(WHITE_LISTED, user2Address);

                await expect(digitoken.connect(user1).transfer(user2Address, amount)).to.be.revertedWith("Digitoken: Sender has not whitelisted");
            });

            it("should transfer when Digitoken: Sender & Receiver are whitelisted", async () => {
                const amount = ethers.parseEther("100");
                await digitoken.connect(owner).grantRole(TRANSFER_AGENT, user1Address);
                await digitoken.connect(owner).grantRole(WHITE_LISTED, user1Address);

                await digitoken.connect(user1).transfer(user2Address, amount);
                expect(await digitoken.balanceOf(user1Address)).to.equal(ethers.parseEther("0"));
                expect(await digitoken.balanceOf(user2Address)).to.equal(amount);
            });
        });
    });
});
