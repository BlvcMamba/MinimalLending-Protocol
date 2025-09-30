// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/MinimalLending.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MinimalLendingToken is ERC20 {
    constructor () ERC20 ("MinimalLendingToken", "MLT") {
        _mint(msg.sender, 1000000 * 10**18); //1M token

    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}


contract LendingProtocolTest is Test {
    MinimalLending public  MLprotocol;

    MinimalLendingToken public token;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public blvcmamba = makeAddr("blvcmamba");

    uint256 constant INITIAL_BALANCE = 10000 * 1e18; //10 thousands token


    function setUp() public {
        token = new MinimalLendingToken();
        MLprotocol = new MinimalLending(address(token));

        //Give test users some tokens

        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);
        token.mint(blvcmamba, INITIAL_BALANCE);

        //approve protocol to spend tokens for all users

        vm.prank(alice);
        token.approve(address(MLprotocol), type(uint256).max);
        
        vm.prank(bob);
        token.approve(address(MLprotocol), type(uint256).max);

        vm.prank(blvcmamba);
        token.approve(address(MLprotocol), type(uint256).max);
    }


    /// DEPOSIT FUNCTION TEST

    function testDeposit_success() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 aliceBalanceBefore = token.balanceOf(alice);

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        //check the user account updated 
        (uint256 deposited, uint256 borrowed, uint256 lastUpdate) = MLprotocol.userAccounts(alice);
        assertEq(deposited, depositAmount);
        assertEq(borrowed, 0);
        assertEq(lastUpdate, block.timestamp);

        //check token balance
        assertEq(token.balanceOf(alice), aliceBalanceBefore - depositAmount);
        assertEq(token.balanceOf(address(MLprotocol)), depositAmount);

        //check the protoco; state

        assertEq(MLprotocol.totalDeposits(), depositAmount);
    }

    function testDposit_EmitEvents() public {
        uint256 depositAmount = 1000 * 1e18;
        vm.expectEmit(true, false, false, true);

        emit MinimalLending.Deposit(alice, depositAmount);

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);
    }

    function testDeposit_RevertOnZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("Amount must be greater than 0");
        MLprotocol.deposit(0);
    }

    function testDeposit_RevertOnInsufficientBalance() public {
        uint256 excessiveAmount = INITIAL_BALANCE + 1;

        vm.prank(alice);
        vm.expectRevert("ERC20: Transfer amount exceed balance");
        MLprotocol.deposit(excessiveAmount);
    }

    //======TEST WITHDRAWAL ======

    function testWithdrawal_success() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 withdrawAmount = 500 * 1e18;

        //first deposit
        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        uint256 aliceBalanceBefore = token.balanceOf(alice);

        //then withdraw
        vm.prank(alice);
        MLprotocol.withdraw(withdrawAmount);

        //check user account updated
        (uint256 deposited, ,) = MLprotocol.userAccounts(alice);
        assertEq(deposited, depositAmount - withdrawAmount);

        //check token balances

        assertEq(token.balanceOf(alice), aliceBalanceBefore - withdrawAmount);
        assertEq(MLprotocol.totalDeposits(), depositAmount - withdrawAmount);
    }

    function testWithdrawal_RevertsOnInsufficientDeposits() public {
        uint256 depositAmount = 500 * 1e18;
        uint256 withdrawAmount = 1000 * 1e18; //more than amoun deposited

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(alice);
        vm.expectRevert("Insufficient Deposit Amount");
        MLprotocol.withdraw(withdrawAmount);

    }

    function testWithdrawal_WhenWouldBreakCollateralRatio() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 1000 * 1e18; //borrow ax allowed
        uint256 withdrawAmount = 100 * 1e18;  //would break collateral ratio

        vm.startPrank(alice);
        MLprotocol.deposit(depositAmount);
        MLprotocol.borrow(borrowAmount);
        
        vm.expectRevert("Would break collateral Ratio");
        MLprotocol.withdraw(withdrawAmount);
        vm.stopPrank();
    }

    //======FUNCTION BORROW TEST====
    function testBorrow_success() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 1000 * 1e18; //within collateral Ratio

        //alice deposit and bob borrows

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        uint256 bobBalanceBefore = token.balanceOf(bob);

        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);

        //check user accounts
        (, uint256 borrowed, uint256 lastUpdate) = MLprotocol.userAccounts(bob);
        assertEq(borrowed, borrowAmount);
        assertEq(lastUpdate, block.timestamp);

        //check token balance

        assertEq(token.balanceOf(bob), bobBalanceBefore + borrowAmount);
        assertEq(MLprotocol.totalBorrows(), borrowAmount);
    }

    function testBorrow_RevertOnInSufficientLiquidity() public {
        uint256 borrowAmount = 1000 * 1e18;
        //No deposit in protocol means no liquidity

        vm.prank(alice);
        vm.expectRevert("Insufficient liquidity");
        MLprotocol.borrow(borrowAmount);
    }

    //===TEST REPAY FUNCTION ===

    function testRepay_success() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 1000 * 1e18;
        uint256 repayAmount = 500 * 1e18;

        //set up bob borrow position 

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);

        //repay part of the debt
        vm.prank(bob);
        MLprotocol.repay(repayAmount);

        //check user account
        (, uint256 borrowed, ) = MLprotocol.userAccounts(bob);
        assertEq(borrowed, borrowAmount - repayAmount);
        assertEq(MLprotocol.totalBorrows(), borrowAmount - repayAmount);
    }

    function testRepay_RevertOnExcessiveAmount() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 500 * 1e18;
        uint256 repayAmount = 1000 * 1e18; //more than amount borrowed

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);

        vm.prank(bob);
        vm.expectRevert("Repay Amount exceeds debt");
        MLprotocol.repay(repayAmount);
    }

    // ====== LIQUIDATION FUNCTION TEST =====
    
    function testLiquidate_success() public {
        uint256 depositAmount = 1200 * 1e18; //Just above liquidation threshold
        uint256 borrowAmount = 1000 * 1e18;

        //setup position at liquidation threshold
        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(alice);
        MLprotocol.borrow(borrowAmount);

        //simulate interest accrual to push below threshold
        vm.warp(block.timestamp + 365 days); //1year later

        //check position is liquidatable
        uint256 healthFactor = MLprotocol.getHealthFactor(alice);
        assertLt(healthFactor, 100);

        uint256 blvcmambaBalanceBefore = token.balanceOf(blvcmamba);

        //blvcmamba liquidates alice
        vm.prank(blvcmamba);

        MLprotocol.liquidate(alice);

        //check alice's position is cleared
        (uint256 deposited, uint256 borrowed,) = MLprotocol.userAccounts(alice);
        assertEq(borrowed, 0);
        assertEq(deposited, depositAmount); //some collateral to be seozed

        //Check blvcmamba received the liquidated collateral
        assertEq(token.balanceOf(blvcmamba), blvcmambaBalanceBefore); 
    }

    function testLiquidate_RevertOnHealthyPosition() public {
        uint256 depositAmount = 2000 * 1e18; //High collateral
        uint256 borrowAmount = 1000 * 1e18;

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(alice);
        MLprotocol.borrow(borrowAmount);

        vm.prank(blvcmamba);
        vm.expectRevert("Position is Healthy");
        MLprotocol.liquidate(alice);

    }

    //======== VIEW FUNCTION TEST===========
    function testGetAvailableLiquidity() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 borrowAmount = 600 * 1e18;

        //Initially no liquidity
        assertEq(MLprotocol.getAvailableLiquidity(), 0);

        //AFTER deposit
        vm.prank(alice);
        MLprotocol.deposit(depositAmount);
        assertEq(MLprotocol.getAvailableLiquidity(), depositAmount);


        //After deposit
        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);
        assertEq(MLprotocol.getAvailableLiquidity(), depositAmount - borrowAmount);

    }

    function testHealthFactor() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 1000 * 1e18;

        //Before borrowing should be max
        assertEq(MLprotocol.getHealthFactor(alice), type(uint256).max);

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);


        //Health Factor should be 150% (1500/1000) * 100
        assertEq(MLprotocol.getHealthFactor(alice), 150);
    }

    //===========TEST INTEREST ACCRUAL ============

    function testInterestAccrual() public {
        uint256 depositAmount = 1500 * 1e18;
        uint256 borrowAmount = 1000 * 1e18;

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        vm.prank(bob);
        MLprotocol.borrow(borrowAmount);

        uint256 debtBefore = MLprotocol.getCurrentDebt(alice);

        //Move forward 1year
        vm.warp(block.timestamp + 365 days);
        uint256 debtAfter = MLprotocol.getCurrentDebt(alice);

        //Debt should have already be increased by ~10%(annual interest rate)
        uint256 expectedInterest = (borrowAmount * 10) / 100; //10 percent of 1000
        assertApproxEqAbs(debtAfter, debtBefore + expectedInterest, 1e15); //Allowing small rounding error;


    }

    //=============== INTEGRATION TEST ======================
    function testCompleteUserJourney() public {
        uint256 depositAmount = 2000 * 1e18;
        uint256 borrowAmount = 1000 * 1e18;
        uint256 repayAmount = 500 * 1e18;
        uint256 withdrawAmount = 500 * 1e18;

        //Alce deposits
        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        //Alice Borrows
        vm.prank(alice);
        MLprotocol.borrow(borrowAmount);

        //checking health factor
        assertEq(MLprotocol.getHealthFactor(alice), 200); //2000/1000 *100

        //Alice Repays part of the debt;
        vm.prank(alice);
        MLprotocol.repay(repayAmount);


        //Alice then withdraw some collateral
        vm.prank(alice);
        MLprotocol.withdraw(withdrawAmount);

        //verifying final state
        (uint256 finalDeposited, uint256 finalBorrowed, ) = MLprotocol.userAccounts(alice);
        assertEq(finalDeposited, depositAmount - withdrawAmount);
        assertEq(finalBorrowed, borrowAmount - repayAmount);

    }

    function testWithdrawalReentrancy() public {
        ///more code...
    }
}
