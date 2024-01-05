// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

contract DefaultInit {
    address public owner;
    address public origin;

    uint256 public value1;
    uint256 public value2;

    function init(uint256 _value1, uint256 _value2) public {
        owner = msg.sender;
        origin = tx.origin;
        value1 = _value1;
        value2 = _value2;
    }
}
