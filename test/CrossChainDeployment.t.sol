// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {Default} from "src/Default.sol";

contract CrossChainDeploymentTest is Test {
    uint256 chain1;
    uint256 chain2;
    address public alice = makeAddr("alice");

    function setUp() public {
        chain1 = vm.createFork("http://localhost:8545");
        chain2 = vm.createFork("http://localhost:8546");
    }

    function test_CrossChain() public {
        vm.selectFork(chain1);
        address deployedChain1 = _deploy(abi.encodePacked(type(Default).creationCode), 0);

        vm.selectFork(chain2);
        address deployedChain2 = _deploy(abi.encodePacked(type(Default).creationCode), 0);

        assertEq(deployedChain1, deployedChain2, "Deployed contracts should be the same");
    }

    function _deploy(bytes memory bytecode, uint256 _salt) public payable returns (address) {
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
