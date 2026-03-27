// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {PriceBet} from "src/PriceBet.sol";

contract DeployPriceBet is Script {
    function run() external returns (PriceBet) {
        // Get the active network config from the helper config
        HelperConfig helperConfig = new HelperConfig();
        address activePriceFeed = helperConfig.activeNetworkConfig();

        // Deploy the PriceBet.sol contract
        vm.startBroadcast();
        PriceBet priceBet = new PriceBet(activePriceFeed);
        vm.stopBroadcast();

        // Return the contract
        return priceBet;
    }
}
