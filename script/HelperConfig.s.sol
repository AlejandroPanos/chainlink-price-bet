// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.t.sol";

contract HelperConfig is Script {
    /* Type declarations */
    struct NetworkConfig {
        address priceFeed;
    }

    /* State variables */
    NetworkConfig public activeNetworkConfig;
    uint256 public constant DECIMALS = 8;
    uint256 public constant INITIAL_ANSWER = 2000e8;
    uint256 public constant SEPOLIA_ID = 11155111;

    /* Constructor */
    constructor() {
        if (block.chainid == SEPOLIA_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() public returns (NetworkConfig memory) {}

    function getAnvilConfig() public returns (NetworkConfig memory) {}
}
