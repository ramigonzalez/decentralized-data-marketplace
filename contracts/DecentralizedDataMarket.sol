// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract DecentralizedDataMarket is ERC721URIStorage, AccessControl, Ownable {

    bytes32 public constant DATA_PROVIDER_ROLE = keccak256("DATA_PROVIDER_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  
    uint256 public platformFee = 0.05 ether; // Percentage for platform (e.g., 5%)
    uint256 public mintFee = 0.001 ether;
    uint256 private _tokenIdCounter;

    mapping(uint256 => uint256) public tokenPrices;

    event DataTokenCreated(uint256 indexed tokenId, string indexed dataHash, address creator);
    event DataListedForSale(uint256 indexed tokenId, uint256 indexed price, address creator);

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can perform this action");
        _; // Continue with the rest of the function execution
    }

    constructor() ERC721("DecentralizedDataMarket", "DATAM") Ownable(msg.sender) {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    // Access control
    function getDataURI(uint256 tokenId) public view onlyRole(DATA_PROVIDER_ROLE) onlyOwnerOf(tokenId) returns (string memory) {
        // Get the IPFS hash
        return tokenURI(tokenId);
    }

    function grantDataProviderRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(DATA_PROVIDER_ROLE, account);
    }

    function grantAdminRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, account);
    }

    function grantConsumerRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(CONSUMER_ROLE, account);
    }

    function revokeDataProviderRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(DATA_PROVIDER_ROLE, account);
    }

    function revokeAdminRole(address account) public onlyRole(ADMIN_ROLE) {
        require(account != msg.sender, "Cannot revoke own admin role"); // Prevent self-revocation
        _revokeRole(ADMIN_ROLE, account);
    }

    function revokeConsumerRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(CONSUMER_ROLE, account);
    }

    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721URIStorage) returns (bool) {
        if (interfaceId == type(IERC165).interfaceId) {
            return true; // Always support IERC165
        } else {
            return super.supportsInterface(interfaceId); // Delegate to base contracts
        }
    }
}