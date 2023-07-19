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
    Counters.Counter private _expectedNonce;

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
    mapping(address => bytes32[]) private _userPartitions;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) private _partitionAllowances;

    // ERC-20 compatibility ____________________________________________________________________________________
    address immutable _certifier;
    

    constructor(string memory name, string memory symbol, address certifier) ERC20(name, symbol) {
        _certifier = certifier;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WHITE_LISTED, msg.sender);
        _grantRole(WHITE_LISTED, address(0));
        _grantRole(TRANSFER_AGENT, address(0));
        setupBurner();

        _expectedNonce.increment();
        _burnerCounter.increment();
    }

    struct Certificate {
        string url;
        bytes32 digest;
        bytes signature;
    }

    // events _________________________________________________________________________________________________
    event Burn(bytes32 indexed partition, address indexed operator, uint256 indexed value);
    event PackedData(bytes packedData);

    // modifiers _______________________________________________________________________________________________
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Digitoken: Sender is not an admin");
        _;
    }

    modifier onlyMinter() {
        require(hasRoleOrAdmin(WHITE_LISTED, msg.sender), "Digitoken: Sender has not whitelisted");
        require(hasRoleOrAdmin(MINTER, msg.sender), "Digitoken: Sender is not a minter");
        _;
    }

    modifier onlyBurner() {
        require(hasRoleOrAdmin(WHITE_LISTED, msg.sender), "Digitoken: Sender has not whitelisted");
        require(hasRoleOrAdmin(BURNER, msg.sender), "Digitoken: Sender is not a burner");
        _;
    }

    modifier onlyWhiteListed(address to) {
        address from = _msgSender();
        require(hasRoleOrAdmin(WHITE_LISTED, to), "Digitoken: Recipient has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, to), "Digitoken: Recipient is not a transfer agent");

        require(hasRoleOrAdmin(WHITE_LISTED, from), "Digitoken: Sender has not whitelisted");
        require(hasRoleOrAdmin(TRANSFER_AGENT, from), "Digitoken: Sender is not a transfer agent");
        _;
    }

    // partition functions _________________________________________________________________________________

    function setupBurner() public onlyAdmin {
        BURNER = keccak256(abi.encodePacked("BURNER_ROLE_", Strings.toString(_burnerCounter.current())));
        _burnerCounter.increment();
    }

    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns (uint256) {
        return _partitions[_partition][_tokenHolder];
    }

    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory) {
        return _userPartitions[_tokenHolder];
    }

    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes memory _data) external returns (bytes32) {
        require(hasRole(TRANSFER_AGENT, msg.sender), "Digitoken: Caller is not a transfer agent");
        require(this.balanceOfByPartition(_partition, msg.sender) >= _value, "Digitoken: Insufficient balance");

        _partitions[_partition][msg.sender] -= _value;
        _partitions[_partition][_to] += _value;

        emit TransferByPartition(_partition, msg.sender, msg.sender, _to, _value, _data, "");

        return _partition;
    }

    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _data) external onlyMinter {
        Certificate memory cert = extractCertificate(_data);
        verifyCertificate(cert, _certifier);

        _partitions[_partition][_tokenHolder] += _value;
        _totalSupplyByPartition[_partition] += _value;
        _certificates[cert.signature] = cert;
        _userPartitions[_tokenHolder].push(_partition);

        super._mint(_tokenHolder, _value);
        _expectedNonce.increment();

        emit IssuedByPartition(_partition, msg.sender, _tokenHolder, _value, _data, cert.signature);
    }

    function extractCertificate(bytes memory _data) internal pure returns (Certificate memory) {
        (string memory url, bytes32 digest, bytes memory signature) = abi.decode(_data, (string, bytes32, bytes));
        return Certificate(url, digest, signature);
    }

    function verifyCertificate(Certificate memory cert, address verifier) internal view {
        bytes32 messageDigest = keccak256(abi.encodePacked(Strings.toString(_expectedNonce.current())));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageDigest));
        address signer = ECDSA.recover(digest, cert.signature);
        require(signer == verifier, "Digitoken: Invalid certificate signer");
    }

    function hasRoleOrAdmin(bytes32 role, address account) internal view returns (bool) {
        return (hasRole(role, account)) || hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Not used functions _________________________________________________________________________________
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes memory _data) external {}

    function operatorRedeemByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes memory _operatorData) external {}

    function operatorTransferByPartition(bytes32 _partition, address _from, address _to, uint256 _value, bytes memory _data, bytes memory _operatorData) external returns (bytes32) {}

    function canTransferByPartition(address _from, address _to, bytes32 _partition, uint256 _value, bytes memory _data) external view returns (bytes memory, bytes32, bytes32) {}

    function isOperator(address _operator, address _tokenHolder) external view returns (bool) {}

    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool) {}

    function authorizeOperator(address _operator) external {}

    function revokeOperator(address _operator) external {}

    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external {}

    function revokeOperatorByPartition(bytes32 _partition, address _operator) external {}

    // ____________________________________________________________________________________________________

    // ERC-20 functions _________________________________________________________________________________

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override onlyWhiteListed(to) {}

    function burn(address _account, uint256 _amount, bytes memory _holderData, bytes memory _issuerData) external onlyBurner {
        Certificate memory holderCert = extractCertificate(_holderData);
        verifyCertificate(holderCert, _account);

        Certificate memory issuerCert = extractCertificate(_issuerData);
        verifyCertificate(issuerCert, _certifier);

        require(_amount > 0, "Digitoken: Invalid burn amount");
        require(_amount <= totalSupply(), "Digitoken: Insufficient supply");

        uint256 remainingValue = _amount;

        bytes32[] storage partitions = _userPartitions[_account];
        for (uint256 i = 0; i < partitions.length; i++) {
            bytes32 partition = partitions[i];
            uint256 balance = _partitions[partition][_account];

            if (balance > 0) {
                uint256 burnAmount = (balance <= remainingValue) ? balance : remainingValue;
                _partitions[partition][_account] -= burnAmount;
                _totalSupplyByPartition[partition] -= burnAmount;

                remainingValue -= burnAmount;

                // remove partition if balance is 0
                if (_partitions[partition][_account] == 0) {
                    removePartition(partition, _account);
                }

                emit Burn(partition, _account, burnAmount);

                // exit when completed
                if (remainingValue == 0) {
                    break;
                }
            }
        }

        require(remainingValue == 0, "Insufficient balance to burn");
        _burn(_account, _amount);
    }

    function removePartition(bytes32 _partition, address _tokenHolder) internal {
        bytes32[] storage partitions = _userPartitions[_tokenHolder];
        for (uint256 i = 0; i < partitions.length; i++) {
            if (partitions[i] == _partition) {
                if (i != partitions.length - 1) {
                    partitions[i] = partitions[partitions.length - 1];
                }
                partitions.pop();
                break;
            }
        }
    }
}
