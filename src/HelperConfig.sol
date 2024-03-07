// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {MockV3Aggregator} from "test/mocks/mockV3aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetwork;

    struct NetworkConfig {
        address priceFeed; //For ETH/USD price on testnet/mainnet
    }

    // address mockPriceFeed;
    uint8 constant ETH_PRICE_DECIMALS = 8;
    int256 constant ETH_INITIAL_PRICE = 2000e8;

    constructor() {
        // 11155111 is Sepoila's Chain ID as found on https://chainlist.org/?testnets=true&search=ETH
        if (block.chainid == 11155111) activeNetwork = getSepoilaConfig();
        else activeNetwork = getOrCreateAnvilConfig();
    }

    function getSepoilaConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ETHUSDpriceFeed = NetworkConfig({priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return ETHUSDpriceFeed;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetwork.priceFeed != address(0)) {
            return activeNetwork;
        } // This here is just to check if anactiveNetwork.priceFeed had been created. Yes? Return that address. No? Create one.

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(ETH_PRICE_DECIMALS, ETH_INITIAL_PRICE);
        vm.stopBroadcast();
        NetworkConfig memory anvilConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilConfig;
    }
}
