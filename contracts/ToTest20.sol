// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Test is ERC20 {
    constructor() ERC20("Gold", "GLD") {
        
    }

    function earn(address account, uint256 amount) public{
        _mint(account, amount);
    }
}