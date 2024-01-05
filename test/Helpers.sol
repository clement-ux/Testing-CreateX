// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

library Helpers {
    function predictAddress_Create1(address _creator, bytes1 _nonce) public pure returns (address) {
        if (_nonce == 0) _nonce = 0x80;
        return address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), _creator, _nonce)))));
    }

    function generateSalt() public view returns (bytes32 salt) {
        unchecked {
            salt = keccak256(
                abi.encode(
                    // We don't use `block.number - 256` (the maximum value on the EVM) to accommodate
                    // any chains that may try to reduce the amount of available historical block hashes.
                    // We also don't subtract 1 to mitigate any risks arising from consecutive block
                    // producers on a PoS chain. Therefore, we use `block.number - 32` as a reasonable
                    // compromise, one we expect should work on most chains, which is 1 epoch on Ethereum
                    // mainnet. Please note that if you use this function between the genesis block and block
                    // number 31, the block property `blockhash` will return zero, but the returned salt value
                    // `salt` will still have a non-zero value due to the hashing characteristic and the other
                    // remaining properties.
                    blockhash(block.number - 32),
                    block.coinbase,
                    block.number,
                    block.timestamp,
                    block.prevrandao,
                    block.chainid,
                    msg.sender
                )
            );
        }
    }

    /**
     * @dev Returns the `keccak256` hash of `a` and `b` after concatenation.
     * @param a The first 32-byte value to be concatenated and hashed.
     * @param b The second 32-byte value to be concatenated and hashed.
     * @return hash The 32-byte `keccak256` hash of `a` and `b`.
     */
    function efficientHash(bytes32 a, bytes32 b) public pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            hash := keccak256(0x00, 0x40)
        }
    }

    function deploy(bytes memory bytecode, uint256 _salt) public returns (address) {
        address addr;

        assembly {
            addr :=
                create2(
                    callvalue(), // wei sent with current call
                    // Actual code starts after skipping the first 32 bytes
                    add(bytecode, 0x20),
                    mload(bytecode), // Load the size of code contained in the first 32 bytes
                    _salt // Salt from function arguments
                )

            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        return addr;
    }
}
