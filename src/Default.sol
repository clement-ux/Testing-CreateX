// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract Default {
    address public owner;
    address public origin;

    constructor() {
        owner = msg.sender;
        origin = tx.origin;
    }
}
