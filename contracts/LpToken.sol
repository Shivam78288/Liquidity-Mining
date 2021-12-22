// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract LpToken is ERC20{
    constructor() ERC20('LP Token', 'LTK'){}
}