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

    function newMemoryMapping(bool sorted, bool overwrite) internal pure returns (MemoryMapping memory) {
        return MemoryMapping({sorted: sorted, overwrite: overwrite, totalKeys: 0, tree: newNode()});
    }

    function newMemoryMapping(bool sorted, bool overwrite, bytes32 key, bytes memory value)
        internal
        pure
        returns (MemoryMapping memory)
    {
        bytes32 ogKey = key;
        if (!sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        return MemoryMapping({
            sorted: sorted,
            overwrite: overwrite,
            totalKeys: 1,
            tree: newNode(uint256(key), uint256(ogKey), bytes(""), value)
        });
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        _add(mm, key, bytes(""), value);
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory bValue) internal pure {
        _add(mm, key, bytes(""), bValue);
    }

    function add(MemoryMapping memory mm, bytes memory bKey, bytes memory value) internal pure {
        _add(mm, keccak256(bKey), bKey, value);
    }

    function add(MemoryMapping memory mm, bytes memory bKey, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        _add(mm, keccak256(bKey), bKey, bValue);
    }

    function _add(MemoryMapping memory mm, bytes32 key, bytes memory bKey, bytes32 value) private pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        _add(mm, key, bKey, bValue);
    }

    function _add(MemoryMapping memory mm, bytes32 key, bytes memory bKey, bytes memory value) private pure {
        bytes32 ogKey = key;
        if (!mm.sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        bool existed = add(mm.tree, mm.overwrite, uint256(key), uint256(ogKey), bKey, value);
        if (!existed) ++mm.totalKeys;
    }

    function get(MemoryMapping memory mm, bytes32 key) internal pure returns (bool ok, bytes memory ret) {
        if (!mm.sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        Tree memory node = get(mm.tree, uint256(key));
        if (node.exists) {
            ok = true;
            assembly {
                ret := mload(add(node, 0x80))
            }
        }
    }

    function get(MemoryMapping memory mm, bytes memory key) internal pure returns (bool ok, bytes memory ret) {
        return get(mm, keccak256(key));
    }

    function dumpKeys(MemoryMapping memory mm) internal pure returns (uint256[] memory keys) {
        keys = new uint256[](mm.totalKeys);
        assembly {
            mstore(keys, 0)
        }
        readInto(mm.tree, 0, keys);
    }

    function dumpKeyBytes(MemoryMapping memory mm) internal pure returns (bytes[] memory keys) {
        keys = new bytes[](mm.totalKeys);
        assembly {
            mstore(keys, 0)
        }
        readInto(mm.tree, 0, keys);
    }

    function dumpBytes(MemoryMapping memory mm) internal pure returns (uint256[] memory keys, bytes[] memory values) {
        keys = new uint256[](mm.totalKeys);
        values = new bytes[](mm.totalKeys);
        assembly {
            mstore(keys, 0)
            mstore(values, 0)
        }
        readInto(mm.tree, 0, keys, values);
    }

    function dumpBothBytes(MemoryMapping memory mm)
        internal
        pure
        returns (bytes[] memory keys, bytes[] memory values)
    {
        keys = new bytes[](mm.totalKeys);
        values = new bytes[](mm.totalKeys);
        assembly {
            mstore(keys, 0)
            mstore(values, 0)
        }
        readInto(mm.tree, 0, keys, values);
    }

    function dumpUint256s(MemoryMapping memory mm)
        internal
        pure
        returns (uint256[] memory keys, uint256[] memory values)
    {
        keys = new uint256[](mm.totalKeys);
        values = new uint256[](mm.totalKeys);
        assembly {
            mstore(keys, 0)
            mstore(values, 0)
        }
        readInto(mm.tree, 0, keys, values);
    }

    // Tree

    struct Tree {
        bool exists;
        uint256 key; // sort by key in descending order max -> min
        uint256 ogKey;
        bytes bKey;
        bytes payload; // optional arbitrary payload
        Tree[] neighbors; // 0-left, 1-right
    }

    function newNode() internal pure returns (Tree memory) {
        Tree memory tree;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function newNode(uint256 key, uint256 ogKey, bytes memory bKey, bytes memory payload)
        internal
        pure
        returns (Tree memory)
    {
        return Tree({exists: true, key: key, ogKey: ogKey, bKey: bKey, payload: payload, neighbors: new Tree[](2)});
    }

    function fillNode(Tree memory tree, uint256 key, uint256 ogKey, bytes memory bKey, bytes memory payload)
        internal
        pure
    {
        tree.exists = true;
        tree.key = key;
        tree.ogKey = ogKey;
        tree.bKey = bKey;
        tree.payload = payload;
    }

    function add(Tree memory tree, bool overwrite, uint256 key, uint256 ogKey, bytes memory bKey, bytes memory payload)
        internal
        pure
        returns (bool existed)
    {
        if (!tree.exists) {
            fillNode(tree, key, ogKey, bKey, payload);
            return false;
        }
        uint256 idx;
        if (key == tree.key) {
            if (overwrite) {
                tree.payload = payload;
            }
            return true;
        }

        if (tree.key > key) idx = 1;
        if (tree.neighbors[idx].exists) {
            return add(tree.neighbors[idx], overwrite, key, ogKey, bKey, payload);
        }
        tree.neighbors[idx] = newNode(key, ogKey, bKey, payload);
        return false;
    }

    function get(Tree memory tree, uint256 key) internal pure returns (Tree memory) {
        if (tree.exists) {
            uint256 _key = tree.key;
            if (_key < key) {
                return get(tree.neighbors[0], key);
            } else if (_key > key) {
                return get(tree.neighbors[1], key);
            }
        } // else dne
        return tree;
    }

    function readInto(Tree memory tree, uint256 idx, uint256[] memory arrayA) internal pure returns (uint256) {
        Tree memory other = tree.neighbors[0];
        if (other.exists) idx = readInto(other, idx, arrayA); // left
        // center

        // assembly does this:

        //arrayA[idx++] = tree.key;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(arrayA, add(mload(arrayA), 1))

            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA); // right
        return idx;
    }

    function readInto(Tree memory tree, uint256 idx, bytes[] memory arrayA) internal pure returns (uint256) {
        Tree memory other = tree.neighbors[0];
        if (other.exists) idx = readInto(other, idx, arrayA); // left
        // center

        // assembly does this:

        //arrayA[idx++] = tree.key;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(arrayA, add(mload(arrayA), 1))

            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x60)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA); // right
        return idx;
    }

    function readInto(Tree memory tree, uint256 idx, uint256[] memory arrayA, bytes[] memory arrayB)
        internal
        pure
        returns (uint256)
    {
        Tree memory other = tree.neighbors[0];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // left
        // center

        // assembly does this:

        //arrayA[idx] = tree.key;
        //arrayB[idx++] = tree.payload;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(arrayA, add(mload(arrayA), 1))
            mstore(arrayB, add(mload(arrayB), 1))

            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x80)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // right
        return idx;
    }

    function readInto(Tree memory tree, uint256 idx, bytes[] memory arrayA, bytes[] memory arrayB)
        internal
        pure
        returns (uint256)
    {
        Tree memory other = tree.neighbors[0];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // left
        // center

        // assembly does this:

        //arrayA[idx] = tree.key;
        //arrayB[idx++] = tree.payload;

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(arrayA, add(mload(arrayA), 1))
            mstore(arrayB, add(mload(arrayB), 1))

            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x60)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x80)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // right
        return idx;
    }

    function readInto(Tree memory tree, uint256 idx, uint256[] memory arrayA, uint256[] memory arrayB)
        internal
        pure
        returns (uint256)
    {
        Tree memory other = tree.neighbors[0];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // left
        // center

        // assembly does this:

        //arrayA[idx] = tree.key;
        //arrayB[idx++] = abi.decode(tree.payload, (uint256));

        assembly {
            // assumes arrays come in allocated BUT have their length initialized to 0 so will know how many added
            mstore(arrayA, add(mload(arrayA), 1))
            mstore(arrayB, add(mload(arrayB), 1))

            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(mload(add(tree, 0x80)), 0x20)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // right
        return idx;
    }
}
