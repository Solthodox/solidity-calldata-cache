// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Cache.sol";

contract CacheTest is Test {
    Cache public cache;

    function setUp() public {
        cache = new Cache();
    }

    function testCaching() public {
        for (uint256 i = 1; i < 5000; i++) {
            cache.cacheWrite(i * i);
        }

        for (uint256 i = 1; i < 5000; i++) {
            assertEq(cache.cacheRead(i), i * i);
        }
    }
}
