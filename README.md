# MemoryMappings in Solidity 

GPL-3 License Copyright (c) 2022 George Carder georgercarder@gmail.com

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Up to certain threshold numbers, Read/write to the memory map is cheaper in gas than the analogue in storage.

It appears this threshold is rather low (60 ish) for many read/writes but this could be useful in some applications.

The threshold is better for many reads and single write. 

See test printouts.

### test printout

```
Gas used (mem test): 23513
Gas used (storage test): 43640


Many read/writes 


Gas used (mem test extended  60 ): 1366361
Gas used (storage test extended  60 ): 1370157


Many reads, single write 


Gas used (mem test extended2  150 ): 3238392
Gas used (storage test extended2  150 ): 3440241


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
