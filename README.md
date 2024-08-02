# MemoryMappings in Solidity 

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Read/write to the memory map is cheaper in gas than the analogue in storage. In this case read/write are O(log n).

### test printout

```
[PASS] test_benchmark_bytes() (gas: 1165725)
Logs:
  238141 gas total
  2381 gas per add
  33213 readInto gas
  332 readInto per elt
  ----
  ----
  282275 get gas total
  2822 get gas avg
  5211 gas max
  497 gas min
  21825 ignorant linear search gas

[PASS] test_benchmark_words() (gas: 899659)
Logs:
  248661 gas total
  2486 gas per add
  35513 readInto gas
  355 readInto per elt
  ----
  ----
  274662 get gas total
  2746 get gas avg
  5015 gas max
  504 gas min
  21809 ignorant linear search gas

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
