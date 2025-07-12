// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

library MemoryMappings2 {

    struct MemoryMapping2 {
        bool sorted; // more efficient read/write when NOT sorted
        // note sorted only for uint256/bytes32 NOT for bytes key
        bool overwrite;
        uint256 totalKeys;
        NewTree tree;
    }

    struct Tree2 {
        bytes32 sortingKey; 
        bytes32 key;
        bytes32 value;
        Tree2[] children;
    }

    function newMemoryMapping(bool sorted, bool overwrite) internal pure returns (MemoryMapping memory) {
        return MemoryMapping2({sorted: sorted, overwrite: overwrite, totalKeys: 0, tree: Tree2(0)});
    }

    function add(MemoryMapping2 memory mm, bytes32 key, bytes memory value) internal pure {
        bytes32 ogKey = key;
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, key)
                sortingKey := keccak256(0x0, 0x20) 
            }
        }
        bytes32 valuePtr;
        assembly {
            valuePtr := value
        }
        _add(mm.tree, mm.overwrite, sortingKey, key, valuePtr);
    }

    function _add(Tree2 memory tree, bool overwrite, bytes32 sortingKey, bytes32 key, bytes32 value) {
        Tree2 memory _tree = tree; 
        while(1) {
            if (_tree.sortingKey == sortingKey && overwrite) {
                _tree.value = value;
                return;
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
}
