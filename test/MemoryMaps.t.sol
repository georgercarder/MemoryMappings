// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "../src/MemoryMappings.sol";

contract MemoryMapsTest is Test {
    function setUp() public {}

    uint256 public bound = 100;

    function test_benchmark_words() public {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping({sorted: true, overwrite: false});

        uint256 gasTotal;
        uint256 gasBefore;
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 value = keccak256(abi.encode(key));
            gasBefore = gasleft();
            MemoryMappings.add(mm, key, value);
            gasTotal += gasBefore - gasleft();
            //console.log(uint256(key), uint256(value));
        }
        console.log("%d gas total", gasTotal);
        console.log("%d gas per add", gasTotal / bound);
        uint256[] memory arrA = new uint256[](bound);
        uint256[] memory arrB = new uint256[](bound);

        gasBefore = gasleft();
        MemoryMappings.readInto(mm.tree, 0, arrA, arrB);
        gasTotal = gasBefore - gasleft();
        console.log("%d readInto gas", gasTotal);
        console.log("%d readInto per elt", gasTotal / bound);

        /*
        console.log("--");
        for (uint256 i; i < bound; ++i) {
            console.log(uint256(arrA[i]), uint256(arrB[i]));
        }
        console.log("--");
       */

        for (uint256 i; i < bound; ++i) {
            uint256 key = arrA[i];
            bytes32 value = keccak256(abi.encode(key));
            /*
            console.log(uint256(value));
            console.log(uint256(arrB[i]));
            console.log("--");
            */
            assertEq(bytes32(arrB[i]), value);
        }

        bool ok;
        bytes memory value;
        gasTotal = 0;
        uint256 max;
        uint256 min = type(uint256).max;
        uint256 gasUsed;
        //console.log("----");
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 expectedValue = keccak256(abi.encode(key));
            gasBefore = gasleft();
            (ok, value) = MemoryMappings.get(mm, key);
            gasUsed = gasBefore - gasleft();
            //console.log(uint256(key), uint256(expectedValue));
            //console.log(uint256(key), abi.decode(value, (uint256)));
            //console.log("%d gasUsed", gasUsed);
            gasTotal += gasUsed;
            //console.log("debug 0");
            assertEq(ok, true);
            //console.log("debug 1");
            if (gasUsed > max) max = gasUsed;
            if (gasUsed < min) min = gasUsed;
            assertEq(abi.decode(value, (bytes32)), expectedValue);
        }
        //console.log("----");
        console.log("%d get gas total", gasTotal);
        console.log("%d get gas avg", gasTotal / bound);
        console.log("%d gas max", max);
        console.log("%d gas min", min);

        bytes32[] memory keys = new bytes32[](bound);
        bytes32[] memory values = new bytes32[](bound);
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            keys[i] = key;
            bytes32 value = keccak256(abi.encode(key));
            values[i] = value;
        }
        // worst case linear search
        bytes32 searchTerm = keccak256(abi.encode(bound - 1));
        gasBefore = gasleft();
        bytes32 found;
        for (uint256 i; i < bound; ++i) {
            if (keys[i] == searchTerm) {
                found = values[i];
            }
        }
        console.log("%d ignorant linear search gas", gasBefore - gasleft());
    }

    function test_benchmark_bytes() public {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping({sorted: true, overwrite: false});

        uint256 gasTotal;
        uint256 gasBefore;
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            bytes memory value = bytes.concat(bytes("hello_cat??"), abi.encode(keccak256(abi.encode(i))));
            gasBefore = gasleft();
            MemoryMappings.add(mm, key, value);
            gasTotal += gasBefore - gasleft();
            //console.log(uint256(key), uint256(value));
        }
        console.log("%d gas total", gasTotal);
        console.log("%d gas per add", gasTotal / bound);
        uint256[] memory arrA = new uint256[](bound);
        bytes[] memory arrB = new bytes[](bound);

        gasBefore = gasleft();
        MemoryMappings.readInto(mm.tree, 0, arrA, arrB);
        gasTotal = gasBefore - gasleft();
        console.log("%d readInto gas", gasTotal);
        console.log("%d readInto per elt", gasTotal / bound);

        for (uint256 i; i < bound; ++i) {
            uint256 key = arrA[i];
            (bool ok, bytes memory expectedValue) = MemoryMappings.get(mm, bytes32(key));
            assertEq(keccak256(arrB[i]), keccak256(expectedValue));
        }

        bool ok;
        bytes memory value;
        gasTotal = 0;
        uint256 max;
        uint256 min = type(uint256).max;
        uint256 gasUsed;
        console.log("----");
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            bytes memory expectedValue = bytes.concat(bytes("hello_cat??"), abi.encode(keccak256(abi.encode(i))));
            gasBefore = gasleft();
            (ok, value) = MemoryMappings.get(mm, key);
            gasUsed = gasBefore - gasleft();
            //console.log("%d gasUsed", gasUsed);
            gasTotal += gasUsed;
            assertEq(ok, true);
            if (gasUsed > max) max = gasUsed;
            if (gasUsed < min) min = gasUsed;
            assertEq(keccak256(value), keccak256(expectedValue));
        }
        console.log("----");
        console.log("%d get gas total", gasTotal);
        console.log("%d get gas avg", gasTotal / bound);
        console.log("%d gas max", max);
        console.log("%d gas min", min);

        bytes32[] memory keys = new bytes32[](bound);
        bytes[] memory values = new bytes[](bound);
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            keys[i] = key;
            bytes memory value = bytes.concat(bytes("hello_"), abi.encode(keccak256("cat??")), abi.encode(i));
            values[i] = value;
        }
        // worst case linear search
        bytes32 searchTerm = keccak256(abi.encode(bound - 1));
        gasBefore = gasleft();
        bytes memory found;
        for (uint256 i; i < bound; ++i) {
            if (keys[i] == searchTerm) {
                found = values[i];
            }
        }
        console.log("%d ignorant linear search gas", gasBefore - gasleft());
    }
}
