//SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.8.0;

library MemoryMappings {

    struct MemoryMapping {
        Tree tree;
    }

    function newMemoryMapping() internal pure returns(MemoryMapping memory) {
        return MemoryMapping({tree: newNode()}); 
    }

    function newMemoryMapping(bytes32 key, bytes memory value) internal pure returns(MemoryMapping memory) {
        return MemoryMapping({tree: newNode(uint256(key), value)}); 
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes32 value) internal pure {
        add(mm.tree, uint256(key), abi.encode(value)); 
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes memory value) internal pure {
        add(mm, keccak256(key), value); 
    }

    function add(MemoryMapping memory mm, bytes32 key, bytes memory value) internal pure {
        add(mm.tree, uint256(key), value); 
    }

    function add(MemoryMapping memory mm, bytes memory key, bytes32 value) internal pure {
        add(mm, keccak256(key), abi.encode(value)); 
    }

    function get(MemoryMapping memory mm, bytes32 key) internal pure returns(bool ok, bytes memory ret) {
        Tree memory node = get(mm.tree, uint256(key)); 
        if (node.exists) {
            ok = true;
            ret = node.payload;
        }
    }

    function get(MemoryMapping memory mm, bytes memory key) internal pure returns(bool ok, bytes memory ret) {
        return get(mm, keccak256(key));
    }

    // Tree

    struct Tree {
        bool exists;
        uint256 value; // sort by value in descending order max -> min
        bytes payload; // optional arbitrary payload
        Tree[] neighbors; // 0-left, 1-right
    }

    function newNode() internal pure returns(Tree memory) {
        Tree memory tree;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function newNode(uint256 value, bytes memory payload) internal pure returns(Tree memory) {
        Tree memory tree;
        tree.exists = true;
        tree.value = value;
        tree.payload = payload;
        tree.neighbors = new Tree[](2);
        return tree;
    }

    function add(Tree memory tree, uint256 value, bytes memory payload) internal pure {
        if (!tree.exists) {
            tree.exists = true;
            tree.value = value;
            tree.payload = payload;
            return;
        }
        uint256 idx = 0;
        if (tree.value > value) idx = 1;
        if (tree.neighbors[idx].exists) {
            add(tree.neighbors[idx], value, payload);
        } else {
            tree.neighbors[idx] = newNode(value, payload); 
        }
    }

    function get(Tree memory tree, uint256 value) internal pure returns(Tree memory) {
        if (!tree.exists || tree.value == value) return tree;
        uint256 idx = 0;
        if (tree.value > value) idx = 1;
        return get(tree.neighbors[idx], value);
    }

    function readInto(Tree memory tree, uint256[] memory arrayA, bytes[] memory arrayB) internal pure { 
        if (tree.neighbors[0].exists) readInto(tree.neighbors[0], arrayA, arrayB); // left
        // center
        uint256 idx = arrayA[arrayA.length-1];
        arrayA[idx] = tree.value;
        arrayB[idx] = tree.payload;
        arrayA[arrayA.length-1] = ++idx;
        if (tree.neighbors[1].exists) readInto(tree.neighbors[1], arrayA, arrayB); // right
    }

    function readInto(Tree memory tree, uint256[] memory arrayA, uint256[] memory arrayB) internal pure { 
        if (tree.neighbors[0].exists) readInto(tree.neighbors[0], arrayA, arrayB); // left
        // center
        uint256 idx = arrayA[arrayA.length-1];
        arrayA[idx] = tree.value;
        arrayB[idx] = abi.decode(tree.payload, (uint256));
        arrayA[arrayA.length-1] = ++idx;
        if (tree.neighbors[1].exists) readInto(tree.neighbors[1], arrayA, arrayB); // right
    }
}
