// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {PriceBet} from "src/PriceBet.sol";
import {DeployPriceBet} from "script/DeployPriceBet.s.sol";

contract TestPriceBet is Test {
    /* Instatiate a new contract */
    PriceBet priceBet;

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

    /* Events */
    event BetOpened(address indexed player, uint256 indexed value, uint256 indexed bet);
    event BetJoined(address indexed player);
    event NewWinner(address indexed winner);

    /* Functions */
    function setUp() public {
        DeployPriceBet deployPriceBet = new DeployPriceBet();
        priceBet = deployPriceBet.run();
        vm.deal(USER, AMOUNT);
    }
}
