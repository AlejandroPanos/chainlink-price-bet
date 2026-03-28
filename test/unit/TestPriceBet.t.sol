// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {PriceBet} from "src/PriceBet.sol";
import {DeployPriceBet} from "script/DeployPriceBet.s.sol";

contract TestPriceBet is Test {
    /* Instatiate a new contract */
    PriceBet priceBet;

    /* State variables */
    address USER = makeAddr("user");
    uint256 private constant AMOUNT = 10 ether;

    /* Functions */
    function setUp() public {
        DeployPriceBet deployPriceBet = new DeployPriceBet();
        priceBet = deployPriceBet.run();
        vm.deal(USER, AMOUNT);
    }
}
