# NFTForge Protocol

A sophisticated NFT smart contract implementation on Stacks blockchain that features dynamic minting algorithms and NFT upgrading mechanics.

## Features

### Dynamic Minting Algorithm
- Real-time adjustment of minting limits based on market metrics
- Factors considered:
  - Number of active holders
  - Trading volume
  - Floor price
  - Market multiplier
  - Time-based cooldowns

### NFT Upgrading System
- Burn-to-upgrade mechanism
- Level-based NFT system
- Rarity enhancement through token burning
- Automated scarcity management

### Market Analytics
- Real-time floor price tracking
- Volume analytics
- Holder activity monitoring
- Price point history
- Market health indicators

## Technical Architecture

### Core Components

1. **Token Management**
```clarity
(define-map tokens 
    {token-id: uint} 
    {owner: principal, level: uint, metadata-uri: (string-ascii 256)})
```

2. **Market Metrics**
```clarity
(define-data-var floor-price uint u100000000)
(define-data-var total-volume uint u0)
(define-data-var active-holders uint u0)
(define-data-var market-multiplier uint u100)
```

3. **Holder Analytics**
```clarity
(define-map holder-activity 
    principal 
    {last-transfer: uint, transfer-count: uint})
```

### Security Features

1. Input Validation
- URI validation
- Token ID verification
- Parameter bounds checking
- Owner authorization

2. Error Handling
- Comprehensive error codes
- Transaction validation
- State consistency checks

3. Access Control
- Owner-only functions
- Transfer authorization
- Pause mechanism

## Getting Started

### Prerequisites
- Clarinet (latest version)
- Node.js (for testing)
- Stacks CLI tools

### Installation

1. Clone the repository
```bash
git clone https://github.com/your-username/nft-forge-protocol.git
cd nft-forge-protocol
```

2. Install dependencies
```bash
npm install
```

3. Run Clarinet check
```bash
clarinet check
```

### Contract Deployment

1. Configure deployment settings in `Clarinet.toml`

2. Deploy to testnet
```bash
clarinet deploy --testnet
```

## Usage Guide

### Minting NFTs

```clarity
(contract-call? .nft-forge mint "metadata-uri")
```

Parameters:
- metadata-uri: String (max 256 chars) containing the NFT metadata URI

### Upgrading NFTs

```clarity
(contract-call? .nft-forge upgrade-nft u1 u2)
```

Parameters:
- token-id: ID of the token to upgrade
- burn-token-id: ID of the token to burn

### Transferring NFTs

```clarity
(contract-call? .nft-forge transfer u1 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

Parameters:
- token-id: ID of the token to transfer
- recipient: Principal to receive the token

## Market Dynamics

### Dynamic Minting Formula

The market multiplier is calculated using:
```clarity
(+ base-multiplier (+ holder-factor (/ volume-factor u100)))
```

Where:
- holder-factor = (active-holders * 100) / max-supply
- volume-factor = total-volume / floor-price
- base-multiplier = 100

### Scarcity Mechanism

The dynamic mint limit is determined by:
```clarity
(/ (* max-supply market-multiplier) u100)
```

## Contract Administration

### Owner Functions

1. Set Mint Cooldown
```clarity
(contract-call? .nft-forge set-mint-cooldown u100)
```

2. Set Floor Price
```clarity
(contract-call? .nft-forge set-floor-price u100000000)
```

3. Toggle Contract Pause
```clarity
(contract-call? .nft-forge toggle-contract-pause)
```

## Error Codes

- u100: Owner only operation
- u101: Not token owner
- u102: Token ID not found
- u103: Insufficient tokens
- u104: Mint limit reached
- u105: Invalid sender
- u106: Not authorized
- u107: Market cooldown
- u108: Below floor price
- u109: Invalid token ID
- u110: Invalid URI
- u111: Invalid parameter

## Testing

Run the test suite:
```bash
clarinet test
```

### Test Coverage
- Minting functionality
- Transfer operations
- Upgrade mechanics
- Market dynamics
- Error handling
- Access control

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Security Considerations

1. Input Validation
- All public functions validate inputs
- URI format checking
- Token ID bounds checking

2. Access Control
- Owner-only functions protected
- Transfer authorization checks
- Pause mechanism for emergencies

3. State Management
- Atomic operations
- Balance consistency checks
- Market metric validation


## Support

For support, please open an issue in the GitHub repository 

## Acknowledgments

- Stacks Blockchain team
- Clarity language developers
- NFT standards contributors