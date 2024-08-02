// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library MemoryMappings {
    struct MemoryMapping {
        bool sorted; // more efficient read/write when NOT sorted
        Tree tree;
    }

    function newMemoryMapping(bool sorted) internal pure returns (MemoryMapping memory) {
        return MemoryMapping({sorted: sorted, tree: newNode()});
    }

    function newMemoryMapping(bool sorted, bytes32 key, bytes memory value)
        internal
        pure
        returns (MemoryMapping memory)
    {
        if (!sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        return MemoryMapping({sorted: sorted, tree: newNode(uint256(key), value)});
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        if (!mm.sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        add(mm.tree, uint256(key), bValue);
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes memory value) internal pure {
        add(mm, keccak256(key), value);
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory value) internal pure {
        if (!mm.sorted) {
            assembly {
                mstore(0x0, key)
                key := keccak256(0x0, 0x20)
            }
        }
        add(mm.tree, uint256(key), value);
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        add(mm, keccak256(key), bValue);
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
                ret := mload(add(node, 0x40))
            }
        }
    }

    function get(MemoryMapping memory mm, bytes memory key) internal pure returns (bool ok, bytes memory ret) {
        return get(mm, keccak256(key));
    }

    // Tree

    struct Tree {
        bool exists;
        uint256 key; // sort by key in descending order max -> min
        bytes payload; // optional arbitrary payload
        Tree[] neighbors; // 0-left, 1-right
    }

    function newNode() internal pure returns (Tree memory) {
        Tree memory tree;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function newNode(uint256 key, bytes memory payload) internal pure returns (Tree memory) {
        return Tree({exists: true, key: key, payload: payload, neighbors: new Tree[](2)});
    }

    function fillNode(Tree memory tree, uint256 key, bytes memory payload) internal pure {
        tree.exists = true;
        tree.key = key;
        tree.payload = payload;
    }

    function add(Tree memory tree, uint256 key, bytes memory payload) internal pure {
        if (!tree.exists) {
            fillNode(tree, key, payload);
            return;
        }
        uint256 idx;
        if (tree.key > key) idx = 1;
        if (tree.neighbors[idx].exists) {
            add(tree.neighbors[idx], key, payload);
        } else {
            tree.neighbors[idx] = newNode(key, payload);
        }
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
            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x20)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))
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
            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x20)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(mload(add(tree, 0x40)), 0x20)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // right
        return idx;
    }
}
