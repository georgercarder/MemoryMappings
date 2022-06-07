# MemoryMappings in Solidity 

GPL-3 License Copyright (c) 2022 George Carder georgercarder@gmail.com

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

So long as the key/value pairs are added somewhat randomly, Read/write to the memory map is cheaper in gas than the analogue in storage. In this case read/write are O(log n). But if the key/value pairs are added in order with respect to the keys, then read/write could be up to O(n), in which case it'd be less efficient.

See test printouts simulating "random" keys.

### test printout

```
single read/write
Gas used (mem test): 23491
Gas used (storage test): 43707


Many read/writes 


Gas used (mem test extended  20 ): 124079
Gas used (storage test extended  20 ): 467316

threshold

Gas used (mem test extended  1000 ): 17962238
Gas used (storage test extended  1000 ): 23269980


Many reads, single write 


Gas used (mem test extended2  1000 ): 6162685
Gas used (storage test extended2  1000 ): 23267068

threshold

Gas used (mem test extended2  1000 ): 6227349
Gas used (storage test extended2  1000 ): 23267068

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
        require(ret == value, "not same");
```

Support my work on this library by donating ETH or other coins to

`0x1331DA733F329F7918e38Bc13148832D146e5adE`
