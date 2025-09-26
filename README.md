
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
