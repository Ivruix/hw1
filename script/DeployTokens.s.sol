// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MyERC20Token.sol";
import "../src/MyNFT.sol";
import "../src/MyERC1155Token.sol";

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Деплой первого токена
        MyERC20Token token1 = new MyERC20Token();
        // Деплой второго токена
        MyNFT token2 = new MyNFT();
        // Деплой третьего токена
        MyERC1155Token token3 = new MyERC1155Token();

        vm.stopBroadcast();
    }
}
