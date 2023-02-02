// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import {BandBridgeConsumer} from "./BandBridgeConsumer.sol";
import {IBridge} from "./bridge/IBridge.sol";
import {Obi} from "./obi/Obi.sol";

contract MockConsumer is BandBridgeConsumer {

    IBridge.Result public latestSavedResult;

    constructor(
        uint8 _minCount,
        uint8 _askCount,
        uint8 _oracleScriptID,
        address _bridge
    ) BandBridgeConsumer(_minCount, _askCount, _oracleScriptID, _bridge) {}

    function _handleOracleResponse(IBridge.Result memory result) override internal {
        latestSavedResult = result;
    }

    function handleOracleResponse(IBridge.Result memory result) public {
        _handleOracleResponse(result);
    }

}
