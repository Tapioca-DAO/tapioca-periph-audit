// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ICurvePool.sol";
import "./BaseSwapper.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Curve pool swapper
contract CurveSwapper is BaseSwapper {
    using SafeERC20 for IERC20;

    /// *** VARS ***
    /// ***  ***
    ICurvePool public curvePool;
    IYieldBox public immutable yieldBox;

    /// *** ERRORS ***
    /// ***  ***
    error Undefined();
    error NotImplemented();

    constructor(
        ICurvePool _curvePool,
        IYieldBox _yieldBox
    ) validAddress(address(_curvePool)) validAddress(address(_yieldBox)) {
        curvePool = _curvePool;
        yieldBox = _yieldBox;
    }

    /// *** VIEW METHODS ***
    /// ***  ***
    /// @notice returns default bytes swap data
    function getDefaultDexOptions()
        public
        pure
        override
        returns (bytes memory)
    {
        revert Undefined();
    }

    /// @notice Computes amount out for amount in
    /// @param swapData operation data
    /// @param dexOptions AMM data
    function getOutputAmount(
        SwapData calldata swapData,
        bytes calldata dexOptions
    ) external view override returns (uint256 amountOut) {
        uint256[] memory tokenIndexes = abi.decode(dexOptions, (uint256[]));

        (uint256 amountIn, ) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );
        amountOut = curvePool.get_dy(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn
        );
    }

    /// @notice Comutes amount in for amount out
    function getInputAmount(
        SwapData calldata,
        bytes calldata
    ) external pure returns (uint256) {
        revert NotImplemented();
    }

    /// *** PUBLIC METHODS ***
    /// ***  ***

    /// @notice swaps amount in
    /// @param swapData operation data
    /// @param amountOutMin min amount out to receive
    /// @param to receiver address
    /// @param data AMM data
    function swap(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address to,
        bytes memory data
    ) external override returns (uint256 amountOut, uint256 shareOut) {
        // Get Curve tokens' indexes & addresses
        uint256[] memory tokenIndexes = abi.decode(data, (uint256[]));
        address tokenIn = curvePool.coins(tokenIndexes[0]);
        address tokenOut = curvePool.coins(tokenIndexes[1]);

        // Get tokens' amounts
        (uint256 amountIn, ) = _getAmounts(
            swapData.amountData,
            swapData.tokensData.tokenInId,
            swapData.tokensData.tokenOutId,
            yieldBox
        );

        // Retrieve tokens from sender or from YieldBox
        amountIn = _extractTokens(
            swapData.yieldBoxData,
            yieldBox,
            tokenIn,
            swapData.tokensData.tokenInId,
            amountIn,
            swapData.amountData.shareIn
        );

        // Swap & compute output
        amountOut = _swapTokensForTokens(
            int128(int256(tokenIndexes[0])),
            int128(int256(tokenIndexes[1])),
            amountIn,
            amountOutMin
        );
        if (swapData.yieldBoxData.depositToYb) {
            _safeApprove(tokenOut, address(yieldBox), amountOut);
            (, shareOut) = yieldBox.depositAsset(
                swapData.tokensData.tokenOutId,
                address(this),
                to,
                amountOut,
                0
            );
        } else {
            IERC20(tokenOut).safeTransfer(to, amountOut);
        }
    }

    /// *** PRIVATE METHODS ***
    /// ***  ***
    function _swapTokensForTokens(
        int128 i,
        int128 j,
        uint256 amountIn,
        uint256 amountOutMin
    ) private returns (uint256) {
        address tokenIn = curvePool.coins(uint256(uint128(i)));
        address tokenOut = curvePool.coins(uint256(uint128(j)));

        uint256 outputAmount = curvePool.get_dy(i, j, amountIn);
        require(outputAmount >= amountOutMin, "insufficient-amount-out");

        uint256 balanceBefore = IERC20(tokenOut).balanceOf(address(this));

        _safeApprove(tokenIn, address(curvePool), amountIn);
        curvePool.exchange(i, j, amountIn, amountOutMin);

        uint256 balanceAfter = IERC20(tokenOut).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "swap failed");

        return balanceAfter - balanceBefore;
    }
}
