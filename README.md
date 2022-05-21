# MemoryMappings in Solidity 

GPL-3 License Copyright (c) 2022 George Carder georgercarder@gmail.com

You can define and use mappings in memory in solidity using this library. Don't trifle with writing to storage when you need a mapping, use this memory library instead.

Read/write to the memory map is cheaper in gas than the analogue in storage.

##### test printout

```
Gas used (mem): 23491
Gas used (storage): 43618
```


Not audited. Use at your own risk.

### example

```
        MemoryMappings.MemoryMapping memory mm = MemoryMappings.newMemoryMapping();

        uint256 key = 123;
        uint256 dankness = 42069;
        mm.add(bytes32(key), bytes32(dankness));
        (bool ok, bytes memory result) = mm.get(bytes32(key));
        require(ok, "not ok");
        uint256 res = uint256(abi.decode(result, (bytes32)));
        require(res == dankness, "fail.");
```

Support my work on this library by donating ETH or other coins to

`0x1331DA733F329F7918e38Bc13148832D146e5adE`
