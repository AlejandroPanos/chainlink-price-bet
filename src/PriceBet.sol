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
    error PriceBet__CannotBeTheSamePlayer();
    error PriceBet__CannotSettleBet();
    error PriceBet__NotEnoughTimeHasPassed();
    error PriceBet__TransferFailed();

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

    Side private s_playerOneSide;
    Side private s_playerTwoSide;
    uint256 private constant MIN_AMOUNT = 0.1 ether;
    uint256 private constant MIN_DURATION = 1 days;
    int256 private s_targetPrice;
    address private s_playerOne;
    address private s_playerTwo;
    uint256 private s_wagerBet;
    uint256 private s_betDuration;
    uint256 private s_startTime;
    address private s_winner;

    /* Events */
    event BetOpened(address indexed player, uint256 indexed value);
    event BetJoined(address indexed player);
    event NewWinner(address indexed winner);

    /* Constructor */
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Functions */
    function openBet(int256 targetPrice, uint256 duration, Side playerSide) external payable {
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
        s_playerOneSide = playerSide;

        s_targetPrice = targetPrice;
        s_playerOne = msg.sender;
        s_wagerBet = msg.value;
        s_betDuration = duration;
        s_startTime = block.timestamp;

        // Interactions
        emit BetOpened(msg.sender, msg.value);
    }

    function joinBet(Side playerSide) external payable {
        // Checks
        if (s_state != State.Opened) {
            revert PriceBet__BetNotAvailable();
        }

        if (playerSide == s_playerOneSide) {
            revert PriceBet__CannotUseSameSide();
        }

        if (msg.value != s_wagerBet) {
            revert PriceBet__YouMustMatchTheBet();
        }

        if (msg.sender == s_playerOne) {
            revert PriceBet__CannotBeTheSamePlayer();
        }

        // Effects
        s_playerTwo = msg.sender;
        s_playerTwoSide = playerSide;
        s_state = State.Ongoing;

        // Interactions
        emit BetJoined(msg.sender);
    }

    function settleBet() external {
        // Checks
        if (s_state != State.Ongoing) {
            revert PriceBet__CannotSettleBet();
        }

        if (block.timestamp < (s_startTime + s_betDuration)) {
            revert PriceBet__NotEnoughTimeHasPassed();
        }

        // Effects
        (, int256 currentPrice,,,) = s_priceFeed.latestRoundData();
        bool isHigher = currentPrice > s_targetPrice;

        if (s_playerOneSide == Side.High && isHigher || s_playerOneSide == Side.Low && !isHigher) {
            s_winner = s_playerOne;
        } else {
            s_winner = s_playerTwo;
        }

        s_state = State.Settled;

        (bool success,) = payable(s_winner).call{value: address(this).balance}("");
        if (!success) {
            revert PriceBet__TransferFailed();
        }

        // Interactions
        emit NewWinner(s_winner);
    }

    /* Getter functions */
    function getBetState() external view returns (State) {
        return s_state;
    }

    function getPlayerOne() external view returns (address) {
        return s_playerOne;
    }

    function getPlayerTwo() external view returns (address) {
        return s_playerTwo;
    }

    function getPlayerSide(address playerAddress) external view returns (Side) {
        if (playerAddress == s_playerOne) {
            return s_playerOneSide;
        } else {
            return s_playerTwoSide;
        }
    }

    function getWagerBet() external view returns (uint256) {
        return s_wagerBet;
    }

    function getTargetPrice() external view returns (int256) {
        return s_targetPrice;
    }

    function getTimeRemaining() external view returns (uint256) {
        uint256 settlementTime = s_startTime + s_betDuration;
        if (block.timestamp >= settlementTime) {
            return 0;
        }
        return settlementTime - block.timestamp;
    }

    function getCurrentPrice() external view returns (int256) {
        (, int256 currentPrice,,,) = s_priceFeed.latestRoundData();
        return currentPrice;
    }

    function getStartTime() external view returns (uint256) {
        return s_startTime;
    }

    function getDuration() external view returns (uint256) {
        return s_betDuration;
    }

    function getPriceFeed() external view returns (address) {
        return address(s_priceFeed);
    }

    function getWinner() external view returns (address) {
        return s_winner;
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
