// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Decentralized_Market} from "../src/Rise_In_Decentralized_Market.sol";

contract DeployDecentralized_Market is Script {
    function run() external returns(Decentralized_Market){
        vm.startBroadcast();
        Decentralized_Market decentralized_market = new Decentralized_Market();
        vm.stopBroadcast();
        return decentralized_market;
    }

    
}
//forge script src/Rise_In_Decentralized_Market.sol:Decentralized_Market