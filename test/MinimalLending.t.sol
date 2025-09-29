// SPDX-License-Identifier: MIT

pragma solidity ^0.8.29;

import "forge-std/Test.sol";
import "../src/MinimalLending.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";


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


    function SetUp() public {
        token = new MinimalLendingToken();
        MLprotocol = new MinimalLending();

        //Give test users some tokens

        token.mint(alice, INITIAL_BALANCE);
        token.mint(bob, INITIAL_BALANCE);
        token.mint(blvcmamba, INITIAL_BALANCE);

        //approve protocol to spend tokens for all users

        vm.prank(alice);
        token.approve(address(protoco), type(uint256).max);
        
        vm.prank(bob);
        token.approve(address(protocol), type(uint256).max);

        vm.prank(blvcmamba);
        token.approve(address(protocol), type(uint256).max);
    }


    /// DEPOSIT FUNCTION TEST

    function testDeposit_success() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 aliceBalanceBefore = token.balance(alice);

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);

        //check the user account updated 
        (uint256 deposited, uint256 borrowed, uint256 lastUpdate) = protocol.userAccounts(alice);
        assertEq(deposited, depositAmount);
        assertEq(borroed, 0);
        assertEq(lastUpdate, block.timestamp);

        //check token balance
        assertEq(token.balanceOf(alice), aliceBalanceBefore - depositAmount);
        assertEq(token.balanceOf(address(MLprotocol)), depositAmount);

        //check the protoco; state

        assertEq(MLprotocol.totalDeposit(), depositAmount);
    }

    function testDposit_EmitEvents() public {
        uint256 depositAmount = 1000 * 1e18;
        vm.expectEmit(true, false, false, true);

        emit MinimalLending.deposit(alice, depositAmount);

        vm.prank(alice);
        MLprotocol.deposit(depositAmount);
    }

    function testDeposit_RevertOnZeroAmount() public {
        vm.prank(alice);
        vm.expectRevert("Amount must be greater than 0");
        protocol.deposit(0);
    }

    function testDeposit_RevertOnInsufficientBalance() public {
        uint256 excessiveAmount = INITIAL_BALANCE + 1;

        vm.prank(alice);
        vm.expectRevert("ERC20: Transfer amount exceed balance");
        protocol.deposit(excessiveAmount);
    }

    //======TEST WITHDRAWAL ======

    function testWithdrawal_success() public {
        uint256 depositAmount = 1000 * 1e18;
        uint256 withdrawAmount = 500 * 1e18;

        //first deposit
        vm.prank(alice);
        MLprotocol.withdraw(withdrawAmount);

        //check user account updated
        (uint256 deposited, ,) = protocol.userAccounts(alice);
        assertEq(deposited, depositAmount - withdrawAmount);

        //check token balances

        assertEq(token.balanceOf(alice), aliceBalanceBefore - withdrawAmount);
        assertEq(MLprotocol.totalDeposit(), depositAmount - withdrawAmount);
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
}
