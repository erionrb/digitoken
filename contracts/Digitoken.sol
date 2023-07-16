// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { IERC1410 } from "./interfaces/IERC1410.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "hardhat/console.sol";

contract Digitoken is IERC1410, ERC20, Ownable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _burnerCounter;

    /**
     * Access Roles
     */
    bytes32 public constant MINTER = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_AGENT = keccak256("TRANSFER_AGENT_ROLE");
    bytes32 public constant WHITE_LISTED = keccak256("WHITE_LISTED");
    bytes32 public BURNER;

    constructor() ERC20("Digitoken", "DIGI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITE_LISTED, msg.sender);
        setupBurner();
    }

    /**
     *  Modifiers
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Sender is not an admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRoleOrAdmin(WHITE_LISTED, msg.sender), "Sender has not whitelisted");
        require(hasRoleOrAdmin(MINTER, msg.sender), "Sender is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(hasRoleOrAdmin(WHITE_LISTED, msg.sender), "Sender has not whitelisted");
        require(hasRoleOrAdmin(BURNER, msg.sender), "Sender is not a burner");
        _;
    }

    modifier onlyTransferAgent(address to) {
        address from = msg.sender;
        require(hasRoleOrAdmin(WHITE_LISTED, to), "Recipient has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, to), "Recipient is not a transfer agent");

        require(hasRoleOrAdmin(WHITE_LISTED, from), "Sender has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, from), "Sender is not a transfer agent");
        _;
    }

    /**
     * Functions
     */

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function transfer(address to, uint256 amount) public override onlyTransferAgent(to) returns (bool) {
        super.transfer(to, amount);
        return true;
    }

    function setupBurner() public onlyAdmin {
        BURNER = keccak256(abi.encodePacked("BURNER_ROLE_", Strings.toString(_burnerCounter.current())));
        _burnerCounter.increment();
    }

    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256) {
        // TODO: implement me
    }

    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory) {
        // TODO: implement me
    }

    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes memory _data) external returns (bytes32) {
        // TODO: implement me
    }

    function operatorTransferByPartition(bytes32 _partition, address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) external returns (bytes32) {
        // TODO: implement me
    }

    function canTransferByPartition(address _from, address _to, bytes32 _partition, uint256 _value, bytes memory _data) external view returns (bytes memory, bytes32, bytes32) {
        // TODO: implement me
    }

    function isOperator(address _operator, address _tokenHolder) external view returns (bool) {
        // TODO: implement me
    }

    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool) {}

    function authorizeOperator(address _operator) external {
        // TODO: implement me
    }

    function revokeOperator(address _operator) external {
        // TODO: implement me
    }

    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external {
        // TODO: implement me
    }

    function revokeOperatorByPartition(bytes32 _partition, address _operator) external {
        // TODO: implement me
    }

    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _data) external {
        // TODO: implement me
    }

    function redeemByPartition(bytes32 _partition, uint256 _value, bytes memory _data) external {
        // TODO: implement me
    }

    function operatorRedeemByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _operatorData) external {
        // TODO: implement me
    }

    function hasRoleOrAdmin(bytes32 role, address account) internal view returns (bool) {
        return (hasRole(role, account)) || hasRole(DEFAULT_ADMIN_ROLE, account);
    }
}
