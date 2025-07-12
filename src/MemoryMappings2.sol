// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

import "forge-std/console.sol"; // FIXME

library MemoryMappings2 {

    struct MemoryMapping2 {
        bool sorted; // more efficient read/write when NOT sorted
        // note sorted only for uint256/bytes32 NOT for bytes key
        bool overwrite;
        uint256 totalKeys;
        Tree2 tree;
    }

    struct Tree2 {
        bytes32 sortingKey; 
        bytes32 key;
        bytes32 value;
        Tree2[] children;
    }

    function newMemoryMapping(bool sorted, bool overwrite) internal pure returns (MemoryMapping2 memory) {
        Tree2 memory empty;
        return MemoryMapping2({sorted: sorted, overwrite: overwrite, totalKeys: 0, tree: empty});
    }

    function add(MemoryMapping2 memory mm, bytes32 key, bytes memory value) internal view {
        bytes32 ogKey = key;
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20) 
            }
        }
        bytes32 valuePtr;
        assembly {
            valuePtr := value
        }
        if (mm.totalKeys < 1) { // bootstrapping
            ++mm.totalKeys; 
            Tree2[] memory empty;
            mm.tree = Tree2(sortingKey, key, valuePtr, empty);
            return;
        }
        bool newValue = _add(mm.tree, mm.overwrite, sortingKey, key, valuePtr);
        if (newValue) ++mm.totalKeys;
    }

    function add(MemoryMapping2 memory mm, bytes32 key, bytes32 value) internal view {
        bytes32 ogKey = key;
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20) 
            }
        }
        if (mm.totalKeys < 1) { // bootstrapping
            ++mm.totalKeys; 
            Tree2[] memory empty;
            mm.tree = Tree2(sortingKey, key, value, empty);
            return;
        }
        bool newValue = _add(mm.tree, mm.overwrite, sortingKey, key, value);
        if (newValue) ++mm.totalKeys;
    }

    function get(MemoryMapping2 memory mm, bytes32 key) internal pure returns(bool ok, bytes32 value) {
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20) 
            }
        }
        return _get(mm.tree, sortingKey);
    }

    function dump(MemoryMapping2 memory mm) internal pure returns(bytes32[] memory keys, bytes32[] memory values) {
        return _dump(mm.tree, mm.totalKeys); 
    }

    function _add(Tree2 memory tree, bool overwrite, bytes32 sortingKey, bytes32 key, bytes32 value) private view returns(bool newValue) {
        Tree2 memory _tree = tree; 

        while(true) {
            if (_tree.sortingKey == sortingKey) {
                if (overwrite || _tree.value == bytes32(0)) {
                    _tree.value = value;
                }
                return overwrite;
            } 

            bool isNewNode = _tree.children.length < 1;
            if (isNewNode) {
                _tree.children = new Tree2[](2); 
            }

            if (sortingKey < _tree.sortingKey) { // FIXME could make this branchless
                _tree = _tree.children[0]; 
            } else {
                _tree = _tree.children[1]; 
            }

            if (isNewNode) {
                _tree.sortingKey = sortingKey;
                _tree.key = key;
            }
        }
    }

    function _get(Tree2 memory tree, bytes32 sortingKey) private pure returns(bool ok, bytes32 value) {
        Tree2 memory _tree = tree; 
        while(true) {
            if (_tree.sortingKey == sortingKey) {
                ok = true;
                value = _tree.value;
                return (ok, value);
            } 

            bool isNewNode = _tree.children.length < 1;
            if (isNewNode) {
                // ok = false;
                return (ok, value);
            }

            if (sortingKey < _tree.sortingKey) { // FIXME could make this branchless
                _tree = _tree.children[0]; 
            } else {
                _tree = _tree.children[1]; 
            }
        }
    }

    function _dump(Tree2 memory tree, uint256 totalKeys) private pure returns(bytes32[] memory keys, bytes32[] memory values) {
        keys = new bytes32[](totalKeys);
        values = new bytes32[](totalKeys);
        uint256 idx;

        /*
        Tree2 memory _tree = tree; 
        while(idx < totalKeys) {
            keys[idx] = _tree.key;
            values[idx++] = _tree.value;


            if (sortingKey < _tree.sortingKey) { // FIXME could make this branchless
                _tree = _tree.children[0]; 
            } else {
                _tree = _tree.children[1]; 
            }
        }
        */
    }
}
