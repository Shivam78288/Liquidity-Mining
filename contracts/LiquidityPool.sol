// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import './GovernanceToken.sol';
import './LpToken.sol';
import './UnderlyingToken.sol';

contract LiquidityPool is LpToken{

    GovernanceToken public govToken;
    UnderlyingToken public underlyingToken;
    //Exchange rate is no of Underlying assets per LP token
    uint public exchangeRate;
    //Gov Token to be rewarded per block per LP token
    uint public REWARD_PER_BLOCK;
    constructor(
        address _govToken, 
        address _underToken, 
        uint _exchangeRate, 
        uint RewardPerBlock) 
        public{
        
        govToken = GovernanceToken(_govToken);
        underlyingToken = UnderlyingToken(_underToken);
        exchangeRate = _exchangeRate;
        REWARD_PER_BLOCK = RewardPerBlock;
    }
    //Checkpoints to know when we last distributed rewards to a holder
    mapping(address => uint) public checkpoints;
    
    //Function to deposit underlying tokens and get LP tokens
    function deposit(uint amount) external{
        require(underlyingToken.balanceOf(msg.sender) >= amount,"Insufficient balance");
        if(checkpoints[msg.sender] == 0){
            checkpoints[msg.sender] = block.number;
        }
        //Distributing rewards accumulated by the user
        //Doing this before because this updates checkpoints
        _distributeRewards(msg.sender);
        //Transferring underlying tokens from user to this contract
        underlyingToken.transferFrom(msg.sender, address(this), amount);
        //Minting LP tokens of equivalent amount
        _mint(msg.sender, amount / exchangeRate);
    }

    //Function to withdraw underlying tokens by paying back LP tokens
    function withdraw(uint amount) external{
        
        //Checking if the balance of msg sender of LP tokens is sufficient
        require(balanceOf(msg.sender) >= amount, "Insufficient Balance");
        
        //Distributing rewards to the user
        //Doing this before because this updates checkpoints
        _distributeRewards(msg.sender);
        
        //Transferring underlying tokens to the user
        underlyingToken.transfer(msg.sender, amount*exchangeRate);
        
        //Burning LP tokens of the user
        _burn(msg.sender,amount);
    }

    //Function for distribution of rewards and updating checkpoints 
    function _distributeRewards(address beneficiary) internal{
        //Checking current checkpoint
        uint checkpoint = checkpoints[beneficiary];
        uint distributionAmount;

        if(checkpoint < block.number){
            //Calculating distribution amount
            distributionAmount = 
                balanceOf(beneficiary)*(block.number - checkpoint)*REWARD_PER_BLOCK;
        }
        
        //Minting govTokens for rewards to the user
        govToken.mint(beneficiary, distributionAmount);
        
        //Updating checkpoint for the user
        checkpoints[beneficiary] = block.number;
    }

}