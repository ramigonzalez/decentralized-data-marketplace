const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentralizedDataMarket", function () {
  async function deployContract() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();
    const DecentralizedDataMarket = await ethers.getContractFactory("DecentralizedDataMarket");
    const decentralizedDataMarket = await DecentralizedDataMarket.deploy();
    return { decentralizedDataMarket, owner, otherAccount };
  }

  describe.only("Deployment", async function () {
    before(function () {
      ethers.getDefaultProvider()
    });
    const tx = { value: ethers.parseEther("0.001") };
    describe("error scenarios", function () {
      it("Should fail if the address has no data provider role", async function () {
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        const DATA_PROVIDER_ROLE = await decentralizedDataMarket.DATA_PROVIDER_ROLE();
        await expect(decentralizedDataMarket.mintDataToken(
          "ipfshash1",
          1,
          tx
        )).to.be.revertedWithCustomError(decentralizedDataMarket, "AccessControlUnauthorizedAccount")
        .withArgs(owner.address, DATA_PROVIDER_ROLE);
      });
      it("Should fail if the value sent is less than mint fee", async function () {
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(owner.address);
        await expect(decentralizedDataMarket.mintDataToken(
          "abc",
          1,
          { value: ethers.parseEther("0.0009999") }
        )).to.be.revertedWith("Insufficient fee");
      });
      it("Should fail if the hash is empty", async function () {
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(owner.address);
        await expect(decentralizedDataMarket.mintDataToken(
          "",
          1,
          tx
        )).to.be.revertedWith("Invalid IPFS hash");
      });
    })
    describe("ok scenarios", function () {
      it("Should mint an a data asset", async function () {
        const TOKEN_COUNT = 1;
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(owner.address);
        await decentralizedDataMarket.mintDataToken("ipfshash1", 1, tx);
        expect(await decentralizedDataMarket.balanceOf(owner.address)).to.equal(TOKEN_COUNT);
        expect(await decentralizedDataMarket.tokenIdCounter()).to.equal(TOKEN_COUNT);
      });
  
      it("Should mint 2 data asset", async function () {
        const TOKEN_COUNT = 2;
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(owner.address);
        await decentralizedDataMarket.mintDataToken("ipfshash1", 1, tx);
        await decentralizedDataMarket.mintDataToken("ipfshash2", 2, tx);
        expect(await decentralizedDataMarket.balanceOf(owner.address)).to.equal(TOKEN_COUNT);
        expect(await decentralizedDataMarket.tokenIdCounter()).to.equal(TOKEN_COUNT);
      });

      it("Should change protocol owner balance on mintDataToken", async function () {
        const tokenCategory = 1;
        const ipfsHash = "ipfshash1";
        const { decentralizedDataMarket, owner, otherAccount } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(otherAccount.address);
        const mintFee = ethers.parseEther("0.001");
        await expect(decentralizedDataMarket.connect(otherAccount).mintDataToken(ipfsHash, tokenCategory, tx))
          .to.changeEtherBalances(
            [owner, otherAccount],
            [mintFee, -mintFee]
          );
      });

      it("Should emit an event on mintDataToken", async function () {
        const tokenId = 1;
        const tokenCategory = 1;
        const ipfsHash = "ipfshash1";
        const { decentralizedDataMarket, owner } = await loadFixture(deployContract);
        await decentralizedDataMarket.grantDataProviderRole(owner.address);
        await expect(decentralizedDataMarket.mintDataToken(ipfsHash, tokenCategory, tx))
          .to.emit(decentralizedDataMarket, "DataTokenCreated")
          .withArgs(tokenId, ipfsHash, tokenCategory, owner.address);
      });
    })
  });
});
