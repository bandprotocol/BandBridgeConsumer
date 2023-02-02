// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import {BandBridgeConsumer} from "../src/BandBridgeConsumer.sol";
import {MockConsumer} from "../src/MockConsumer.sol";
import {MockProxy} from "../src/bridge/MockProxy.sol";
import {Bridge} from "../src/bridge/Bridge.sol";

contract BandBridgeConsumerTest is Test {
    address EOA_1 = vm.addr(uint256(1));
    address EOA_2 = vm.addr(uint256(2));

    MockConsumer public consumer;
    Bridge public bridge;
    Bridge public bridgeProxy;
    MockProxy public proxy;

    function setUp() public {
        vm.prank(EOA_1);

        bridge = new Bridge();
        proxy = new MockProxy(address(bridge), EOA_2, "");
        bridgeProxy = Bridge(address(proxy));

        Bridge.ValidatorWithPower[] memory vps = new Bridge.ValidatorWithPower[](0);
        bridgeProxy.initialize(vps, abi.encodePacked("test"));

        consumer = new MockConsumer(1, 1, 1, address(bridgeProxy));
    }

    function testGetters() public {
        assertEq(bridgeProxy.encodedChainID(), abi.encodePacked("test"));

        assertEq(proxy.getAdmin(), EOA_2);
        assertEq(proxy.getImplementation(), address(bridge));

        BandBridgeConsumer.OracleBasicConfiguration memory config = consumer.getConfig();
        assertEq(config.oracleScriptID, 1);
        assertEq(config.minCount, 1);
        assertEq(config.askCount, 1);

    }

}
