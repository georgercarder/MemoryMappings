# MemoryMappings in Solidity 

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Read/write to the memory map is cheaper in gas than the analogue in storage. In this case read/write are O(log n).

### test printout

```
[PASS] test_benchmark_bytes() (gas: 1657509)
Logs:
  252159 gas total
  2521 gas per add
  34613 readInto gas
  346 readInto per elt
  ----
  ----
  360260 get gas total
  3602 get gas avg
  6732 gas max
  583 gas min
  21858 ignorant linear search gas

[PASS] test_benchmark_words() (gas: 1037022)
Logs:
  263368 gas total
  2633 gas per add
  35513 readInto gas
  355 readInto per elt
  310656 get gas total
  3106 get gas avg
  5782 gas max
  542 gas min
  21818 ignorant linear search gas

```

Not audited. Use at your own risk.

### example

```
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();
        uint256 key = 123;
        uint256 value = 42069; 
        mm.add(bytes32(key), bytes32(value));
        (bool ok, bytes memory result) = mm.get(bytes32(key));
        uint256 ret = ok ? uint256(abi.decode(result, (bytes32))) : 0;

        // also can read into an array (SORTED VALUES OMG!!)

        uint256[] memory arrA = new uint256[](bound);
        uint256[] memory arrB = new uint256[](bound);

        MemoryMappings.readInto(mm.tree, 0, arrA, arrB);
```

Support my work on this library by donating ETH or other coins to

`0x1331DA733F329F7918e38Bc13148832D146e5adE`
