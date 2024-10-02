// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MyERC20Token.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MyERC20TokenTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    MyERC20Token public token;
    address public deployer;
    address public alice;
    address public bob;
    uint256 public initialDeployerBalance;

    function setUp() public {
        deployer = address(this);
        alice = address(0x1);
        bob = address(0x2);

        token = new MyERC20Token();
        initialDeployerBalance = token.balanceOf(deployer);
    }

    /// @notice Тест функции buyToken
    function testBuyToken() public {
        // Симулируем покупку токенов Алисой
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        token.buyToken{value: 0.01 ether}();

        // Рассчитываем ожидаемое количество токенов, которые должна получить Алиса
        uint256 expectedAmount = (0.01 ether * 10 ** token.decimals()) / token.pricePerToken();

        assertEq(token.balanceOf(alice), expectedAmount, "Alice did not receive the correct amount of tokens");

        // Проверяем, что баланс владельца уменьшился на ожидаемую сумму
        uint256 expectedDeployerBalance = initialDeployerBalance - expectedAmount;
        assertEq(token.balanceOf(deployer), expectedDeployerBalance, "Deployer's balance did not decrease correctly");
    }

    /// @notice Тест функции transfer с вычетом комиссии
    function testTransferWithFee() public {
        // Сначала переводим немного токенов Алисе
        uint256 amountToTransfer = 1000 * 10 ** token.decimals();
        token.transfer(alice, amountToTransfer);

        // Симулируем перевод токенов от Алисы к Бобу
        vm.prank(alice);
        token.transfer(bob, amountToTransfer);

        // Рассчитываем комиссию и сумму после вычета комиссии
        uint256 fee = (amountToTransfer * token.transferFee()) / 100;
        uint256 amountAfterFee = amountToTransfer - fee;

        // Проверяем балансы
        assertEq(token.balanceOf(bob), amountAfterFee, "Bob did not receive the correct amount of tokens");
        assertEq(token.balanceOf(deployer), initialDeployerBalance - amountToTransfer + fee, "Fee recipient did not receive the correct fee");
        assertEq(token.balanceOf(alice), 0, "Alice's balance should be zero");
    }

    /// @notice Тест функции transferFrom с вычетом комиссии
    function testTransferFromWithFee() public {
        // Сначала переводим немного токенов Алисе
        uint256 amountToTransfer = 1000 * 10 ** token.decimals();
        token.transfer(alice, amountToTransfer);

        // Алиса одобряет Бобу тратить её токены
        vm.prank(alice);
        token.approve(bob, amountToTransfer);

        // Симулируем вызов transferFrom Бобом для перевода токенов от Алисы к самому себе
        vm.prank(bob);
        token.transferFrom(alice, bob, amountToTransfer);

        // Рассчитаываем комиссию и сумму после вычета комиссии
        uint256 fee = (amountToTransfer * token.transferFee()) / 100;
        uint256 amountAfterFee = amountToTransfer - fee;

        // Проверяем балансы
        assertEq(token.balanceOf(bob), amountAfterFee, "Bob did not receive the correct amount of tokens");
        assertEq(token.balanceOf(deployer), initialDeployerBalance - amountToTransfer + fee, "Fee recipient did not receive the correct fee");
        assertEq(token.balanceOf(alice), 0, "Alice's balance should be zero");

        // Проверяем, что разрешение было обновлено
        uint256 remainingAllowance = token.allowance(alice, bob);
        assertEq(remainingAllowance, 0, "Bob's allowance should be zero");
    }

    /// @notice Тест безгазовой передачи с использованием разрешения
    function testPermitAndTransferWithSignature() public {
        // Генерация подписи от Алисы для одобрения расходов Бобом
        uint256 amountToApprove = 1000 * 10 ** token.decimals();
        uint256 privateKeyAlice = 0xA11CE; // Приватный ключ Алисы
        address aliceAddress = vm.addr(privateKeyAlice);

        // Перевод токенов Алисе
        token.transfer(aliceAddress, amountToApprove);

        // Построение параметров разрешения
        uint256 nonce = token.nonces(aliceAddress);
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                aliceAddress,
                bob,
                amountToApprove,
                nonce,
                deadline
            )
        );

        bytes32 digest = MessageHashUtils.toTypedDataHash(token.DOMAIN_SEPARATOR(), structHash);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeyAlice, digest);

        // Боб вызывает разрешение для установки лимита без отправки транзакции от Алисы
        token.permit(aliceAddress, bob, amountToApprove, deadline, v, r, s);

        // Проверка, что лимит установлен
        uint256 allowance = token.allowance(aliceAddress, bob);
        assertEq(allowance, amountToApprove, "Allowance not set correctly via permit");

        // Боб теперь может перевести токены от Алисы, используя transferFrom
        vm.prank(bob);
        token.transferFrom(aliceAddress, bob, amountToApprove);

        // Рассчитываем комиссию и сумму после вычета комиссии
        uint256 fee = (amountToApprove * token.transferFee()) / 100;
        uint256 amountAfterFee = amountToApprove - fee;

        // Проверка балансов
        assertEq(token.balanceOf(bob), amountAfterFee, "Bob did not receive the correct amount of tokens");
        assertEq(token.balanceOf(deployer), initialDeployerBalance - amountToApprove + fee, "Fee recipient did not receive the correct fee");
        assertEq(token.balanceOf(aliceAddress), 0, "Alice's balance should be zero");
    }
}