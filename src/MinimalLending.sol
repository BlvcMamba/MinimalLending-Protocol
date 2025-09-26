// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MininmalLending is ReentrancyGuard {

    struct UserAccount {
        uint256 deposited;
        uint256 borrowed;
        uint32 lastUpdatedTime;
    }

    IERC20 public immutable underlying_token;
    uint256 public constant COLLATERAL_RATIO = 150;
    uint256 public constant  ANNUAL_INTEREST_RATE = 10;
    uint256 public constant SECOND_PER_YEAR = 365 * 24 * 60 * 60;
    uint256 public constant LIQUIDAATION_THRESHOLD = 120;
    uint256 public constant LIQUIDATION_PENALTY = 10;

    uint256 public totalDeposits;
    uint256 public totalBorrows;

    mapping (address user => UserAccount account) userAccounts;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount); 
    event Repay(address indexed user, uint256 amount);
    event Liquidate(address indexed liquidator, address indexed user, uint256 debtAmount);

    error NotEnoughAmount();
    error NotEnoughWithdrawableAmount();
    error InsufficientDeposit();
    error CollateralRatioBroken();
    error TransferFailed();

    constructor (address _underlying_token) {
        underlying_token = IERC20(_underlying_token);
    }

    function deposit(uint256 _amount) external nonReentrant {
        require(_amount > 0, NotEnoughAmount());

        updateInterestRate(); //The function is yet to be built
        userAccounts[msg.sender].deposit += _amount;
        totalDeposits += _amount;

        require(token.transferFrom(msg,sender, address(this), _amount));

        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, NotEnoughWithdrawableAmount);

        _updateInterestRate(msg.sender); //still under construction

        UserAccount storage account = userAccounts[msg.sender];
        require(account.deposited >= _amount, InsufficientDeposit());

        //check if withdrawL mainatains healthy collateral ratio
        uint256 newDeposited = account.deposit - _amount;
        //Not written the logic of the healthyPossition
        require(isHealthyPosition(newDeposited, account.borrowed), CollateralRatioBroken());

        account.deposited = newDeposited;
        totalDeposits -= _amount;

        require(token.transferFrom(msg.sender, amount), TransferFailed());

        emit Withdraw(msg.sender, amount);


    }



}