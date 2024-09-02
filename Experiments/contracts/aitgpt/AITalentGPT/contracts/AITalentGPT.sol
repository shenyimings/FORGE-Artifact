// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AITalentGPT is ERC20, Ownable {


    constructor() ERC20("AI TalentGPT", "AITGPT") {
        _mint(msg.sender, 1_000_000_000_000 * 10 ** decimals());
    }

}