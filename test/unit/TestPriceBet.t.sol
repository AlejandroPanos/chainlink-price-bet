// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {PriceBet} from "src/PriceBet.sol";
import {DeployPriceBet} from "script/DeployPriceBet.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract TestPriceBet is Test {
    /* Instatiate a new contract */
    PriceBet priceBet;
    HelperConfig helperConfig;
    MockV3Aggregator mockPriceFeed;

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

    /* State variables */
    address USER = makeAddr("user");
    address JOINER = makeAddr("joiner");
    uint256 private constant AMOUNT = 10 ether;
    uint256 private constant SEND_AMOUNT = 0.5 ether;
    uint256 private constant DURATION = 7 days;
    int256 private constant TARGET_PRICE = 3000e8;
    uint256 private constant LOWER_SEND_AMOUNT = 0.01 ether;
    uint256 private constant LOWER_DURATION = 1 minutes;
    PriceBet.Side private constant PLAYER_ONE_SIDE = PriceBet.Side.High;
    PriceBet.Side private constant PLAYER_TWO_SIDE = PriceBet.Side.Low;
    int256 private constant HIGHER_PRICE = 4000e8;
    int256 private constant LOWER_PRICE = 2000e8;
    address private priceFeed;

    /* Events */
    event BetOpened(address indexed player, uint256 indexed value);
    event BetJoined(address indexed player);
    event NewWinner(address indexed winner);

    /* Functions */
    function setUp() public {
        DeployPriceBet deployPriceBet = new DeployPriceBet();
        (priceBet, helperConfig) = deployPriceBet.run();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        priceFeed = config.priceFeed;
        mockPriceFeed = MockV3Aggregator(priceFeed);
        vm.deal(USER, AMOUNT);
        vm.deal(JOINER, AMOUNT);
    }

    /* General Testing Functions */

    function testContractStartsWithCorrectPriceFeed() public view {
        assertEq(priceBet.getPriceFeed(), priceFeed);
    }

    function testInitialStateIsIdle() public view {
        assertEq(uint256(priceBet.getBetState()), uint256(PriceBet.State.Idle));
    }

    /* Open Bet Testing Functions */

    function testRevertsIfNotEnoughEthSentToOpenBet() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(PriceBet__NotEnoughMoneySent.selector);

        // Act / Assert
        priceBet.openBet{value: LOWER_SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
    }

    function testRevertsIfNotEnoughDurationSet() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(PriceBet__DurationMustBeLonger.selector);

        // Act / Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, LOWER_DURATION, PLAYER_ONE_SIDE);
    }

    function testRevertsIfStateIsNotIdleWhenOpened() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(USER);
        vm.expectRevert(PriceBet__BetAlreadyStarted.selector);

        // Act / Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
    }

    function testStateChangesToOpenedWhenBetOpens() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(uint256(priceBet.getBetState()), uint256(PriceBet.State.Opened));
    }

    function testPlayerSideGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(uint256(priceBet.getPlayerSide(USER)), uint256(PLAYER_ONE_SIDE));
    }

    function testTargetPriceGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(priceBet.getTargetPrice(), TARGET_PRICE);
    }

    function testMsgSenderIsPlayerOne() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(priceBet.getPlayerOne(), USER);
    }

    function testMsgValueIsWagerBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(priceBet.getWagerBet(), SEND_AMOUNT);
    }

    function testDurationGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(priceBet.getDuration(), DURATION);
    }

    function testStartTimeGetsSetCorrectly() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Assert
        assertEq(priceBet.getStartTime(), block.timestamp);
    }

    function testEmitsBetOpenedWhenOpensBet() public {
        // Arrange
        vm.prank(USER);
        vm.expectEmit(true, true, false, false);
        emit BetOpened(USER, SEND_AMOUNT);

        // Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
    }

    /* Join Bet Testing Functions */

    function testRevertsIfStateIsNotOpened() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(PriceBet__BetNotAvailable.selector);

        // Act / Assert
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_ONE_SIDE);
    }

    function testRevertsIfSideIsSameAsPlayerOne() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
        vm.prank(JOINER);
        vm.expectRevert(PriceBet__CannotUseSameSide.selector);

        // Act / Assert
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_ONE_SIDE);
    }

    function testRevertsIfMsgValueIsNotEqualToWager() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
        vm.prank(JOINER);
        vm.expectRevert(PriceBet__YouMustMatchTheBet.selector);

        // Act / Assert
        priceBet.joinBet{value: (SEND_AMOUNT - 0.1 ether)}(PLAYER_TWO_SIDE);
    }

    function testRevertsIfSamePlayerTriesJoiningTheBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
        vm.prank(USER);
        vm.expectRevert(PriceBet__CannotBeTheSamePlayer.selector);

        // Act / Assert
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);
    }

    function testPlayerTwoGetsSetCorrectlyWhenJoiningBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Act
        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        // Assert
        assertEq(priceBet.getPlayerTwo(), JOINER);
    }

    function testPlayerTwoSideGetsSetCorrectlyWhenJoiningBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Act
        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        // Assert
        assertEq(uint256(priceBet.getPlayerSide(JOINER)), uint256(PLAYER_TWO_SIDE));
    }

    function testStateChangesToOngoingWhenJoiningBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Act
        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        // Assert
        assertEq(uint256(priceBet.getBetState()), uint256(PriceBet.State.Ongoing));
    }

    function testEmitsBetJoinedWhenJoinsBet() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        // Act
        vm.prank(JOINER);
        vm.expectEmit(true, false, false, false);
        emit BetJoined(JOINER);

        // Assert
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);
    }

    /* Settle Bet Testing Functions */
    function testRevertsIfStateIsNotOngoing() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);
        vm.expectRevert(PriceBet__CannotSettleBet.selector);

        // Act / Assert
        priceBet.settleBet();
    }

    function testRevertsIfNotEnoughTimeHasPassed() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        vm.warp(block.timestamp + (DURATION - 1 days));
        vm.expectRevert(PriceBet__NotEnoughTimeHasPassed.selector);

        // Act / Assert
        priceBet.settleBet();
    }

    function testPlayerBettingHighWinsIfPriceIsGreater() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        vm.warp(block.timestamp + (DURATION + 1 days));

        // Act
        mockPriceFeed.updateAnswer(HIGHER_PRICE);
        priceBet.settleBet();

        // Assert
        assertEq(priceBet.getWinner(), USER);
    }

    function testPlayerBettingLowWinsIfPriceIsLower() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        vm.warp(block.timestamp + (DURATION + 1 days));

        // Act
        mockPriceFeed.updateAnswer(LOWER_PRICE);
        priceBet.settleBet();

        // Assert
        assertEq(priceBet.getWinner(), JOINER);
    }

    function testStateChangesToSettledWhenBetIsSettled() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        vm.warp(block.timestamp + (DURATION + 1 days));

        // Act
        priceBet.settleBet();

        // Assert
        assertEq(uint256(priceBet.getBetState()), uint256(PriceBet.State.Settled));
    }

    function testContractBalanceIsZeroWhenBetSettles() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_ONE_SIDE);

        vm.prank(JOINER);
        priceBet.joinBet{value: SEND_AMOUNT}(PLAYER_TWO_SIDE);

        vm.warp(block.timestamp + (DURATION + 1 days));

        // Act
        priceBet.settleBet();

        // Assert
        assertEq(priceBet.getContractBalance(), 0);
    }
}
