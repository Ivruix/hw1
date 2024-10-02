// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract MyERC1155Token is ERC1155URIStorage {
    uint256 public tokenCounter;
    uint256 public pricePerToken = 0.01 ether;

    constructor() ERC1155("") {
        tokenCounter = 0;
    }

    /// @notice Покупка нового ERC1155 токена
    function buyToken(uint256 amount, string memory tokenURI) public payable {
        require(msg.value >= pricePerToken * amount, "Not enought ETH to buy");
        _mint(msg.sender, tokenCounter, amount, "");
        _setURI(tokenCounter, tokenURI);
        tokenCounter++;
    }
}
