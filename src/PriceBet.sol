// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/**
 * @dev A contract where two players can bet ETH against each other on whether
 * the price of ETH will be above or below a target USD price at a specific point in time.
 * The first player sets the target price and picks a side.
 * The second player takes the opposite side.
 * When the time is up, anyone can trigger the settlement and the winner takes the pot.
 * @dev Chainlink gets implemented to access real world data.
 */
contract PriceBet {
    /* Errors */
    error PriceBet__NotEnoughMoneySent();
    error PriceBet__DurationMustBeLonger();
    error PriceBet__BetAlreadyStarted();

    /* Type declarations */
    enum Side {
        High,
        Low
    }

    enum State {
        Idle,
        Opened,
        Ongoing,
        Settled
    }

    /* State variables */
    address public immutable i_owner;
    uint256 public constant MIN_AMOUNT = 0.1 ether;
    uint256 public constant MIN_DURATION = 1 days;
    AggregatorV3Interface private s_priceFeed;
    State private s_state;
    Side public s_trackSide;
    uint256 public s_targetPrice;
    address public playerOne;
    uint256 public s_wagerBet;
    uint256 public s_betDuration;
    uint256 public s_startTime;

    /* Events */
    event BetOpened(address indexed player);

    /* Constructor */
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Functions */
    function openBet(uint256 targetPrice, uint256 duration, Side playerSide) external payable {
        // Check
        if (msg.value < MIN_AMOUNT) {
            revert PriceBet__NotEnoughMoneySent();
        }

        if (duration < MIN_DURATION) {
            revert PriceBet__DurationMustBeLonger();
        }

        if (s_state != State.Idle) {
            revert PriceBet__BetAlreadyStarted();
        }

        // Effects
        s_trackSide = playerSide;
        s_targetPrice = targetPrice;
        s_wagerBet = msg.value;
        s_betDuration = duration;
        s_startTime = block.timestamp;
        s_state = State.Opened;

        // Interactions
        emit BetOpened(msg.sender);
    }

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
