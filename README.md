
## Minimal Lending Protocol
A minimal decentralized lending and borrowing protocol built for educational purposes and security research. This protocol demonstrates core decentralized finance lending mechanics including collaterallized borrowing, interest accrual and liquidations.

## Overview
The Minimal lending protocol allows users to:
- Deposit `ERC20` tokens as collateral.
- Borrow tokens against their collateral
- Repay borrowed amount with accrued interest
- Withdraw collateral when health conditions are met
- Liquidate undercollaterized positions

## Architecture
**The core components**
- **Single Token System**: The protocol operates with one `ERC20` token that serves both as collateral and borrowing asset.
- **Overcollaterized Lending**: Borrowers must maintain a 150% collateralization ratio.
- **Interest Accural**: 10% annual interest rate on borrowed amounts.
- **Liquidation Mechanism** : Positions become liquidatable below 120% collateral ratio.

## key Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| **Collateral Ratio** | 150% | Required collateral to debt ratio for borrowing |
| **Liquidation Threshold** | 120% | Health ratio below which positions can be liquidated |
| **Annual Interest Rate** | 10% | Interest charged on borrowed amounts |
| **Liquidation Penalty** | 10% | Bonus for liquidators |

### Core Functions

__User Operations__

`deposit(uint256 amount)`

- Deposit tokens as collateral 
- Updates user's deposited balance
- Requires token approval

`withdraw(uint256 amount)`

- Withdraw deposited tokens
- Validates that the withdrawal maintains healthy collateral ratio.
- Fails if a user has insufficient deposits or would break collateralization.

`borrow`(uint256 amount)`

- Borrows tokens against deposited collateral 
- Requires maintaining the 150% collateral ratio.'
- Limited by available protocol liquidity
- Start accruing interest immediately

`repay(uint256 amount)`

- Repay borrowed tokens plus accrued interests.
- Reduces user's debt balances
- Must not exceed current debt amount.


`liquidate(address user)`

- Liquidates undercollaterized positions (health factor < 100%)
- Liquidator pays the user's debt
- Receives user's collateral plus 10% penalty
- Completely clears the user's position


__View Functions__

`getHealthFactor(address user)`

- Returns user's collateralization ratio as percentage
- Formula: `(deposited * 100)/ cuurentDebt`
- Values below 100%% shows that a position is liquidatable 


`getCuurentDebt(address user)`

- Returns user's total debt including aacrued interest
- INterest compounds continously based on time elapsed.


`getAvailableLiquidity()`

- Returna available for borrowing.
- Fomula: `totalDeposits - totalBorrow`


### Protocol Mechanics

__Interest Calculation__

Interest accrues continuously using the formula:

```
interestAccrued = (borrowed * annualRate * timeElapsed) / (100 * secondsPerYear)
```

Interest is updated whenever a user interacts with the protocol through `_updateInterest()`
