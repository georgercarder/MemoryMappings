// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.25;

library MemoryMappings {
    struct MemoryMapping {
        Tree tree;
    }

    function newMemoryMapping() internal pure returns (MemoryMapping memory) {
        return MemoryMapping({tree: newNode()});
    }

    function newMemoryMapping(bytes32 key, bytes memory value) internal pure returns (MemoryMapping memory) {
        return MemoryMapping({tree: newNode(uint256(key), value)});
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        assembly {
            mstore(0x00, key)
            key := keccak256(0x00, 0x20) // hash of key ensures tree is more balanced
        }
        add(mm.tree, uint256(key), bValue);
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes memory value) internal pure {
        add(mm, keccak256(key), value);
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory value) internal pure {
        assembly {
            mstore(0x00, key)
            key := keccak256(0x00, 0x20) // hash of key ensures tree is more balanced
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
        assembly {
            mstore(0x00, key)
            key := keccak256(0x00, 0x20) // recall, hash of key ensures tree is more balanced.. see add(..) above
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
        uint256 value; // sort by value in descending order max -> min
        bytes payload; // optional arbitrary payload
        Tree[] neighbors; // 0-left, 1-right
    }

    function newNode() internal pure returns (Tree memory) {
        Tree memory tree;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function newNode(uint256 value, bytes memory payload) internal pure returns (Tree memory) {
        return Tree({exists: true, value: value, payload: payload, neighbors: new Tree[](2)});
    }

    function fillNode(Tree memory tree, uint256 value, bytes memory payload) internal pure {
        tree.exists = true;
        tree.value = value;
        tree.payload = payload;
    }

    function add(Tree memory tree, uint256 value, bytes memory payload) internal pure {
        if (!tree.exists) {
            fillNode(tree, value, payload);
            return;
        }
        uint256 idx;
        if (tree.value > value) idx = 1;
        if (tree.neighbors[idx].exists) {
            add(tree.neighbors[idx], value, payload);
        } else {
            tree.neighbors[idx] = newNode(value, payload);
        }
    }

    function get(Tree memory tree, uint256 value) internal pure returns (Tree memory) {
        if (tree.exists) {
            uint256 _value = tree.value;
            if (_value < value) {
                return get(tree.neighbors[0], value);
            } else if (_value > value) {
                return get(tree.neighbors[1], value);
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
        //arrayA[idx] = tree.value;
        //arrayB[idx++] = tree.payload;
        assembly {
            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x20)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))
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
        //arrayA[idx] = tree.value;
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
