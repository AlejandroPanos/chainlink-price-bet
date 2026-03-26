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
    error PriceBet__YouAreNotTheOwner();

    /* Type declarations */
    enum Side {
        High,
        Low
    }

    enum State {
        Opened,
        Ongoing,
        Settled
    }

    /* State variables */
    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    /* Events */
    event BetOpened(address indexed player);

    /* Constructor */
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    /* Functions */
    function openBet() external {}

    /* Getter functions */
    function getOwner() external view returns (address) {
        return i_owner;
    }
}
