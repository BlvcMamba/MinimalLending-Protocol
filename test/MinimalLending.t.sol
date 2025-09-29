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
        protocol.deposit(depositAmount);

        //check the user account updated 
        (uint256 deposited, uint256 borrowed, uint256 lastUpdate) = protocol.userAccounts(alice);
        assertEq(deposited, depositAmount);
        assertEq(borroed, 0);
        assertEq(lastUpdate, block.timestamp);

        //check token balance
        assertEq(token.balanceOf(alice), aliceBalanceBefore - depositAmount);
        assertEq(token.balanceOf(address(MLprotocol)), depositAmount);

        //check the protoco; state

        assertEq(protocol.totalDeposit(), depositAmount);
    }
}
