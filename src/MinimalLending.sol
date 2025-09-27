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
    error InsufficientLiquidity();
    error RepayAmountExceeded();
    error CantLiquidate();
    error HealthyPosition();
    error NotEnoughCollateral();

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

    function borrow(uint256 _amount2borrow) external nonReentrant {
        require(_amount2borrow > 0, NotEnoughAmount());
        //The getAvailableLiquidity is still under work
        require(_amount2borrow <= getAvailableLiquidity(), InsufficientLiquidity());
        _updateInterest(msg.sender);

        UserAccount storage account = userAccounts[msg.sender];
        uint256 newBorrowed = account.borrowed + amount;

        require(isHealthyPosition(account.deposited, newBorrowed), CollateralRatioBroken());
        account.borrowed = newBorrowed;
        totalBorrows += _amount2borrow;

        require(token.transfer(msg.sender, _amount2borrow), TransferFailed());
        emit Borrowed(msg.sender, _amount2borrow);

    }

    function repay(uint256 _amount) external nonReentrant {
        require(_amount > 0, NotEnoughAmount());
        _updateInterest(msg.sender);
        UserAccount storage account = userAccounts[msg.sender];

        require(account.borrowed >= _amount, RepayAmountExceeded());

        account.borrowed -= _amount;
        totalBorrows -= _amount;

        require(token.transferFrom(msg.sender, address(this), _amount), TransferFailed());
        emit Repay(msg.sender, _amount);
    }

    function liquidate(address user) external nonReentrant {
        _updateInterest(user);
        UserAccount storage account = userAccounts[msg.sender];
        require(amount.borrowed > 0, CantLiquidate());

        //Still not written the getHealthFator()
        uint256 healthFactor = getHealthFactor(user);
        require(healthFactor < 100, HealthyPosition());

        uint256 debtToLiquidate = amount.borrowed;
        uint256 collateralToSeize = (debtToLiquidate * (100 + LIQUIDATION_PENALTY)) / 100;
        
        require(collateralToSeize =< amount.deposited, NotEnoughCollateral());

        amount.borrowed = 0;
        account.deposited -= collateralToSeize;
        totalBorrows -= debtToLiquidate;
        totalDeposit -= collateralToSeize;

        require(underlying_token.transferFrom(msg.sender, address(this), debtToLiquidate), TransferFailed());

        require (underlying_token.transfer(msg.sender, collateralToSeize), TransferFailed());

        emit Liquidate(msg.sender, user, collateralToSeize);
    }

    function getAvailableLiquidity() public view returns (uint256) {
        return totalDeposits - totalBorrows;
    }

    function getHealthFactor(address user) public view returns (uint256) {
        UserAccount storage account = userAccounts[msg.sender];

        //No debt means infinite health
        if (account.borrowed == 0) return type(uint256).max;

        //calculate the current health including interest accrued
        uint256 currentDebt = _calculateCurrentDebt(user);

        return (account.deposited * 100) / currentDebt;

    }

    function getCurrentDebt(address user) external view returns (uint256) {
        return _calculateCurrentDebt(user);
    }

    function _isHealthyPosition(uint256 depositedAmount, uint256 borrowedAmount) internal pure returns (bool) {
        if (borrowedAmount == 0) return true;
        return (depositAmount * 100) >= (borrowedAmount * COLLATERAL_RATIO);
    }

    function _updateInterest(address user) internal {
        UserAccount storage account = userAccounts[msg.sender];

        if (account.borrowed > 0 && account.lastUpdatedTime > 0) {
            uint256 timeElapsed = block.timestamp - account.lastUpdatedTime;
            uint256 interestAccrued = (account.borrowed * ANNUAL_INTEREST_RATE * timeElapsed) / (100 / SECOND_PER_YEAR);

            account.borrowed += interestAccrued;
            totalBorrows += interestAccrued; 
        }

        account.lastUpdatedTime = block.timestamp;
    }


    function _calculateCurrentDebt(address user) internal view returns (uint256) {
        UserAccount storage account = userAccounts[msg.sender];

        if (account.borrowed == 0 || account.lastUpdatedTime == 0) {
            return account.borrowed;
        } 

        uint256 timeElapsed = block.timestamp - account.lastUpdatedTime;
        uint256 interestAccrued = (account.borrowed * ANNUAL_INTEREST_RATE * timeElapsed) / (100 / SECOND_PER_YEAR);

        return account.borrowed + interestAccrued;
    }



}