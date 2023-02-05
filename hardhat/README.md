# BandBridgeConsumer contract

This project consists of three helper contracts designed to help developers create a consumer contract or a contract that connects to Band's bridge contract and makes use of the verified data returned from the bridge verification process. 
The `Bridge contract` is a Band Protocol component that allows other blockchains to access off-chain information via the decentralized oracle. It implements the lite client verification specification, allowing users to validate the accuracy of the results they receive from Oracle. The Bridge contract can be implemented as a smart contract with user-supplied logic or as a blockchain module with built-in logic. Users can ensure the accuracy of information received from the decentralized oracle and maintain the security and reliability of their own blockchain applications by using the Bridge contract.

For more detail about Bridge contract, please see 👉 [here](https://github.com/bandprotocol/vrf-and-bridge-contracts/blob/master/contracts/bridge/README.md).

## Installation

```shell
npm install band-bridge-consumer
```

## Deployment

### npmjs
```shell
nvm use 16
npm install
npm run prepublish
npm login
npm publish
```

## Helper contracts

- The `Obi` contract library in the BandChain ecosystem contains standard methods for serializing and deserializing binary data. An OBI schema explains how a data object in any supported programming language can be encoded to and decoded from plain bytes.
- The `IBridge` contract serves as an interface for communicating with the Bridge contract.
- The `BandBridgeConsumer` is a parent contract designed to assist developers in creating a consumer contract that can connect to the Band's bridge contract. It contains Band's basic parameters such as minCount, askCount, oracleScriptID, and a reference of the bridge contract, which are used to verify the configurations within the result returned from the Bridge contract. This parent contract acts as a safeguard by ensuring that the result returned from the Bridge contract has the correct configurations before being processed further in the consumer contract.

## Obi contract

For the document about Obi, please see 👉 [here](https://docs.bandchain.org/technical-specifications/obi.html)

## IBridge contract

### Enums
- **ResolveStatus**
    ```solidity=
    enum ResolveStatus {
        RESOLVE_STATUS_OPEN_UNSPECIFIED,
        RESOLVE_STATUS_SUCCESS,
        RESOLVE_STATUS_FAILURE,
        RESOLVE_STATUS_EXPIRED
    }
    ```

### Structs
- **Result**
    ```solidity=
    struct Result {
        string clientID;
        uint64 oracleScriptID;
        bytes params;
        uint64 askCount;
        uint64 minCount;
        uint64 requestID;
        uint64 ansCount;
        uint64 requestTime;
        uint64 resolveTime;
        ResolveStatus resolveStatus;
        bytes result;
    }
    ```

### Functions

- **relayAndVerify(bytes calldata data)**
    Performs oracle state relay and oracle data verification in one go. The caller submits the encoded proof and receives back the decoded data, ready to be validated and used.
- **relayAndMultiVerify(bytes calldata data)**
    Performs oracle state relay and many times of oracle data verification in one go. The caller submits the encoded proof and receives back the decoded data, ready to be validated and used.
- **verifyOracleResult(bytes calldata data)**
    Performs oracle state extraction and verification without saving root hash to storage in one go. The caller submits the encoded proof and receives back the decoded data, ready to be validated and used.
- **relayAndVerifyCount(bytes calldata data)**
    Performs oracle state relay and requests count verification in one go. The caller submits the encoded proof and receives back the decoded data, ready tobe validated and used.
    
### Example use cases

```solidity=

import "band-bridge-consumer/contracts/bridge/IBridge.sol";

contract BridgeConsumer {
    
    IBridge public bridgeReference;
    
    constructor(..., IBridge _bridge, ...) public {
        ...
        bridgeReference = _bridge;
        ...
    }
    
    ...
    
    function useBridgeContractForVerification(bytes calldata _data) public {
        Result memory result = bridgeReference.relayAndVerify(_data);
        require(
            result.resolveStatus == IBridge.ResolveStatus.RESOLVE_STATUS_SUCCESS,
            "Request not successfully resolved"
        );
        ...
    }
    
}
```

## BandBridgeConsumer

### Structs
- **OracleBasicConfiguration**
    ```solidity=
    struct OracleBasicConfiguration {
        uint8 minCount;
        uint8 askCount;
        uint64 oracleScriptID;
        IBridge bridge;
    }
    ```

### State variables
- **config**
    ```solidity=
    OracleBasicConfiguration public config;
    ```
    
### Functions

- **getConfig()**
    This function will return a state variable `config` in the form of the struct `OracleBasicConfiguration`. Despite the fact that the config is a public state variable, directly calling config() will return a tuple of `(uint8,uint8,uint64,address)` rather than a struct `OracleBasicConfiguration`. This is due to the fact that the current Solidity version's built-in public function will only be generated for primitive types and will not be able to use any custom structs.
- **_handleOracleResponse(IBridge.Result memory result)**
    An internal virtual function designed to allow the implementor to do something with the result struct securely after Band's bridge contract has verified its proof of availability and this contract has also verified the basic configuration.
- **verifyProofAndBasicConfiguration(bytes calldata data)**
    This is a view function with two primary verification steps. The data is first passed to Band's bridge contract, which verifies its proof of availability. After the bridge verification is successful, the extracted result is returned, and this function checks for basic configuration on top of that before returning the verified result.
- **verifyProofAndHandleResponse(bytes calldata data)**
    This function combines two functions, `verifyProofAndBasicConfiguration` and `_handleOracleResponse` to allow the caller to only submit the proof from Band and then execute the implementation logic within the function `_handleOracleResponse` based on the consumer contract's implementation.

### Example use cases

This example shows a price consumer contract that wants to consume Band's crypto price data from oracle-script-3. The contract is extended from BandBridgeConsumer to handle the verified result by decoding the request's params and result bytes into symbols and rates and then saving the decoded information to the state.

```solidity=

import "band-bridge-consumer/contracts/obi/Obi.sol";
import "band-bridge-consumer/contracts/bridge/IBridge.sol";
import "band-bridge-consumer/contracts/BandBridgeConsumer.sol";

contract PriceConsumer is BandBridgeConsumer {
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
```
