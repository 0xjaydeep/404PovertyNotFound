# Uniswap V4 Integration Requirements & TODO

## Project Overview
Integration of Uniswap V4 hooks into the 404 Poverty Not Found DeFi investment platform to enable automated salary-based contributions to Real World Assets (RWAs) through custom hook mechanisms.

## Architecture Requirements

### Core Components Needed

#### 1. Uniswap V4 Dependencies
- **@uniswap/v4-core**: Core pool management contracts
  - `IPoolManager` interface
  - `PoolKey` and `PoolId` types
  - `Hooks` library for permissions
  - `SwapParams` and `ModifyLiquidityParams` structs
- **@uniswap/v4-periphery**: Helper contracts and utilities
- **BaseHook**: Foundation contract for custom hooks
- **CREATE2 deployment**: For deterministic hook addresses

#### 2. Hook Contract Structure
```solidity
contract InvestmentHook is BaseHook {
    // Required implementation based on v4-template Counter.sol pattern

    // Core hook functions:
    - beforeSwap()     // Compliance validation
    - afterSwap()      // Investment execution
    - beforeAddLiquidity() // LP management
    - afterAddLiquidity()  // LP tracking
    - getHookPermissions() // Define hook flags
}
```

#### 3. Hook Permissions Configuration
- `beforeSwap: true` - For compliance checks and trade validation
- `afterSwap: true` - For automated investment execution
- `beforeAddLiquidity: true` - For LP position management
- `afterAddLiquidity: true` - For LP tracking and rebalancing
- Additional permissions as needed for compliance

## Functional Requirements

### 1. Automated Investment Execution
- **Trigger**: User swaps in designated pools
- **Action**: Automatically allocate percentage of swap value to investment plans
- **Integration**: Call InvestmentEngine.invest() from afterSwap hook
- **Compliance**: Validate user eligibility and plan limits

### 2. Compliance Integration (ERC-3643)
- **Pre-trade Validation**: Check user compliance status in beforeSwap
- **KYC Verification**: Integrate with existing compliance systems
- **Geographic Restrictions**: Block trades from restricted jurisdictions
- **Investment Limits**: Enforce position and exposure limits

### 3. Liquidity Position Management
- **LP Token Tracking**: Monitor user LP positions across pools
- **Rebalancing Triggers**: Detect when LP positions drift >5% from targets
- **Automated Rebalancing**: Execute rebalancing through hook mechanisms
- **Fee Collection**: Collect fees for investment pool funding

### 4. Integration with Existing Contracts

#### InvestmentEngine Integration
- **Function Calls**: Hook calls InvestmentEngine.invest() after swaps
- **Data Passing**: Transfer swap data, user info, and investment amounts
- **Error Handling**: Graceful fallback if investment fails
- **Gas Optimization**: Minimize gas costs in hook execution

#### PlanManager Integration
- **Plan Lookup**: Retrieve user investment plans and allocations
- **Risk Validation**: Ensure swaps don't violate risk limits
- **Plan Updates**: Trigger plan rebalancing based on swap activity

#### Portfolio Tracker Integration
- **Position Updates**: Update portfolio positions after investments
- **Performance Tracking**: Track investment performance metrics
- **Reporting**: Generate investment reports and tax documents

## Technical Implementation Plan

### Phase 1: Core Hook Development
```
TODO Status: [pending]
```

#### 1.1 Set Up Uniswap V4 Dependencies
- [ ] Install @uniswap/v4-core and v4-periphery packages
- [ ] Configure Foundry for V4 development
- [ ] Set up proper remappings for V4 imports
- [ ] Test basic V4 integration with sample hook

#### 1.2 Create Base Investment Hook Contract
- [ ] Implement BaseHook extension
- [ ] Define hook permissions bitmap
- [ ] Implement basic beforeSwap/afterSwap structure
- [ ] Add state variables for investment tracking

#### 1.3 Hook Deployment Infrastructure
- [ ] Implement CREATE2 deployment pattern
- [ ] Create salt mining for proper hook flags
- [ ] Set up deployment scripts for hook contract
- [ ] Configure hook address verification

### Phase 2: Investment Automation
```
TODO Status: [pending]
```

#### 2.1 Swap-Based Investment Logic
- [ ] Implement afterSwap investment execution
- [ ] Calculate investment amounts from swap values
- [ ] Integrate with InvestmentEngine.invest()
- [ ] Handle multiple asset class investments

#### 2.2 Compliance Validation
- [ ] Implement beforeSwap compliance checks
- [ ] Integrate ERC-3643 compliance verification
- [ ] Add KYC status validation
- [ ] Implement geographic restrictions

#### 2.3 Error Handling & Fallbacks
- [ ] Graceful handling of failed investments
- [ ] Fallback mechanisms for compliance failures
- [ ] Gas limit management for hook calls
- [ ] Emergency pause functionality

### Phase 3: Liquidity Management
```
TODO Status: [pending]
```

#### 3.1 LP Position Tracking
- [ ] Implement beforeAddLiquidity/afterAddLiquidity hooks
- [ ] Track user LP positions and values
- [ ] Monitor position drift from target allocations
- [ ] Calculate rebalancing requirements

