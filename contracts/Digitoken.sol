// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC1410} from "./interfaces/IERC1410.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract DigitokenFinal is IERC1410, ERC20, Ownable {
    constructor() ERC20("Digitoken", "DIGI") {}

    function balanceOfByPartition(
        bytes32 _partition,
        address _tokenHolder
    ) external view returns (uint256) {}

    function partitionsOf(
        address _tokenHolder
    ) external view returns (bytes32[] memory) {}

    function transferByPartition(
        bytes32 _partition,
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes32) {}

    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _operatorData
    ) external returns (bytes32) {}

    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes memory _data
    ) external view returns (bytes memory, bytes32, bytes32) {}

    // Operator Information
    function isOperator(
        address _operator,
        address _tokenHolder
    ) external view returns (bool) {}

    function isOperatorForPartition(
        bytes32 _partition,
        address _operator,
        address _tokenHolder
    ) external view returns (bool) {}

    function authorizeOperator(address _operator) external {}

    function revokeOperator(address _operator) external {}

    function authorizeOperatorByPartition(
        bytes32 _partition,
        address _operator
    ) external {}

    function revokeOperatorByPartition(
        bytes32 _partition,
        address _operator
    ) external {}

    function issueByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes memory _data
    ) external {}

    function redeemByPartition(
        bytes32 _partition,
        uint256 _value,
        bytes memory _data
    ) external {}

    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes memory _operatorData
    ) external {}
}
