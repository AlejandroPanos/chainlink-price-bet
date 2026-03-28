# PriceBet

A Solidity smart contract built as a Foundry practice project. Two players bet ETH against each other on whether the ETH/USD price will be above or below a target price at settlement time. The first player opens the bet and picks a side, the second player takes the opposite side, and anyone can trigger settlement once the duration has passed. Integrates Chainlink price feeds with HelperConfig for multi-network deployment support.

---

## What It Does

- Player 1 opens a bet by setting a target USD price, a duration, and choosing High or Low
- Player 2 joins by taking the opposite side and matching the wager exactly
- Anyone can trigger settlement once the duration has passed
- The contract fetches the live ETH/USD price from Chainlink at settlement time
- The winner receives the entire pot
- Direct ETH transfers to the contract are rejected
- All state is reset after settlement, allowing a new bet to be opened

---

## Project Structure

```
.
├── src/
│   └── PriceBet.sol                    # Main contract
├── script/
│   ├── DeployPriceBet.s.sol            # Foundry deploy script
│   └── HelperConfig.s.sol              # Network configuration and mock deployment
└── test/
    ├── unit/
    │   └── TestPriceBet.t.sol          # Unit tests
    └── mocks/
        └── MockV3Aggregator.sol        # Fake Chainlink price feed for local testing
```

---

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed

### Install dependencies and build

```bash
forge install
forge build
```

### Run tests

```bash
forge test
```

### Run tests with gas report

```bash
forge test --gas-report
```

### Run tests with coverage report

```bash
forge coverage
```

### Deploy to a local Anvil chain

In one terminal, start Anvil:

```bash
anvil
```

In another terminal, run the deploy script:

```bash
forge script script/DeployPriceBet.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Deploy to Sepolia

```bash
forge script script/DeployPriceBet.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Contract Overview

### Bet Lifecycle

```
Idle -> Opened -> Ongoing -> Settled -> Idle
```

- Idle: no active bet, contract is ready for a new one
- Opened: Player 1 has opened a bet, waiting for Player 2
- Ongoing: both players have joined, waiting for settlement time
- Settled: winner has been paid, state resets to Idle

### State

| Variable          | Type                    | Description                                        |
| ----------------- | ----------------------- | -------------------------------------------------- |
| `s_priceFeed`     | `AggregatorV3Interface` | Chainlink price feed for ETH/USD                   |
| `s_state`         | `State`                 | Current lifecycle state of the bet                 |
| `s_playerOne`     | `address`               | Address of the player who opened the bet           |
| `s_playerTwo`     | `address`               | Address of the player who joined the bet           |
| `s_playerOneSide` | `Side`                  | Side chosen by Player 1 (High or Low)              |
| `s_playerTwoSide` | `Side`                  | Side chosen by Player 2 (High or Low)              |
| `s_targetPrice`   | `int256`                | Target ETH/USD price in Chainlink 8-decimal format |
| `s_wagerBet`      | `uint256`               | ETH amount each player must contribute             |
| `s_betDuration`   | `uint256`               | Duration in seconds before settlement is allowed   |
| `s_startTime`     | `uint256`               | Timestamp when the bet was opened                  |
| `s_winner`        | `address`               | Address of the winner after settlement             |
| `MIN_AMOUNT`      | `uint256`               | Minimum wager amount (0.1 ETH)                     |
| `MIN_DURATION`    | `uint256`               | Minimum bet duration (1 day)                       |

### Enums

| Enum    | Values                         | Description                            |
| ------- | ------------------------------ | -------------------------------------- |
| `Side`  | High, Low                      | The side a player bets on              |
| `State` | Idle, Opened, Ongoing, Settled | The current lifecycle state of the bet |

### Functions

| Function                                                         | Visibility         | Description                                                                           |
| ---------------------------------------------------------------- | ------------------ | ------------------------------------------------------------------------------------- |
| `openBet(int256 targetPrice, uint256 duration, Side playerSide)` | `external payable` | Opens a new bet. Minimum 0.1 ETH, minimum 1 day duration.                             |
| `joinBet(Side playerSide)`                                       | `external payable` | Joins an open bet with the opposite side and matching wager.                          |
| `settleBet()`                                                    | `external`         | Settles the bet once the duration has passed. Fetches live price and pays the winner. |
| `getBetState()`                                                  | `external view`    | Returns the current State enum value                                                  |
| `getPlayerOne()`                                                 | `external view`    | Returns Player 1's address                                                            |
| `getPlayerTwo()`                                                 | `external view`    | Returns Player 2's address                                                            |
| `getPlayerSide(address)`                                         | `external view`    | Returns the Side enum value for a given player address                                |
| `getWagerBet()`                                                  | `external view`    | Returns the wager amount in wei                                                       |
| `getTargetPrice()`                                               | `external view`    | Returns the target price in Chainlink 8-decimal format                                |
| `getTimeRemaining()`                                             | `external view`    | Returns seconds until settlement is possible, or 0 if already past                    |
| `getCurrentPrice()`                                              | `external view`    | Returns the current ETH/USD price from Chainlink                                      |
| `getStartTime()`                                                 | `external view`    | Returns the timestamp when the bet was opened                                         |
| `getDuration()`                                                  | `external view`    | Returns the bet duration in seconds                                                   |
| `getPriceFeed()`                                                 | `external view`    | Returns the Chainlink price feed address                                              |
| `getWinner()`                                                    | `external view`    | Returns the winner's address after settlement                                         |
| `getContractBalance()`                                           | `external view`    | Returns the current ETH balance of the contract                                       |