#### 3.2 Automated Rebalancing
- [ ] Implement rebalancing trigger logic (>5% drift)
- [ ] Execute automated rebalancing through hooks
- [ ] Optimize gas costs for rebalancing operations
- [ ] Handle partial rebalancing scenarios

#### 3.3 Fee Management
- [ ] Implement fee collection mechanisms
- [ ] Route fees to investment pool
- [ ] Calculate performance-based fees
- [ ] Handle fee distribution to stakeholders

### Phase 4: Integration & Testing
```
TODO Status: [pending]
```

#### 4.1 Contract Integration
- [ ] Integrate hook with existing InvestmentEngine
- [ ] Connect to PlanManager for plan data
- [ ] Link with Portfolio Tracker for position updates
- [ ] Test end-to-end investment flow

#### 4.2 Comprehensive Testing
- [ ] Unit tests for all hook functions
- [ ] Integration tests with V4 pools
- [ ] Gas optimization testing
- [ ] Security audit preparation

#### 4.3 Deployment & Configuration
- [ ] Deploy hook to testnet
- [ ] Configure pools with custom hook
- [ ] Set up monitoring and analytics
- [ ] Prepare mainnet deployment

## Smart Contract Files to Create

### 1. Core Hook Contract
```
File: solidity/src/hooks/InvestmentHook.sol
Purpose: Main hook contract for investment automation
Dependencies: BaseHook, IPoolManager, InvestmentEngine
```

### 2. Hook Interfaces
```
File: solidity/src/interfaces/IInvestmentHook.sol
Purpose: Interface definition for investment hook
Functions: Investment triggers, compliance checks, LP management
```

### 3. Hook Factory
```
File: solidity/src/hooks/InvestmentHookFactory.sol
Purpose: Factory for deploying investment hooks with proper salts
Dependencies: CREATE2, hook deployment utilities
```

### 4. Compliance Module
```
File: solidity/src/hooks/ComplianceModule.sol
Purpose: ERC-3643 compliance validation for hooks
Functions: KYC checks, geographic restrictions, investment limits
```

### 5. Test Contracts
```
Files: solidity/test/hooks/
Purpose: Comprehensive testing for hook functionality
Coverage: Unit tests, integration tests, gas optimization
```

## Dependencies & Setup Requirements

### 1. Package Dependencies
```toml
# Add to foundry.toml remappings
'@uniswap/v4-core/=lib/v4-core/'
'@uniswap/v4-periphery/=lib/v4-periphery/'
'@openzeppelin/=lib/openzeppelin-contracts/'
```

### 2. Required Libraries
- forge-std (already installed)
- @uniswap/v4-core
- @uniswap/v4-periphery
- @openzeppelin/contracts (for security and utilities)

### 3. Development Tools
- Foundry (forge, cast, anvil) - already configured
- V4 testing utilities
- Hook deployment scripts
- Gas profiling tools

## Integration Architecture

```
User Swap Request
        ↓
    Pool Manager
        ↓
   Investment Hook
        ↓
┌─────────────────┐    ┌────────────────┐    ┌─────────────────┐
│  beforeSwap()   │ -> │ Compliance     │ -> │ Validation      │
│  - KYC Check    │    │ Module         │    │ Result          │
│  - Geo Check    │    │                │    │                 │
│  - Limits Check │    │                │    │                 │
└─────────────────┘    └────────────────┘    └─────────────────┘
        ↓
   Execute Swap
        ↓
┌─────────────────┐    ┌────────────────┐    ┌─────────────────┐
│  afterSwap()    │ -> │ Investment     │ -> │ Portfolio       │
│  - Calc Amount  │    │ Engine         │    │ Tracker         │
│  - Execute      │    │                │    │                 │
│  - Track LP     │    │                │    │                 │
└─────────────────┘    └────────────────┘    └─────────────────┘
```

## Risk Considerations

### 1. Gas Optimization
- Hook calls must be gas-efficient
- Batch operations where possible
- Implement gas limit safeguards
- Optimize for common use cases

### 2. Security Concerns
- Reentrancy protection in hook calls
- Proper access controls for administrative functions
- Validation of all external calls
- Emergency pause mechanisms

### 3. Compliance Risks
- Ensure proper KYC validation
- Handle compliance failures gracefully
- Maintain audit trails for regulatory compliance
- Regular compliance system updates

## Success Metrics

### 1. Functional Metrics
- [ ] Successful automated investment execution rate >95%
- [ ] Compliance validation accuracy 100%
- [ ] Gas costs per hook call <50k gas
- [ ] LP rebalancing trigger accuracy >99%

### 2. Performance Metrics
- [ ] Hook deployment success on testnet
- [ ] Integration test pass rate 100%
- [ ] Zero critical security vulnerabilities
- [ ] Documentation coverage >90%

## Current Status

- ✅ **Research Phase**: Uniswap V4 architecture analysis complete
- 🔄 **Dependency Analysis**: In progress
- ❌ **Implementation**: Not started
- ❌ **Testing**: Not started
- ❌ **Deployment**: Not started

---

*Last Updated*: September 27, 2025
*Branch*: feature/uniswap-v4-integration
*Priority*: High - Core platform functionality