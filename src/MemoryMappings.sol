// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library MemoryMappings {
    struct MemoryMapping {
        Tree tree;
    }

    function newMemoryMapping() internal pure returns (MemoryMapping memory) {
        return MemoryMapping({tree: newNode()});
    }

    function newMemoryMapping(bytes32 key, bytes memory value) internal pure returns (MemoryMapping memory) {
        uint256 orderingKey;
        assembly {
            mstore(0x00, key)
            orderingKey := keccak256(0x00, 0x20) // hash of key ensures tree is more balanced
        }
        return MemoryMapping({tree: newNode(orderingKey, uint256(key), value)});
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        uint256 orderingKey;
        assembly {
            mstore(0x00, key)
            orderingKey := keccak256(0x00, 0x20) // hash of key ensures tree is more balanced
        }
        add(mm.tree, orderingKey, uint256(key), bValue);
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes memory value) internal pure {
        add(mm, keccak256(key), value);
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory value) internal pure {
        uint256 orderingKey;
        assembly {
            mstore(0x00, key)
            orderingKey := keccak256(0x00, 0x20) // hash of key ensures tree is more balanced
        }
        add(mm.tree, orderingKey, uint256(key), value);
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes32 value) internal pure {
        bytes memory bValue = new bytes(32);
        assembly {
            mstore(add(bValue, 0x20), value)
        }
        add(mm, keccak256(key), bValue);
    }

    function get(MemoryMapping memory mm, bytes32 key) internal pure returns (bool ok, bytes memory ret) {
        uint256 orderingKey;
        assembly {
            mstore(0x00, key)
            orderingKey := keccak256(0x00, 0x20) // recall, hash of key ensures tree is more balanced.. see add(..) above
        }
        Tree memory node = get(mm.tree, orderingKey);
        if (node.exists) {
            ok = true;
            assembly {
                ret := mload(add(node, 0x60))
            }
        }
    }

    function get(MemoryMapping memory mm, bytes memory key) internal pure returns (bool ok, bytes memory ret) {
        return get(mm, keccak256(key));
    }

    // Tree

    struct Tree {
        bool exists;
        uint256 orderingKey; // sort by key in descending order max -> min
        uint256 key;
        bytes payload; // optional arbitrary payload
        Tree[] neighbors; // 0-left, 1-right
    }

    function newNode() internal pure returns (Tree memory) {
        Tree memory tree;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function newNode(uint256 orderingKey, uint256 key, bytes memory payload) internal pure returns (Tree memory) {
        return Tree({exists: true, orderingKey: orderingKey, key: key, payload: payload, neighbors: new Tree[](2)});
    }

    function fillNode(Tree memory tree, uint256 orderingKey, uint256 key, bytes memory payload) internal pure {
        tree.exists = true;
        tree.orderingKey = orderingKey;
        tree.key = key;
        tree.payload = payload;
    }

    function add(Tree memory tree, uint256 orderingKey, uint256 key, bytes memory payload) internal pure {
        if (!tree.exists) {
            fillNode(tree, orderingKey, key, payload);
            return;
        }
        uint256 idx;
        if (tree.orderingKey > orderingKey) idx = 1;
        if (tree.neighbors[idx].exists) {
            add(tree.neighbors[idx], orderingKey, key, payload);
        } else {
            tree.neighbors[idx] = newNode(orderingKey, key, payload);
        }
    }

    function get(Tree memory tree, uint256 orderingKey) internal pure returns (Tree memory) {
        if (tree.exists) {
            uint256 _orderingKey = tree.orderingKey;
            if (_orderingKey < orderingKey) {
                return get(tree.neighbors[0], orderingKey);
            } else if (_orderingKey > orderingKey) {
                return get(tree.neighbors[1], orderingKey);
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
            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x60)))
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
            mstore(add(arrayA, add(0x20, mul(idx, 0x20))), mload(add(tree, 0x40)))

            mstore(add(arrayB, add(0x20, mul(idx, 0x20))), mload(add(mload(add(tree, 0x60)), 0x20)))
            idx := add(idx, 1)
        }
        other = tree.neighbors[1];
        if (other.exists) idx = readInto(other, idx, arrayA, arrayB); // right
        return idx;
    }
}
