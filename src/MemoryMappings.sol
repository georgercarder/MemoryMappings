// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

library MemoryMappings {
    struct MemoryMapping {
        bool sorted; // more efficient read/write when NOT sorted
        // note sorted only for uint256/bytes32 NOT for bytes key
        bool overwrite;
        uint256 totalKeys;
        Tree tree;
    }

    struct Tree {
        bool exists;
        bytes32 sortingKey;
        bytes32 key;
        bytes32 value;
        Tree[] children;
    }

    function newMemoryMapping(bool sorted, bool overwrite) internal pure returns (MemoryMapping memory) {
        Tree memory empty;
        return MemoryMapping({sorted: sorted, overwrite: overwrite, totalKeys: 0, tree: empty});
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory value) internal pure {
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20)
            }
        }
        _add(mm, sortingKey, key, value);
    }

    // note that won't be sorted if keys are bytes
    function add(MemoryMapping memory mm, bytes memory key, bytes memory value) internal pure {
        bytes32 keyHash = keccak256(abi.encode(key));
        bytes32 keyPtr;
        assembly {
            keyPtr := key
        }
        _add(mm, keyHash, keyPtr, value);
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20)
            }
        }
        if (mm.totalKeys < 1) {
            // bootstrapping
            ++mm.totalKeys;
            Tree[] memory children = new Tree[](2);
            mm.tree = Tree(true, sortingKey, key, value, children);
            return;
        }
        bool newValue = _add(mm.tree, mm.overwrite, sortingKey, key, value);
        if (newValue) ++mm.totalKeys;
    }

    function _add(MemoryMapping memory mm, bytes32 sortingKey, bytes32 key, bytes memory value) private pure {
        bytes32 valuePtr;
        assembly {
            valuePtr := value
        }
        if (mm.totalKeys < 1) {
            // bootstrapping
            ++mm.totalKeys;
            Tree[] memory children = new Tree[](2);
            mm.tree = Tree(true, sortingKey, key, valuePtr, children);
            return;
        }
        bool newValue = _add(mm.tree, mm.overwrite, sortingKey, key, valuePtr);
        if (newValue) ++mm.totalKeys;
    }

    function get(MemoryMapping memory mm, bytes32 key) internal pure returns (bool ok, bytes32 value) {
        bytes32 sortingKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, sortingKey)
                sortingKey := keccak256(0x0, 0x20)
            }
        }
        return _get(mm, sortingKey);
    }

    function get(MemoryMapping memory mm, bytes memory key) internal pure returns (bool ok, bytes32 value) {
        bytes32 keyHash = keccak256(abi.encode(key)); // FIXME need more efficient hash
        return _get(mm, keyHash);
    }

    function _get(MemoryMapping memory mm, bytes32 sortingKey) private pure returns (bool ok, bytes32 value) {
        return _get(mm.tree, sortingKey);
    }

    function dump(MemoryMapping memory mm) internal pure returns (bytes32[] memory keys, bytes32[] memory values) {
        keys = new bytes32[](mm.totalKeys);
        values = new bytes32[](mm.totalKeys);
        _dump(mm.tree, 0, keys, values);
    }

    function dumpKeys(MemoryMapping memory mm) internal pure returns (bytes32[] memory keys) {
        keys = new bytes32[](mm.totalKeys);
        _dumpKeys(mm.tree, 0, keys);
    }

    function dumpValues(MemoryMapping memory mm) internal pure returns (bytes32[] memory values) {
        values = new bytes32[](mm.totalKeys);
        _dumpValues(mm.tree, 0, values);
    }

    function _add(Tree memory tree, bool overwrite, bytes32 sortingKey, bytes32 key, bytes32 value)
        private
        pure
        returns (bool newValue)
    {
        Tree memory _tree = tree;

        while (true) {
            if (_tree.sortingKey == sortingKey) {
                newValue = !_tree.exists;
                if (overwrite || newValue) {
                    _tree.exists = true;
                    _tree.value = value;
                    _tree.children = new Tree[](2);
                    return newValue;
                }
                return newValue;
            }

            if (sortingKey < _tree.sortingKey) {
                // FIXME could make this branchless
                _tree = _tree.children[0];
            } else {
                _tree = _tree.children[1];
            }

            if (!_tree.exists) {
                _tree.sortingKey = sortingKey;
                _tree.key = key;
            }
        }
    }

    function _get(Tree memory tree, bytes32 sortingKey) private pure returns (bool ok, bytes32 value) {
        Tree memory _tree = tree;
        while (true) {
            if (_tree.sortingKey == sortingKey) {
                ok = true;
                value = _tree.value;
                return (ok, value);
            }

            //bool isNewNode = _tree.children.length < 1;
            if (_tree.children.length < 1) {
                // ok = false;
                return (ok, value);
            }

            if (sortingKey < _tree.sortingKey) {
                // FIXME could make this branchless
                _tree = _tree.children[0];
            } else {
                _tree = _tree.children[1];
            }
        }
    }

    function _dump(Tree memory tree, uint256 idx, bytes32[] memory keys, bytes32[] memory values)
        private
        pure
        returns (uint256)
    {
        Tree memory other = tree.children[0];
        if (other.exists) idx = _dump(other, idx, keys, values); // left
        // center

        // assembly does this:

        //keys[idx] = tree.key;
        //values[idx++] = tree.value;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(keys, add(mload(keys), 1))
            mstore(values, add(mload(values), 1))

            mstore(add(keys, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            mstore(add(values, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x60)))
            idx := add(idx, 1)
        }

        other = tree.children[1];
        if (other.exists) idx = _dump(other, idx, keys, values); // right
        return idx;
    }

    function _dumpKeys(Tree memory tree, uint256 idx, bytes32[] memory keys) private pure returns (uint256) {
        Tree memory other = tree.children[0];
        if (other.exists) idx = _dumpKeys(other, idx, keys); // left
        // center

        // assembly does this:

        //keys[idx] = tree.key;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(keys, add(mload(keys), 1))

            mstore(add(keys, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            idx := add(idx, 1)
        }

        other = tree.children[1];
        if (other.exists) idx = _dumpKeys(other, idx, keys); // right
        return idx;
    }

    function _dumpValues(Tree memory tree, uint256 idx, bytes32[] memory values) private pure returns (uint256) {
        Tree memory other = tree.children[0];
        if (other.exists) idx = _dumpValues(other, idx, values); // left
        // center

        // assembly does this:

        //values[idx++] = tree.value;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(values, add(mload(values), 1))

            mstore(add(values, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x60)))
            idx := add(idx, 1)
        }

        other = tree.children[1];
        if (other.exists) idx = _dumpValues(other, idx, values); // right
        return idx;
    }
}
