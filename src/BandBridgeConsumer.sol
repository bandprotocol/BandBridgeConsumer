// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import {IBridge} from "./bridge/IBridge.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract BandBridgeConsumer is ReentrancyGuard {
    struct OracleBasicConfiguration {
        uint8 minCount;
        uint8 askCount;
        uint64 oracleScriptID;
        IBridge bridge;
    }

    OracleBasicConfiguration public config;

    constructor(uint8 _minCount, uint8 _askCount, uint8 _oracleScriptID, address _bridge) {
        OracleBasicConfiguration memory _config;

        _config.minCount = _minCount;
        _config.askCount = _askCount;
        _config.oracleScriptID = _oracleScriptID;
        _config.bridge = IBridge(_bridge);

        config = _config;
    }

    function getConfig() public view returns(OracleBasicConfiguration memory) {
        return config;
    }

    function _handleOracleResponse(IBridge.Result memory result) virtual internal {
        revert("BandBridgeConsumer: Not implemented yet");
    }

    function verifyProofAndBasicConfiguration(bytes calldata data) public view returns(IBridge.Result memory result) {
        OracleBasicConfiguration memory _config = config;

        result = _config.bridge.verifyOracleResult(data);

        require(
            result.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS,
            "BandBridgeConsumer: Request not successfully resolved"
        );
        require(
            result.oracleScriptID == _config.oracleScriptID,
            "BandBridgeConsumer: Oracle Script ID not match"
        );
        require(result.minCount == uint8(_config.minCount), "BandBridgeConsumer: Min Count not match");
        require(result.askCount == uint8(_config.askCount), "BandBridgeConsumer: Ask Count not match");
    }

    function verifyProofAndHandleResponse(bytes calldata data) public nonReentrant {
        _handleOracleResponse(verifyProofAndBasicConfiguration(data));
    }
}
