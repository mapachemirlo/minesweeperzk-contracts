// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MINSWPToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Minesweeper Token", "MINSWP") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }
}
