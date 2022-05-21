const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TestMemoryMapper", function () {
  it("Should run test without reverting", async function () {
    const TestMemoryMapping = await ethers.getContractFactory("TestMemoryMapping");
    const testMemoryMapping = await TestMemoryMapping.deploy();
    await testMemoryMapping.deployed();

    await testMemoryMapping.test();
    console.log("single read/write")

    let tx = await testMemoryMapping.testMem();
    let receipt = await tx.wait()
    console.log("Gas used (mem test):", receipt.gasUsed.toString());
    let gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorage();
    receipt = await tx.wait()
    console.log("Gas used (storage test):", receipt.gasUsed.toString());
    let gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)

    console.log("\n\nMany read/writes \n\n");
    let bound = 20;
    let offset = 20;

    tx = await testMemoryMapping.testMemExtended(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (mem test extended ", bound,"):", receipt.gasUsed.toString());
    gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorageExtended(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (storage test extended ", bound,"):", receipt.gasUsed.toString());
    gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)

    console.log("\nthreshold\n")
    offset = bound*offset;
    bound = 60;
    tx = await testMemoryMapping.testMemExtended(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (mem test extended ", bound,"):", receipt.gasUsed.toString());
    gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorageExtended(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (storage test extended ", bound,"):", receipt.gasUsed.toString());
    gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)

    console.log("\n\nMany reads, single write \n\n");
    offset = bound*offset;
    bound = 20;

    tx = await testMemoryMapping.testMemExtended2(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (mem test extended2 ", bound,"):", receipt.gasUsed.toString());
    gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorageExtended2(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (storage test extended2 ", bound,"):", receipt.gasUsed.toString());
    gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)
    offset = bound*offset;
    bound = 150;
    console.log("\nthreshold\n")

    tx = await testMemoryMapping.testMemExtended2(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (mem test extended2 ", bound,"):", receipt.gasUsed.toString());
    gasMem = receipt.gasUsed;

    tx = await testMemoryMapping.testStorageExtended2(bound, offset);
    receipt = await tx.wait()
    console.log("Gas used (storage test extended2 ", bound,"):", receipt.gasUsed.toString());
    gasStorage = receipt.gasUsed;

    expect(gasMem.lt(gasStorage)).to.equal(true)
    
  });
});
