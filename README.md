
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


## Protocol Mechanics

__Interest Calculation__

Interest accrues continuously using the formula:

```
interestAccrued = (borrowed * annualRate * timeElapsed) / (100 * secondsPerYear)
```

Interest is updated whenever a user interacts with the protocol through `_updateInterest()`

### Health Factor

A user's health is measured by their collateralization ratio:
- If greater than(CR > 150): 150% can borrow more
- 120% -150%: Healthy but cannot borrow more.
- If lesser than < 120%(CR < 120): Liquidatable positions


### Liquidation Process

1. Anyone can liquidate positions with health factor < 100%
2. Liquidator pays the full debt amount
3. Liquidator receives collateral + 10% penalty
4. User's position is completely cleared.


### User Account Structure

```solidity

struct UserAccount {
    uint256 deposited;   //The collateral that was deposited
    uint256 borrowed;    // The amount borrowed excluding (accrued interest)
    uint256 lastUpdatedTime;  //The last Interest calculation timestamp
}
```


### Security
This protocol is built for educational purposes and contains several potential vulnerabilities and its therefore not advisable for anyone to fork and use for any production code.
It will mostly contain bugs and would have unit test that confirms these kind of bugs.

1. __Single Token Risk__: No price oracle means no protection against token volatility
2. __Interest Rate Model__ : Fixed 10% rate regardless of utilization
3. __Liquidation Mechanics__ : Full liquidation only, no partial Liquidation
4. __Flashloan Attacks__: No protection against same transaction exploit
5. __Precision Issues__ : Potential Rounding error in calculations


### 🛠️ Development Setup
__Prerequisites__

- [Foundry](https://getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)

### Installation

```bash
# Clone the repository
git clone https://github.com/BlvcMamba/MinimalLending-Protocol
cd MinimalLendingProtocol

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Run tests
forge test

# Run specific test
forge test --match-test testDeposit_Success
```

### Project Structure

```
src/
├── SimpleLendingProtocol.sol    # Main protocol contract
test/
├── SimpleLendingProtocol.t.sol  # Comprehensive test suite
├── SecurityTests.sol            # Vulnerability testing
```
