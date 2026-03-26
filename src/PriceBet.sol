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
    error PriceBet__BetNotAvailable();
    error PriceBet__CannotUseSameSide();
    error PriceBet__YouMustMatchTheBet();

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
    AggregatorV3Interface private s_priceFeed;
    State private s_state;
    Side private s_trackSide;

    uint256 private constant MIN_AMOUNT = 0.1 ether;
    uint256 private constant MIN_DURATION = 1 days;
    uint256 private s_targetPrice;
    address private s_playerOne;
    address private s_playerTwo;
    uint256 private s_wagerBet;
    uint256 private s_betDuration;
    uint256 private s_startTime;

    /* Events */
    event BetOpened(address indexed player, uint256 indexed value, uint256 indexed bet);
    event BetJoined(address indexed player);

    /* Constructor */
    constructor(address priceFeed) {
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
        s_state = State.Opened;
        s_trackSide = playerSide;

        s_targetPrice = targetPrice;
        s_playerOne = msg.sender;
        s_wagerBet = msg.value;
        s_betDuration = duration;
        s_startTime = block.timestamp;

        // Interactions
        emit BetOpened(msg.sender, msg.value, s_wagerBet);
    }

    function joinBet(Side playerSide) external payable {
        // Checks
        if (s_state == State.Idle || s_state == State.Settled) {
            revert PriceBet__BetNotAvailable();
        }

        if (playerSide == s_trackSide) {
            revert PriceBet__CannotUseSameSide();
        }

        if (msg.value != s_wagerBet) {
            revert PriceBet__YouMustMatchTheBet();
        }

        // Effects
        s_playerTwo = msg.sender;

        // Interactions
        emit BetJoined(msg.sender);
    }

    /* Getter functions */
}
