// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC1410 } from "./interfaces/IERC1410.sol";
import { console } from "hardhat/console.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Digitoken is IERC1410, ERC20, Ownable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _burnerCounter;

    using ECDSA for bytes32;

    // Access Roles ____________________________________________________________________________________________
    bytes32 public constant MINTER = keccak256("MINTER_ROLE");
    bytes32 public constant TRANSFER_AGENT = keccak256("TRANSFER_AGENT_ROLE");
    bytes32 public constant WHITE_LISTED = keccak256("WHITE_LISTED");
    bytes32 public BURNER;

    // Partition compatibility _________________________________________________________________________________
    mapping(bytes => Certificate) private _certificates;
    mapping(bytes32 => uint256) private _totalSupplyByPartition;
    mapping(bytes32 => mapping(address => uint256)) private _partitions;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) private _partitionAllowances;

    // ERC-20 compatibility ____________________________________________________________________________________
    address immutable _certifier;

    constructor(string memory name, string memory symbol, address certifier) ERC20(name, symbol) {
        _certifier = certifier;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITE_LISTED, msg.sender);
        setupBurner();
    }

    struct Certificate {
        string url;
        bytes32 digest;
        bytes signature;
    }

    // Modifiers _______________________________________________________________________________________________
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

    modifier onlyWhiteListed(address to) {
        address from = _msgSender();
        require(hasRoleOrAdmin(WHITE_LISTED, to), "Recipient has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, to), "Recipient is not a transfer agent");

        require(hasRoleOrAdmin(WHITE_LISTED, from), "Sender has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, from), "Sender is not a transfer agent");
        _;
    }

    // partition functions _________________________________________________________________________________

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

    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _data) external onlyMinter {
        Certificate memory cert = extractCertificate(_data);
        require(verifyCertificate(cert), "Invalid certificate");

        _partitions[_partition][_tokenHolder] += _value;
        _totalSupplyByPartition[_partition] += _value;
        _certificates[cert.signature] = cert;

        super._mint(_tokenHolder, _value);

        emit IssuedByPartition(_partition, msg.sender, _tokenHolder, _value, _data, cert.signature);
    }

    function extractCertificate(bytes memory _data) internal pure returns (Certificate memory) {
        (string memory url, bytes32 digest, bytes memory signature) = abi.decode(_data, (string, bytes32, bytes));
        return Certificate(url, digest, signature);
    }

    function verifyCertificate(Certificate memory cert) internal view returns (bool) {
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", cert.digest));
        address signer = ECDSA.recover(digest, cert.signature);
        return signer == _certifier;
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

    // ERC-20 functions _________________________________________________________________________________
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override onlyWhiteListed(to) {}
}
