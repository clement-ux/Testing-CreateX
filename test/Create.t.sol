// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";

import {Helpers} from "test/Helpers.sol";

import {CreateX} from "createX/CreateX.sol";
import {Default} from "src/Default.sol";
import {DefaultInit} from "src/DefaultInit.sol";
import {DefaultConstructor} from "src/DefaultConstructor.sol";

contract Deploy_WithCreate_Test is Test {
    CreateX public createX;
    Default public dummy;
    DefaultInit public dummyInit;
    DefaultConstructor public dummyConstructor;

    function setUp() public {
        createX = new CreateX();
    }

    function test_Create_Simple() public {
        // Set custom nonce //
        uint64 customNonce = 32;
        vm.setNonce(address(createX), customNonce);

        // Hash init code //
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        // bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreateAddress(customNonce);
        address predicted2 =
            Helpers.predictAddress_Create1(address(createX), bytes1(uint8(vm.getNonce(address(createX)))));

        // Deploy contract //
        address deployed = createX.deployCreate(cachedInitCode);

        // Assertions //
        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertEq(deployed, predicted2, "Deployed address should match predicted address 2");
    }

    function test_Create_WithConstructor() public {
        // Set custom nonce //
        uint64 customNonce = 32;
        vm.setNonce(address(createX), customNonce);

        // Hash init code //
        bytes memory args = abi.encode(uint256(123), uint256(456));
        bytes memory cachedInitCode = abi.encodePacked(type(DefaultConstructor).creationCode, args);
        // bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreateAddress(customNonce);
        address predicted2 =
            Helpers.predictAddress_Create1(address(createX), bytes1(uint8(vm.getNonce(address(createX)))));

        // Deploy contract //
        address deployed = createX.deployCreate(cachedInitCode);

        // Assertions //
        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertEq(deployed, predicted2, "Deployed address should match predicted address 2");
        assertEq(DefaultConstructor(deployed).value1(), uint256(123), "Deployed contract should have value1 set to 123");
        assertEq(DefaultConstructor(deployed).value2(), uint256(456), "Deployed contract should have value2 set to 456");
    }

    function test_Create_WithInit() public {
        // Set custom nonce //
        uint64 customNonce = 32;
        vm.setNonce(address(createX), customNonce);

        // Hash init code //
        //bytes memory args = abi.encode(uint256(123));
        bytes memory cachedInitCode = abi.encodePacked(type(DefaultInit).creationCode);
        // bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreateAddress(customNonce);
        address predicted2 =
            Helpers.predictAddress_Create1(address(createX), bytes1(uint8(vm.getNonce(address(createX)))));

        // Deploy contract //
        bytes memory data = abi.encodeWithSelector(DefaultInit.init.selector, uint256(123), uint256(456));
        CreateX.Values memory values = CreateX.Values(0, 0);
        address deployed = createX.deployCreateAndInit(cachedInitCode, data, values);

        // Assertions //
        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertEq(deployed, predicted2, "Deployed address should match predicted address 2");
        assertEq(DefaultInit(deployed).value1(), uint256(123), "Deployed contract should have value set to 123");
        assertEq(DefaultInit(deployed).value2(), uint256(456), "Deployed contract should have value set to 456");
    }

    function test_Create_WithClone() public {
        address clone = address(new DefaultInit());

        // Set custom nonce //
        uint64 customNonce = 32;
        vm.setNonce(address(createX), customNonce);

        // Predict address //
        address predicted = createX.computeCreateAddress(customNonce);

        // Deploy contract //
        bytes memory data = abi.encodeWithSelector(DefaultInit.init.selector, uint256(123), uint256(456));
        address deployed = createX.deployCreateClone(clone, data);

        // Assertions //
        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertEq(DefaultInit(clone).value1(), uint256(0), "Init clone contract should have value set to 0");
        assertEq(DefaultInit(deployed).value1(), uint256(123), "Deployed contract should have value set to 123");
        assertEq(DefaultInit(deployed).value2(), uint256(456), "Deployed contract should have value set to 456");
    }
}
