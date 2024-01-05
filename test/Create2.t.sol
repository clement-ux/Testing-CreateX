// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";

import {Helpers} from "test/Helpers.sol";

import {CreateX} from "createX/CreateX.sol";

import {Default} from "src/Default.sol";
import {DefaultInit} from "src/DefaultInit.sol";
import {DefaultConstructor} from "src/DefaultConstructor.sol";

contract Deploy_WithCreate2_Test is Test {
    uint256 chain1;
    uint256 chain2;

    CreateX public createX;

    Default public dummy;
    DefaultInit public dummyInit;
    DefaultConstructor public dummyConstructor;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        // Create ForkIds //
        chain1 = vm.createFork("http://localhost:8545");
        chain2 = vm.createFork("http://localhost:8546");

        // Bytecode //
        bytes memory initCode = type(CreateX).creationCode;

        // Deploy contracts //
        vm.selectFork(chain1);
        createX = CreateX(Helpers.deploy(initCode, 0));

        vm.selectFork(chain2);
        createX = CreateX(Helpers.deploy(initCode, 0));
    }

    function test_Create2_Simple_SimpleSalt() public {
        // Prepare Salt and hash //
        bytes32 defaultSalt = hex"03";
        bytes32 encodedSalt = keccak256(abi.encode(defaultSalt));
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreate2Address(encodedSalt, initCodeHash);

        // Deploy contract //
        vm.prank(address(this), address(this));
        address deployed = createX.deployCreate2(defaultSalt, cachedInitCode);
        vm.stopPrank();

        // Assertions //
        assertEq(deployed, predicted, "Deployed address should match predicted address");
        assertEq(Default(deployed).owner(), address(createX), "Deployed contract should have correct owner");
        assertEq(Default(deployed).origin(), address(this), "Deployed contract should have correct origin");
    }

    function test_RevertWhen_Create2_Simple_ProtectedSalt_Address0_WrongCrossChainProtection() public {
        // Prepare Salt //
        bytes20 address0 = hex"00";
        bytes1 crosschainProtectionFlag = hex"ff";
        bytes11 salt = hex"0000000000000000000011";
        bytes32 encodedSalt = bytes32(abi.encodePacked(address0, crosschainProtectionFlag, salt));

        // Prepare code hash //
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        //bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        //address predicted = createX.computeCreate2Address(encodedSalt, initCodeHash);

        // Deploy contract //
        vm.prank(address(this), address(this));
        vm.expectRevert(abi.encodeWithSelector(CreateX.InvalidSalt.selector, address(createX)));
        createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();
    }

    /// @notice Permisionless deploying contract without cross-chain possibility.
    ///
    /// @dev Permissionless deploying contract with cross-chain protection is a little bit useless because
    /// even if it allow anyone to deploy this contract, it can be deployed only on 1 chain,
    /// so the permissionless feature is useless.
    function test_Create2_Simple_ProtectedSalt_Address0_WithCrossChainProtection() public {
        // Prepare Salt //
        bytes20 address0 = hex"00";
        bytes1 crosschainProtectionFlag = hex"01";
        bytes11 salt = hex"0000000000000000000011";
        bytes32 encodedSalt = bytes32(abi.encodePacked(address0, crosschainProtectionFlag, salt));
        bytes32 guardSalt = Helpers.efficientHash(bytes32(block.chainid), encodedSalt);

        // Prepare code hash //
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreate2Address(guardSalt, initCodeHash);

        // Deploy contract //
        vm.startPrank(address(this), address(this));
        address deployed = createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();

        // Assertions //
        assertEq(predicted, deployed, "Deployed address should match predicted address");
    }

    /// @notice Permisionless deploying contract with cross-chain possibility.
    function test_Create2_Simple_ProtectedSalt_Address0_WithoutCrossChainProtection() public {
        // Prepare Salt //
        bytes20 sender = bytes20(address(0)); // Permissionless
        bytes1 crosschainProtectionFlag = hex"00"; // Crosschain protection disabled
        bytes11 salt = hex"0000000000000000000011"; // Random salt to generate random address
        bytes32 encodedSalt = bytes32(abi.encodePacked(sender, crosschainProtectionFlag, salt));
        bytes32 guardSalt = keccak256(abi.encode(encodedSalt)); // Used to predict address

        // Prepare code hash //
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreate2Address(guardSalt, initCodeHash);

        // Deploy contract on Chain1 //
        vm.selectFork(chain1);
        vm.startPrank(alice, alice);
        address deployed = createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();

        // Assertions //
        assertEq(predicted, deployed, "Deployed address should match predicted address");

        // Deploy contract on Chain2 with other user//
        vm.selectFork(chain2);
        vm.startPrank(bob, bob);
        deployed = createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();

        // Assertions //
        assertEq(predicted, deployed, "Deployed address should match predicted address");
    }

    /// @notice Permisionned deploying contract with cross-chain possibility.
    function test_Create2_Simple_ProtectedSalt_MsgSender_WithoutCrossChainProtection() public {
        // Prepare Salt //
        bytes20 msgSender = bytes20(address(this));
        bytes1 crosschainProtectionFlag = hex"00"; // false
        bytes11 salt = hex"0000000000000000012345";
        bytes32 encodedSalt = bytes32(abi.encodePacked(msgSender, crosschainProtectionFlag, salt));
        bytes32 guardSalt = Helpers.efficientHash(bytes32(uint256(uint160(address(this)))), encodedSalt);

        // Prepare code hash //
        bytes memory cachedInitCode = abi.encodePacked(type(Default).creationCode);
        bytes32 initCodeHash = keccak256(cachedInitCode);

        // Predict address //
        address predicted = createX.computeCreate2Address(guardSalt, initCodeHash);

        // Deploy contract on Chain1 //
        vm.selectFork(chain1);
        vm.startPrank(address(this), address(this));
        address deployed = createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();

        // Assertions //
        assertEq(predicted, deployed, "Deployed address should match predicted address");

        // Deploy contract on Chain2 //
        vm.selectFork(chain2);
        vm.startPrank(address(this), address(this));
        createX.deployCreate2(encodedSalt, cachedInitCode);
        vm.stopPrank();
    }
}
