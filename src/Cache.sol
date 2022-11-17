// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Cache {
    // for this example we are storing uin256
    //if the first bytes of the calldata are 0xFF we save it into cache, else not
    bytes1 public constant INTO_CACHE = 0xFF;
    bytes1 public constant DONT_CACHE = 0xFE;

    // We map it in both directions to access data easily
    mapping(uint256 => uint256) public valueToKey;
    uint256[] public keyToValue; // we will start from position 1

    // MAIN FUNCTION encode the value from uint256 to bytes , using cache when possible to reduce gas computation and therefore gas
    function encodeVal(uint256 _val) public view returns (bytes memory) {
        uint256 _key = valueToKey[_val];

        // The value isn't in the cache yet, add it
        if (_key == 0) return bytes.concat(INTO_CACHE, bytes32(_val));

        // If the key is <0x10, return it as a single byte
        if (_key < 0x10) return bytes.concat(bytes1(uint8(_key)));

        // Two byte value, encoded as 0x1vvv
        if (_key < 0x1000) return bytes.concat(bytes2(uint16(_key) | 0x1000));

        // Encoding
        if (_key < 16 * 256**2)
            return bytes.concat(bytes3(uint24(_key) | (0x2 * 16 * 256**2)));
        if (_key < 16 * 256**3)
            return bytes.concat(bytes4(uint32(_key) | (0x3 * 16 * 256**3)));
        if (_key < 16 * 256**4)
            return bytes.concat(bytes5(uint40(_key) | (0x4 * 16 * 256**4)));
        if (_key < 16 * 256**5)
            return bytes.concat(bytes6(uint48(_key) | (0x5 * 16 * 256**5)));
        if (_key < 16 * 256**6)
            return bytes.concat(bytes7(uint56(_key) | (0x6 * 16 * 256**6)));
        if (_key < 16 * 256**7)
            return bytes.concat(bytes8(uint64(_key) | (0x7 * 16 * 256**7)));
        if (_key < 16 * 256**8)
            return bytes.concat(bytes9(uint72(_key) | (0x8 * 16 * 256**8)));
        if (_key < 16 * 256**9)
            return bytes.concat(bytes10(uint80(_key) | (0x9 * 16 * 256**9)));
        if (_key < 16 * 256**10)
            return bytes.concat(bytes11(uint88(_key) | (0xA * 16 * 256**10)));
        if (_key < 16 * 256**11)
            return bytes.concat(bytes12(uint96(_key) | (0xB * 16 * 256**11)));
        if (_key < 16 * 256**12)
            return bytes.concat(bytes13(uint104(_key) | (0xC * 16 * 256**12)));
        if (_key < 16 * 256**13)
            return bytes.concat(bytes14(uint112(_key) | (0xD * 16 * 256**13)));
        if (_key < 16 * 256**14)
            return bytes.concat(bytes15(uint120(_key) | (0xE * 16 * 256**14)));
        if (_key < 16 * 256**15)
            return bytes.concat(bytes16(uint128(_key) | (0xF * 16 * 256**15)));

        // If we get here, something is wrong.
        revert("Error in encodeVal, should not happen");
    }

    function cacheRead(uint256 k) public view returns (uint256) {
        require(k <= keyToValue.length, "k<arr.length");
        return valueToKey[k - 1];
    }

    function cacheWrite(uint256 v) public returns (uint256) {
        // If is in cache break and return the key
        if (valueToKey[v] != 0) return valueToKey[v];

        //if cache storage is filled don`t allow more storage
        require(
            keyToValue.length + 1 < 0x0DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            "cache overflow"
        );

        valueToKey[v] = keyToValue.length + 1;
        keyToValue.push(v);
        return keyToValue.length;
    }

    function _readParam(uint256 _startByte)
        internal
        returns (uint256 nextByte, uint256 parameterValue)
    {
        // we pick the first byte of the calldata to interpret wether to store it in cache or not
        uint8 _firstByte = uint8(_calldataVal(_startByte, 1));

        //Case we don't have to save it to cache
        if (_firstByte == uint8(DONT_CACHE)) {
            return (
                nextByte = _startByte + 33,
                parameterValue = _calldataVal(_startByte + 1, 32)
            );
        }
        //Case we save it
        if (_firstByte == uint8(INTO_CACHE)) {
            uint256 _param = _calldataVal(_startByte + 1, 32); //we take first 32 bytes
            cacheWrite(_param); // save it to cache
            return (nextByte = _startByte + 33, parameterValue = _param); // return the same
        }

        // else

        // Number of extra bytes to read
        uint8 _extraBytes = _firstByte / 16;

        //Fetch the key of the value
        uint256 _key = (uint256(_firstByte & 0x0F) << (8 * _extraBytes)) +
            _calldataVal(_startByte + 1, _extraBytes);

        return (_startByte + _extraBytes + 1, cacheRead(_key));
    }

    // read multiple parameters
    function _readParams(uint256 _paramNum)
        internal
        returns (uint256[] memory)
    {
        uint256[] memory params = new uint256[](_paramNum);

        // Parameters start at byte 4, before that it's the function signature
        uint256 _atByte = 4;

        require(
            _paramNum < 256,
            "Can only handle up to 256 function parameters"
        );

        //fetch the params of each
        for (uint256 i = 0; i < _paramNum; i++) {
            (_atByte, params[i]) = _readParam(_atByte);
        }
        // return all
        return (params);
    }

    // Returns the number read from the calldata
    function _calldataVal(uint256 _startByte, uint256 _len)
        internal
        pure
        returns (uint256)
    {
        uint256 _retVal; //declare variable to save inline assembly result in it

        // make sure we don't wanna read further than the calldata length
        require(_len < 0x21, "_calldataVal length limit");
        require(
            _startByte + _len <= msg.data.length,
            "_calldataVal trying to read beyond calldatasize"
        );

        assembly {
            _retVal := calldataload(_startByte) // calldataload opcode to get bytes from _startByte
        }
        _retVal = _retVal >> (256 - _len * 8); // we remove the part we don't need

        return _retVal;
    }

    // For testing using 4 params
    function fourParam()
        public
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256[] memory params;
        params = _readParams(4);
        return (params[0], params[1], params[2], params[3]);
    }
}
