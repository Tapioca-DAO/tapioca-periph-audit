// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

interface IStargatePool {
    function deltaCredit() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function localDecimals() external view returns (uint256);

    function token() external view returns (address);
}

/// @notice Courtesy of https://gist.github.com/0xShaito/f01f04cb26d0f89a0cead15cff3f7047
/// @dev Addresses are for Arbitrum
contract SGOracle is IOracle {
    string public _name;
    string public _symbol;

    IStargatePool public immutable SG_POOL;
    AggregatorV2V3Interface public immutable UNDERLYING;

    constructor(
        string memory __name,
        string memory __symbol,
        IStargatePool pool,
        AggregatorV2V3Interface _underlying
    ) {
        _name = __name;
        _symbol = __symbol;
        SG_POOL = pool;
        UNDERLYING = _underlying;
    }

    function decimals() external view returns (uint8) {
        return UNDERLYING.decimals();
    }

    /// @notice Calculated the price of 1 LP token
    /// @return _maxPrice the current value
    /// @dev This function comes from the implementation in vyper that is on the bottom
    function _get() internal view returns (uint256 _maxPrice) {
        uint256 lpPrice = (SG_POOL.totalLiquidity() *
            uint256(UNDERLYING.latestAnswer())) / SG_POOL.totalSupply();

        return lpPrice;
    }

    /// @notice Get the latest exchange rate.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata
    ) external virtual returns (bool success, uint256 rate) {
        return (true, _get());
    }

    /// @notice Check the last exchange rate without any state changes.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata
    ) external view virtual returns (bool success, uint256 rate) {
        return (true, _get());
    }

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(
        bytes calldata
    ) external view virtual returns (uint256 rate) {
        return _get();
    }

    /// @notice Returns a human readable (short) name about this oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata) external view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns a human readable name about this oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata) external view returns (string memory) {
        return _name;
    }
}
