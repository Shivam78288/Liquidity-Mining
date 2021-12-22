const {expextRevert} = require("@openzeppelin/test-helpers");
const { time } = require('@openzeppelin/test-helpers');
const expectRevert = require("@openzeppelin/test-helpers/src/expectRevert");

const { web3 } = require("@openzeppelin/test-helpers/src/setup");
const GovernanceToken = artifacts.require("GovernanceToken.sol");
const UnderlyingToken = artifacts.require("UnderlyingToken.sol");
const LiquidityPool = artifacts.require("LiquidityPool.sol");

contract ("LiquidityMining", (accounts) => { 
    let govToken, underlyingToken, liquidityPool;
    const [account1, account2] = [accounts[0], accounts[1]];
    beforeEach(async() =>{
        govToken = await GovernanceToken.new();
        underlyingToken = await UnderlyingToken.new();
        liquidityPool = await LiquidityPool.new(
                                    govToken.address,
                                    underlyingToken.address,
                                    1,
                                    1,
                                );
        await govToken.transferOwnership(liquidityPool.address);
        
        const seedTokenBalance = async(trader) => {
            await underlyingToken.faucet(trader, web3.utils.toWei("100")),
            await underlyingToken.approve(liquidityPool.address, web3.utils.toWei("100"), {from: trader})
            }
        await Promise.all(
            [account1, account2].map(account => seedTokenBalance(account))
            );
                        
    });


    it("Should deposit underlying tokens and get LP tokens", async()=>{
        await liquidityPool.deposit(web3.utils.toWei("20"), {from: account2});
        let myLpBalance = await liquidityPool.balanceOf(account2);
        assert(myLpBalance.toString() === web3.utils.toWei("20"));
    });

    it("Should mint 4*20 = 80 gov tokens and update checkpoints", async() => {
        await liquidityPool.deposit(web3.utils.toWei("20"), {from: account2});
        let oldCheckpoint = await liquidityPool.checkpoints(account2);
        await time.advanceBlock();
        await time.advanceBlock();
        await time.advanceBlock();
        await liquidityPool.withdraw(web3.utils.toWei('10'), {from: account2});
        let balanceUnderlying = await underlyingToken.balanceOf(account2);
        let newCheckpoint = await liquidityPool.checkpoints(account2);
        const balanceGovToken = await govToken.balanceOf(account2);
        const myLpBalance = await liquidityPool.balanceOf(account2);
        assert(balanceGovToken.toString() === web3.utils.toWei('80'));
        assert(myLpBalance.toString() === web3.utils.toWei('10'));     
        assert((newCheckpoint - oldCheckpoint).toString() === "4");
        //Initially 100, then deposited 20 and withdrew 10. So total must be 90
        assert(balanceUnderlying.toString() === web3.utils.toWei("90"));
    });

    it("Should not withdraw if balance too low", async()=>{
        await expectRevert(
            liquidityPool.withdraw(web3.utils.toWei("20")),
            "Insufficient Balance"
        );
    });

});