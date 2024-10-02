// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract ViewStorageSlots is Script {
    address contractAddress = 0x1633921bc5702350790d9Ad3dAc27228D9C9cDfE;
    address user = 0x9F44D8D990f82c457d35e9e579b8b80F086D6D92;

    function run() public {
        bytes32 slot;

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        slot = bytes32(keccak256(abi.encode(user, uint256(0))));
        bytes32 balanceSlot = vm.load(contractAddress, slot);
        console.log("Balance slot:", uint(balanceSlot));

        vm.stopBroadcast();
    }
}
