//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MemoryMappings.sol";
import "hardhat/console.sol";

contract TestMemoryMapping {
    using MemoryMappings for MemoryMappings.MemoryMapping;

    constructor() {
    }

    function test() external view {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();
     
        string memory key = "hello";
        string memory value = "world";
        mm.add(bytes(key), bytes(value));
        (bool ok, bytes memory result) = mm.get(bytes(key));
        require(ok, "not ok");
        console.log(string(result));

        uint256 key2 = 123;
        uint256 dankness = 42069;
        mm.add(bytes32(key2), bytes32(dankness));
        (ok, result) = mm.get(bytes32(key2));
        require(ok, "not ok");
        bytes32 bRes = abi.decode(result, (bytes32));
        console.log(uint256(bRes));
        require(uint256(bRes) == dankness, "fail.");
    }
}
