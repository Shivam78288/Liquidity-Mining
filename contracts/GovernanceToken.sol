// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract GovernanceToken is ERC20 {
    address owner;
    constructor() ERC20('Governance Token', 'GTK'){
        owner = msg.sender;
    }
    function mint(address to, uint amount) external{
        require(msg.sender == owner, "Only Owner");
        _mint(to,amount);
    }

    function transferOwnership(address newOwner) external{
        require(msg.sender == owner);
        owner= newOwner;
    }
}