### Custom Errors

| Error                                   | When It Triggers                                                 |
| --------------------------------------- | ---------------------------------------------------------------- |
| `PriceBet__NotEnoughMoneySent()`        | ETH sent to openBet() is below the minimum                       |
| `PriceBet__DurationMustBeLonger()`      | Duration passed to openBet() is below the minimum                |
| `PriceBet__BetAlreadyStarted()`         | openBet() is called when a bet is already active                 |
| `PriceBet__BetNotAvailable()`           | joinBet() is called when no bet is in Opened state               |
| `PriceBet__CannotUseSameSide()`         | Player 2 tries to pick the same side as Player 1                 |
| `PriceBet__YouMustMatchTheBet()`        | Player 2 sends a different ETH amount than the wager             |
| `PriceBet__CannotBeTheSamePlayer()`     | Player 1 tries to join their own bet                             |
| `PriceBet__CannotSettleBet()`           | settleBet() is called when the bet is not Ongoing                |
| `PriceBet__NotEnoughTimeHasPassed()`    | settleBet() is called before the duration has elapsed            |
| `PriceBet__TransferFailed()`            | The ETH transfer to the winner fails                             |
| `PriceBet__DirectTransfersNotAllowed()` | ETH is sent directly to the contract via receive() or fallback() |

### Events

| Event                                                      | When It Emits                         |
| ---------------------------------------------------------- | ------------------------------------- |
| `BetOpened(address indexed player, uint256 indexed value)` | Player 1 successfully opens a bet     |
| `BetJoined(address indexed player)`                        | Player 2 successfully joins a bet     |
| `NewWinner(address indexed winner)`                        | A bet is settled and a winner is paid |

---

## HelperConfig

Handles network detection and price feed configuration automatically. No manual address changes are needed when switching networks.

| Network       | Chain ID | Behaviour                                                                          |
| ------------- | -------- | ---------------------------------------------------------------------------------- |
| Sepolia       | 11155111 | Uses the real Chainlink ETH/USD feed at 0x694AA1769357215DE4FAC081bf1f309aDC325306 |
| Anvil (local) | 31337    | Deploys a MockV3Aggregator with 8 decimals and an initial price of $2,000          |

---

## Tests

28 tests covering over 90% of the contract.

### General

| Test                                     | What It Checks                                    |
| ---------------------------------------- | ------------------------------------------------- |
| `testContractStartsWithCorrectPriceFeed` | Price feed address is set correctly at deployment |
| `testInitialStateIsIdle`                 | Contract initialises in the Idle state            |

### openBet()

| Test                                     | What It Checks                                     |
| ---------------------------------------- | -------------------------------------------------- |
| `testRevertsIfNotEnoughEthSentToOpenBet` | Reverts when ETH sent is below the minimum         |
| `testRevertsIfNotEnoughDurationSet`      | Reverts when duration is below the minimum         |
| `testRevertsIfStateIsNotIdleWhenOpened`  | Reverts when a bet is already active               |
| `testStateChangesToOpenedWhenBetOpens`   | State changes to Opened after a successful call    |
| `testPlayerSideGetsSetCorrectly`         | Player 1's side is stored correctly                |
| `testTargetPriceGetsSetCorrectly`        | Target price is stored correctly                   |
| `testMsgSenderIsPlayerOne`               | Player 1's address is stored correctly             |
| `testMsgValueIsWagerBet`                 | Wager amount is stored correctly                   |
| `testDurationGetsSetCorrectly`           | Duration is stored correctly                       |
| `testStartTimeGetsSetCorrectly`          | Start time is set to the current block timestamp   |
| `testEmitsBetOpenedWhenOpensBet`         | BetOpened event is emitted with correct parameters |

### joinBet()

| Test                                              | What It Checks                                     |
| ------------------------------------------------- | -------------------------------------------------- |
| `testRevertsIfStateIsNotOpened`                   | Reverts when no bet is in Opened state             |
| `testRevertsIfSideIsSameAsPlayerOne`              | Reverts when Player 2 picks the same side          |
| `testRevertsIfMsgValueIsNotEqualToWager`          | Reverts when Player 2 does not match the wager     |
| `testRevertsIfSamePlayerTriesJoiningTheBet`       | Reverts when Player 1 tries to join their own bet  |
| `testPlayerTwoGetsSetCorrectlyWhenJoiningBet`     | Player 2's address is stored correctly             |
| `testPlayerTwoSideGetsSetCorrectlyWhenJoiningBet` | Player 2's side is stored correctly                |
| `testStateChangesToOngoingWhenJoiningBet`         | State changes to Ongoing after a successful join   |
| `testEmitsBetJoinedWhenJoinsBet`                  | BetJoined event is emitted with correct parameters |

### settleBet()

| Test                                        | What It Checks                                             |
| ------------------------------------------- | ---------------------------------------------------------- |
| `testRevertsIfStateIsNotOngoing`            | Reverts when the bet is not in Ongoing state               |
| `testRevertsIfNotEnoughTimeHasPassed`       | Reverts when the duration has not elapsed                  |
| `testPlayerBettingHighWinsIfPriceIsGreater` | High better wins when price exceeds the target             |
| `testPlayerBettingLowWinsIfPriceIsLower`    | Low better wins when price is below the target             |
| `testStateChangesToSettledWhenBetIsSettled` | State changes to Settled after settlement                  |
| `testContractBalanceIsZeroWhenBetSettles`   | Contract balance is zero after the winner is paid          |
| `testEmitsNewWinnerWhenBetSettles`          | NewWinner event is emitted with the correct winner address |

---
