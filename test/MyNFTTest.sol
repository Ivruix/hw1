// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MyNFT.sol";

contract MyNFTTest is Test {
    MyNFT public nftContract;
    address public buyer;


    uint256 public nftPrice = 0.01 ether;

    function setUp() public {
        nftContract = new MyNFT();
        buyer = vm.addr(0x1);
        vm.deal(buyer, 1 ether);
    }

    /// @notice Тест успешной покупки NFT
    function testBuyTokenSuccessfully() public {
        vm.prank(buyer);
        nftContract.buyToken{value: nftPrice}("ipfs://tokenURI1");

        // Проверяем, что buyer стала владельцем токена с ID 0
        assertEq(nftContract.ownerOf(0), buyer);

        // Проверяем, что tokenCounter увеличился
        assertEq(nftContract.tokenCounter(), 1);

        // Проверяем, что токен имеет правильный URI
        assertEq(nftContract.tokenURI(0), "ipfs://tokenURI1");
    }

    /// @notice Тест покупки NFT с недостаточным количеством ETH
    function testBuyTokenWithInsufficientETH() public {
        vm.prank(buyer);
        vm.expectRevert("Not enought ETH to buy");
        nftContract.buyToken{value: 0.005 ether}("ipfs://tokenURI2");
    }

    /// @notice Тест покупки нескольких NFT
    function testMultipleTokenPurchases() public {
        // buyer покупает первый и второй токен
        vm.prank(buyer);
        nftContract.buyToken{value: nftPrice}("ipfs://tokenURI1");
        vm.prank(buyer);
        nftContract.buyToken{value: nftPrice}("ipfs://tokenURI2");

        // Проверяем общий счетчик токенов
        assertEq(nftContract.tokenCounter(), 2);
    }

    /// @notice Тест установки правильного tokenURI
    function testTokenURIIsSetCorrectly() public {
        vm.prank(buyer);
        nftContract.buyToken{value: nftPrice}("ipfs://tokenURI1");

        string memory tokenURI = nftContract.tokenURI(0);
        assertEq(tokenURI, "ipfs://tokenURI1");
    }

    /// @notice Тест покупки NFT без отправки ETH
    function testBuyTokenWithoutSendingETH() public {
        vm.prank(buyer);
        vm.expectRevert("Not enought ETH to buy");
        nftContract.buyToken("ipfs://tokenURI2");
    }

    /// @notice Тест, что контракт получает ETH при покупке
    function testContractReceivesETH() public {
        uint256 initialBalance = address(nftContract).balance;

        vm.prank(buyer);
        nftContract.buyToken{value: nftPrice}("ipfs://tokenURI1");

        uint256 finalBalance = address(nftContract).balance;

        assertEq(finalBalance, initialBalance + nftPrice);
    }
}