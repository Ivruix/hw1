// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyERC20Token is ERC20Permit {
    uint256 public pricePerToken = 0.001 ether;
    uint256 public transferFee = 1; // 1%
    address public feeRecipient;

    constructor() ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        feeRecipient = msg.sender;
        _mint(feeRecipient, 1000000 * 10 ** decimals());
        // Разрешаем контракту перевод токенов от имени feeRecipient на неограниченную сумму
        _approve(feeRecipient, address(this), type(uint256).max);
    }

    /// @notice Покупка токенов путем отправки эфира
    function buyToken() external payable {
        uint256 amountToBuy = (msg.value * 10 ** decimals()) / pricePerToken;
        require(amountToBuy > 0, "Not enough ETH to buy");
        require(balanceOf(feeRecipient) >= amountToBuy, "Not enough tokens");

        // Переводим токены от feeRecipient к покупателю
        _transfer(feeRecipient, msg.sender, amountToBuy);
    }

    /// @notice Переопределение функции перевода с добавлением комиссии
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * transferFee) / 100;
        if (msg.sender == feeRecipient) {
            fee = 0;
        }
        uint256 amountAfterFee = amount - fee;

        // Переводим комиссию получателю комиссии
        super.transfer(feeRecipient, fee);
        // Переводим остаток получателю
        super.transfer(recipient, amountAfterFee);

        return true;
    }

    /// @notice Переопределение функции transferFrom с добавлением комиссии
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 fee = (amount * transferFee) / 100;
        if (msg.sender == feeRecipient) {
            fee = 0;
        }
        uint256 amountAfterFee = amount - fee;

        // Обновляем allowance
        uint256 currentAllowance = allowance(sender, msg.sender);
        require(currentAllowance >= amount, "Transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

        // Переводим комиссию получателю комиссии
        _transfer(sender, feeRecipient, fee);
        // Переводим остаток получателю
        _transfer(sender, recipient, amountAfterFee);

        return true;
    }
}