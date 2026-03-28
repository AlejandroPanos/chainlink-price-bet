// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    /* Type declarations */
    struct NetworkConfig {
        address priceFeed;
    }

    /* State variables */
    NetworkConfig public activeNetworkConfig;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_ANSWER = 2000e8;
    uint256 public constant SEPOLIA_ID = 11155111;
    address public constant SEPOLIA_CONTRACT_ADDRESS = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    /* Constructor */
    constructor() {
        if (block.chainid == SEPOLIA_ID) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    /* Functions */
    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        // Create the Sepolia testnet config
        NetworkConfig memory sepoliaConfig = NetworkConfig({priceFeed: SEPOLIA_CONTRACT_ADDRESS});

        // Return the config
        return sepoliaConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        // Check if there is a price feed already
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy the MockV3Aggregator fake Chainlink price feed
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER);
        vm.stopBroadcast();

        // Create the Anvil config
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});

        // Return the Anvil config
        return anvilConfig;
    }

    /* Getter functions */
    function getConfig() external view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
