// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "lib/forge-std/src/Script.sol";
import {Decentralized_Market} from "../src/Rise_In_Decentralized_Market.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract DeployDecentralized_Market is Script {
    function run() external returns (Decentralized_Market) {
        // HelperConfig helperConfig= new HelperConfig();
        // address ETHUSD_PriceFeed = helperConfig.activeNetwork();

        vm.startBroadcast();
        Decentralized_Market decentralized_market = new Decentralized_Market(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        vm.stopBroadcast();
        return decentralized_market;
    }
}
//forge script src/Rise_In_Decentralized_Market.sol:Decentralized_Market
