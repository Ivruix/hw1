// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Импортируем тестовые утилиты Foundry
import "forge-std/Test.sol";
import "../src/MyERC1155Token.sol"; // Путь к вашему контракту

contract MyERC1155TokenTest is Test {
    MyERC1155Token internal erc1155;
    address internal buyer;
    string internal sampleURI = "https://example.com/token/{id}.json";

    // Функция, которая вызывается перед каждым тестом
    function setUp() public {
        erc1155 = new MyERC1155Token();
        buyer = address(0xBEEF);
    }

    /// @notice Тест успешной покупки токенов
    function testBuyTokenSuccess() public {
        uint256 amount = 5;
        uint256 totalPrice = 0.01 ether * amount;

        // Начальный баланс покупателя
        vm.deal(buyer, totalPrice);

        // Принципалский вызов от имени покупателя
        vm.prank(buyer);
        erc1155.buyToken{value: totalPrice}(amount, sampleURI);

        // Проверяем баланс покупателя
        uint256 balance = erc1155.balanceOf(buyer, 0); // tokenId = 0
        assertEq(balance, amount, "Incorrect token balance");

        // Проверяем URI токена
        string memory uri = erc1155.uri(0);
        assertEq(uri, sampleURI, "Incorrect token URI");

        // Проверяем, что счетчик токенов увеличился
        uint256 tokenCounter = erc1155.tokenCounter();
        assertEq(tokenCounter, 1, "Token counter not incremented");

        // Проверяем, что контракт получил ETH
        uint256 contractBalance = address(erc1155).balance;
        assertEq(contractBalance, totalPrice, "Incorrect contract ETH balance");
    }

    /// @notice Тест покупки токенов с недостаточным количеством ETH
    function testBuyTokenInsufficientETH() public {
        uint256 amount = 3;
        uint256 insufficientPrice = 0.01 ether * amount - 1 wei;

        // Начальный баланс покупателя
        vm.deal(buyer, insufficientPrice);

        // Принципалский вызов от имени покупателя и ожидание revert
        vm.prank(buyer);
        vm.expectRevert(bytes("Not enought ETH to buy"));
        erc1155.buyToken{value: insufficientPrice}(amount, sampleURI);
    }
}
