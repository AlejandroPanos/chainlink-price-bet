// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {PriceBet} from "src/PriceBet.sol";
import {DeployPriceBet} from "script/DeployPriceBet.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract TestPriceBet is Test {
    /* Instatiate a new contract */
    PriceBet priceBet;
    HelperConfig helperConfig;

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
    uint256 private constant AMOUNT = 10 ether;
    uint256 private constant SEND_AMOUNT = 0.5 ether;
    uint256 private constant DURATION = 7 days;
    int256 private constant TARGET_PRICE = 3000e8;
    uint256 private constant LOWER_SEND_AMOUNT = 0.01 ether;
    uint256 private constant LOWER_DURATION = 1 minutes;
    PriceBet.Side private constant PLAYER_SIDE = PriceBet.Side.High;
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
        vm.deal(USER, AMOUNT);
    }

    function testContractStartsWithCorrectPriceFeed() public view {
        assertEq(priceBet.getPriceFeed(), priceFeed);
    }

    function testInitialStateIsIdle() public view {
        assertEq(uint256(priceBet.getBetState()), uint256(PriceBet.State.Idle));
    }

    function testRevertsIfNotEnoughEthSentToOpenBet() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(PriceBet__NotEnoughMoneySent.selector);

        // Act / Assert
        priceBet.openBet{value: LOWER_SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_SIDE);
    }

    function testRevertsIfNotEnoughDurationSet() public {
        // Arrange
        vm.prank(USER);
        vm.expectRevert(PriceBet__DurationMustBeLonger.selector);

        // Act / Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, LOWER_DURATION, PLAYER_SIDE);
    }

    function testRevertsIfStateIsNotIdleWhenOpened() public {
        // Arrange
        vm.prank(USER);
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_SIDE);

        vm.prank(USER);
        vm.expectRevert(PriceBet__BetAlreadyStarted.selector);

        // Act / Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_SIDE);
    }

    function testEmitsBetOpenedWhenOpensBet() public {
        // Arrange
        vm.prank(USER);
        vm.expectEmit(true, true, false, false);
        emit BetOpened(USER, SEND_AMOUNT);

        // Assert
        priceBet.openBet{value: SEND_AMOUNT}(TARGET_PRICE, DURATION, PLAYER_SIDE);
    }
}
