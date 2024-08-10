# MemoryMappings in Solidity 

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Read/write to the memory map is cheaper in gas than the analogue in storage. In best case read/write are O(log n).

### test printout

```
Logs:
  295020 gas total
  2950 gas per add
  38213 readInto gas
  382 readInto per elt
  ----
  ----
  413395 get gas total
  4133 get gas avg
  7568 gas max
  562 gas min
  21865 ignorant linear search gas

[PASS] test_benchmark_words() (gas: 1124416)
Logs:
  306230 gas total
  3062 gas per add
  39113 readInto gas
  391 readInto per elt
  350131 get gas total
  3501 get gas avg
  6421 gas max
  515 gas min
  21823 ignorant linear search gas
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
