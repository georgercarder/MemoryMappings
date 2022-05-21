//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./MemoryMappings.sol";
import "hardhat/console.sol";

contract TestMemoryMapping {
    using MemoryMappings for MemoryMappings.MemoryMapping;

    mapping(uint256 => uint256) public storageMapping;

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

    function testMem() external {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();
        uint256 key = 123;
        uint256 value = 42069; 
        mm.add(bytes32(key), bytes32(value));
        (bool ok, bytes memory result) = mm.get(bytes32(key));
        uint256 ret = ok ? uint256(abi.decode(result, (bytes32))) : 0;
        require(ret == value, "not same");
    }

    function testStorage() external {
        uint256 key = 123;
        uint256 value = 42069; 
        storageMapping[key] = value;
        uint256 ret = storageMapping[key];
        require(ret == value, "not same");
    }

    function testMemExtended(uint256 bound) external {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();
        uint256 key;
        uint256 value; 
        for (uint256 i; i<bound; ++i) {
            key = i;
            value = i*1000;
            mm.add(bytes32(key), bytes32(value));
            (bool ok, bytes memory result) = mm.get(bytes32(key));
            uint256 ret = ok ? uint256(abi.decode(result, (bytes32))) : 0;
            require(ret == value, "not same");
        }
    }

    function testStorageExtended(uint256 bound) external {
        uint256 key;
        uint256 value; 
        for (uint256 i; i<bound; ++i) {
            key = i;
            value = i*1000;
            storageMapping[key] = value;
            uint256 ret = storageMapping[key];
            require(ret == value, "not same");
        }
    }

    function testMemExtended2(uint256 bound) external {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();
        uint256 key;
        uint256 value; 
        for (uint256 i; i<bound; ++i) {
            key = i;
            value = i*1000;
            mm.add(bytes32(key), bytes32(value));
        }
        // read one value.
        key = 13;
        value = key*1000; // expected
        (bool ok, bytes memory result) = mm.get(bytes32(key));
        uint256 ret = ok ? uint256(abi.decode(result, (bytes32))) : 0;
        require(ret == value, "not same (mem)");
    }

    function testStorageExtended2(uint256 bound) external {
        uint256 key;
        uint256 value; 
        for (uint256 i; i<bound; ++i) {
            key = i;
            value = i*1000;
            storageMapping[key] = value;
        }
        // read one value.
        key = 13;
        value = key*1000; // expected
        uint256 ret = storageMapping[key];
        require(ret == value, "not same (storage)");
    }

}
