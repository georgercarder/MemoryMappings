// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

import "../src/MemoryMappings.sol";

import "lib/solady/src/utils/LibSort.sol";

contract MemoryMapsTest is Test {
    function setUp() public {}

    uint256 public bound = 100;

    function test_benchmark_words() public view {
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

        {
            bytes32 key = bytes32(uint256(42069));
            (bool ok, bytes32 value) = MemoryMappings.get(mm, key); // double checking getting nonexistant key will be !ok
            assertEq(ok, false);
        }

        gasBefore = gasleft();
        (bytes32[] memory keys, bytes32[] memory values) = MemoryMappings.dump(mm);
        gasTotal = gasBefore - gasleft();
        console.log("%d dump gas", gasTotal);
        console.log("%d dump per elt", gasTotal / bound);

        for (uint256 i; i < bound; ++i) {
            uint256 key = uint256(keys[i]);
            //console.log("%d key", key);
            bytes32 expected = keccak256(abi.encode(key));
            /*
            console.log(uint256(expected));
            console.log(uint256(values[i]));
            console.log("--");
            */
            assertEq(values[i], expected);
        }

        bool ok;
        bytes32 valuePtr;
        gasTotal = 0;
        uint256 max;
        uint256 min = type(uint256).max;
        uint256 gasUsed;
        //console.log("----");
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            bytes32 expectedValue = keccak256(abi.encode(key));
            gasBefore = gasleft();
            (ok, valuePtr) = MemoryMappings.get(mm, key);
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
            //console.log("%d valuePtr", uint256(valuePtr));
            assertEq(valuePtr, expectedValue);
        }
        //console.log("----");
        console.log("%d get gas total", gasTotal);
        console.log("%d get gas avg", gasTotal / bound);
        console.log("%d gas max", max);
        console.log("%d gas min", min);

        bytes32[] memory _keys = new bytes32[](bound);
        bytes32[] memory _values = new bytes32[](bound);
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            _keys[i] = key;
            bytes32 value = keccak256(abi.encode(key));
            _values[i] = value;
        }
        // worst case linear search
        bytes32 searchTerm = keccak256(abi.encode(bound - 1));
        gasBefore = gasleft();
        bytes32 found;
        for (uint256 i; i < bound; ++i) {
            if (_keys[i] == searchTerm) {
                found = _values[i];
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

        gasBefore = gasleft();
        (bytes32[] memory keys, bytes32[] memory valuePtrs) = MemoryMappings.dump(mm);
        bytes[] memory values;
        assembly {
            values := valuePtrs
        }
        gasTotal = gasBefore - gasleft();
        console.log("%d dumpBytes gas", gasTotal);
        console.log("%d dumpBytes per elt", gasTotal / bound);

        for (uint256 i; i < bound; ++i) {
            uint256 key = uint256(keys[i]);
            (bool ok, bytes32 expectedValuePtr) = MemoryMappings.get(mm, bytes32(key));
            bytes memory expectedValue;
            assembly {
                expectedValue := expectedValuePtr
            }
            assertEq(keccak256(values[i]), keccak256(expectedValue));
        }

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
            (bool ok, bytes32 valuePtr) = MemoryMappings.get(mm, key);
            assembly {
                value := valuePtr
            }
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

        bytes32[] memory _keys = new bytes32[](bound);
        bytes[] memory _values = new bytes[](bound);
        for (uint256 i; i < bound; ++i) {
            bytes32 key = keccak256(abi.encode(i));
            keys[i] = key;
            bytes memory _value = bytes.concat(bytes("hello_"), abi.encode(keccak256("cat??")), abi.encode(i));
            _values[i] = value;
        }
        // worst case linear search
        bytes32 searchTerm = keccak256(abi.encode(bound - 1));
        gasBefore = gasleft();
        bytes memory found;
        for (uint256 i; i < bound; ++i) {
            if (_keys[i] == searchTerm) {
                found = _values[i];
            }
        }
        console.log("%d ignorant linear search gas", gasBefore - gasleft());
    }

    function test_benchmark_bytes_bytes() public {
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping({sorted: false, overwrite: false});

        uint256 gasTotal;
        uint256 gasBefore;
        bytes memory key;
        bytes memory value;
        for (uint256 i; i < bound; ++i) {
            key = bytes.concat(bytes("hello_catKEY??"), abi.encode(keccak256(abi.encode(i))));
            value = bytes.concat(bytes("hello_cat??"), abi.encode(keccak256(abi.encode(i))));

            gasBefore = gasleft();
            MemoryMappings.add(mm, key, value);
            gasTotal += gasBefore - gasleft();
            //console.log(uint256(key), uint256(value));
        }
        console.log("%d gas total", gasTotal);
        console.log("%d gas per add", gasTotal / bound);

        {
            gasBefore = gasleft();
            (bytes32[] memory keyPtrs, bytes32[] memory valuePtrs) = MemoryMappings.dump(mm);
            bytes[] memory keys;
            bytes[] memory values;
            assembly {
                keys := keyPtrs
                values := valuePtrs
            }
            gasTotal = gasBefore - gasleft();
            console.log("%d dumpBothBytes gas", gasTotal);
            console.log("%d dumpBothBytes per elt", gasTotal / bound);

            for (uint256 i; i < bound; ++i) {
                bytes memory key = keys[i];
                //console.log(string(key));
                //console.log(string(values[i]));
                (bool ok, bytes32 expectedValuePtr) = MemoryMappings.get(mm, key);
                bytes memory expectedValue;
                assembly {
                    expectedValue := expectedValuePtr
                }
                assertEq(keccak256(values[i]), keccak256(expectedValue));
            }
        }

        gasTotal = 0;
        uint256 max;
        uint256 min = type(uint256).max;
        uint256 gasUsed;
        console.log("----");
        for (uint256 i; i < bound; ++i) {
            bytes memory key = bytes.concat(bytes("hello_catKEY??"), abi.encode(keccak256(abi.encode(i))));
            bytes memory expectedValue = bytes.concat(bytes("hello_cat??"), abi.encode(keccak256(abi.encode(i))));
            gasBefore = gasleft();
            (bool ok, bytes32 valuePtr) = MemoryMappings.get(mm, key);
            bytes memory value;
            assembly {
                value := valuePtr
            }
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

        bytes[] memory _keys = new bytes[](bound);
        bytes[] memory _values = new bytes[](bound);
        for (uint256 i; i < bound; ++i) {
            bytes memory key = bytes.concat(bytes("hello_catKEY??"), abi.encode(keccak256(abi.encode(i))));
            _keys[i] = key;
            bytes memory value = bytes.concat(bytes("hello_"), abi.encode(keccak256("cat??")), abi.encode(i));
            _values[i] = value;
        }
        // worst case linear search
        bytes memory searchTerm = bytes.concat(bytes("hello_catKEY??"), abi.encode(keccak256(abi.encode(bound - 1))));
        gasBefore = gasleft();
        bytes memory found;
        for (uint256 i; i < bound; ++i) {
            if (keccak256(_keys[i]) == keccak256(searchTerm)) {
                found = _values[i];
            }
        }
        console.log("%d ignorant linear search gas", gasBefore - gasleft());
    }
}
