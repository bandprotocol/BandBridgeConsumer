// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.15;

import {BandBridgeConsumer} from "../BandBridgeConsumer.sol";
import {IBridge} from "../bridge/IBridge.sol";
import {Obi} from "../obi/Obi.sol";

contract MockConsumer is BandBridgeConsumer {
    using Obi for Obi.Data;

    mapping(string => uint64) public savedPrices;
    uint256 public requestIDFromTheLastSaved;

    constructor(
        uint8 _minCount,
        uint8 _askCount,
        uint8 _oracleScriptID,
        address _bridge
    ) BandBridgeConsumer(_minCount, _askCount, _oracleScriptID, _bridge) {}

    function decodeParams(bytes memory _data) internal pure returns (string[] memory symbols, uint64 multiplier) {
        Obi.Data memory decoder = Obi.from(_data);
        uint32 length = decoder.decodeU32();
        symbols = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            symbols[i] = string(decoder.decodeBytes());
        }
        multiplier = decoder.decodeU64();
        require(decoder.finished(), "Fail to decode params: DATA_DECODE_NOT_FINISHED");
    }

    function decodeResult(bytes memory _data) internal pure returns (uint64[] memory rates) {
        Obi.Data memory decoder = Obi.from(_data);
        uint32 length = decoder.decodeU32();
        rates = new uint64[](length);
        for (uint256 i = 0; i < length; i++) {
            rates[i] = decoder.decodeU64();
        }
        require(decoder.finished(), "Fail to decode result: DATA_DECODE_NOT_FINISHED");
    }

    function _handleOracleResponse(IBridge.Result memory result) override internal {
        require(result.requestID > requestIDFromTheLastSaved, "Fail to handle response: request ID is not new");

        (string[] memory symbols, uint64 multiplier) = decodeParams(result.params);
        (uint64[] memory rates) = decodeResult(result.result);

        require(symbols.length == rates.length, "Fail to handle response: symbols, rates length mismatch");

        for (uint256 i = 0; i < symbols.length; i++) {
            // Save the price for each symbol
            savedPrices[symbols[i]] = uint64((uint256(rates[i]) * 1e9) / uint256(multiplier));
        }

        requestIDFromTheLastSaved = result.requestID;
    }
}
