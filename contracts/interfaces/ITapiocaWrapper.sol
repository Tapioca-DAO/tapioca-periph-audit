// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaWrapper {
    function mngmtFee() external view returns (uint256);

    function mngmtFeeFraction() external view returns (uint256);
}
