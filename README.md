# MemoryMappings in Solidity 

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Read/write to the memory map is cheaper in gas than the analogue in storage. In best case read/write are O(log n).

### test printout

```
Logs:
  254440 gas total
  2544 gas per add
  34613 readInto gas
  346 readInto per elt
  ----
  ----
  348583 get gas total
  3485 get gas avg
  6311 gas max
  476 gas min
  21850 ignorant linear search gas

[PASS] test_benchmark_words() (gas: 1032500)
Logs:
  265751 gas total
  2657 gas per add
  35513 readInto gas
  355 readInto per elt
  307526 get gas total
  3075 get gas avg
  5552 gas max
  451 gas min
  21813 ignorant linear search gas
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
