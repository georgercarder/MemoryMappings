const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TestMemoryMapper", function () {
  it("Should run test without reverting", async function () {
    const TestMemoryMapping = await ethers.getContractFactory("TestMemoryMapping");
    const testMemoryMapping = await TestMemoryMapping.deploy();
    await testMemoryMapping.deployed();

    await testMemoryMapping.test();

    let tx = await testMemoryMapping.testMem();
    let receipt = await tx.wait()
    console.log("Gas used (mem test):", receipt.gasUsed.toString());
    let gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorage();
    receipt = await tx.wait()
    console.log("Gas used (storage test):", receipt.gasUsed.toString());
    let gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)
  });
});
