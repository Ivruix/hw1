// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyERC20Token.sol";

contract InteractWithContract is Script {
    address contractAddress = 0x1633921bc5702350790d9Ad3dAc27228D9C9cDfE; // Адрес вашего контракта на Amoy
    address userA = 0x9F44D8D990f82c457d35e9e579b8b80F086D6D92; // Адрес отправителя
    address userB = 0x2988D77ca7acEB85Dd3eBd27B4109501AAeBB617; // Адрес получателя

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Инстанцируем контракт
        MyERC20Token token = MyERC20Token(contractAddress);

        token.transfer(userB, 100 * 10 ** token.decimals());
        token.approve(userA, 50 * 10 ** token.decimals());
        token.transferFrom(userA, userB, 50 * 10 ** token.decimals());
        (bool success, ) = contractAddress.call{value: 0.1 ether}(""); 
        require(success, "Failed to buy tokens");

        vm.stopBroadcast();
    }
}
