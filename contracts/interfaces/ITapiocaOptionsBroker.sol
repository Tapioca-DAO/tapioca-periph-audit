// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ICommonOFT} from "tapioca-sdk/dist/contracts/token/oft/v2/ICommonOFT.sol";

interface ITapiocaOptionsBrokerCrossChain {
    struct IApproval {
        bool permitAll;
        bool allowFailure;
        address target;
        bool permitBorrow;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct IExerciseOptionsData {
        address from;
        address target;
        uint256 paymentTokenAmount;
        uint256 oTAPTokenID;
        address paymentToken;
        uint256 tapAmount;
    }
    struct IExerciseLZData {
        uint16 lzDstChainId;
        address zroPaymentAddress;
        uint256 extraGas;
    }
    struct IExerciseLZSendTapData {
        bool withdrawOnAnotherChain;
        address tapOftAddress;
        uint16 lzDstChainId;
        uint256 amount;
        address zroPaymentAddress;
        uint256 extraGas;
    }

    function exerciseOption(
        IExerciseOptionsData calldata optionsData,
        IExerciseLZData calldata lzData,
        IExerciseLZSendTapData calldata tapSendData,
        IApproval[] calldata approvals
    ) external payable;
}

interface ITapiocaOptionsBroker {
    struct IOptionsParticipateData {
        bool participate;
        address target;
    }

    function oTAP() external view returns (address);

    function exerciseOption(
        uint256 oTAPTokenID,
        address paymentToken,
        uint256 tapAmount
    ) external;

    function participate(
        uint256 tOLPTokenID
    ) external returns (uint256 oTAPTokenID);
}