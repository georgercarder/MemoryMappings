const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TestMemoryMapper", function () {
  it("Should run test without reverting", async function () {
    const TestMemoryMapping = await ethers.getContractFactory("TestMemoryMapping");
    const testMemoryMapping = await TestMemoryMapping.deploy();
    await testMemoryMapping.deployed();

    await testMemoryMapping.test();
  });
});
