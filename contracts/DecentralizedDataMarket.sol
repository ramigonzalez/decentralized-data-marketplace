// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

/// @notice This contact intends to provide a Data Decentralization Marketplace implementation
/// @dev Comment follow the Ethereum ´Natural Specification´ language format (´natspec´)
contract DecentralizedDataMarket is ERC721URIStorage, AccessControl, Ownable {

    /// @dev Access control constants
    bytes32 public constant DATA_PROVIDER_ROLE = keccak256("DATA_PROVIDER_ROLE");
    bytes32 public constant CONSUMER_ROLE = keccak256("CONSUMER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 public platformFee = 0.05 ether; // Percentage for platform (e.g., 5%)
    uint256 public mintFee = 0.001 ether;
    uint256 public monthlyFee = 0.002 ether;
    uint256 private _tokenIdCounter;

    enum DataCategory { PUBLIC, PRIVATE, CONFIDENTIAL }

    struct Subscription {
        uint256 expiresAt;
        DataCategory category;
    }

    /// @dev STATE MAPPINGS
    mapping(uint256 => uint256) public tokenPrices;
    mapping(uint256 => DataCategory) public dataCategories;
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;

    /// EVENTS
    event DataTokenCreated(uint256 indexed tokenId, string indexed dataHash, DataCategory indexed category, address creator);
    event DataListedForSale(uint256 indexed tokenId, uint256 indexed price, address creator);
    event SubscriptionCreated(address creator, uint256 indexed tokenId, uint256 duration);

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can perform this action");
        _; // Continue with the rest of the function execution
    }

    /// @notice Initialize the state of the contract
    /// @dev Admin role is granted to deployer
    /// @dev The deployer is the owner of the protocol
    constructor() ERC721("DecentralizedDataMarket", "DATAM") Ownable(msg.sender) {
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /// @notice Mints a new data token representing a data asset on IPFS. Also transfer minting fees to the protocol owner
    /// @dev Throw if msg.sender has not DATA_PROVIDER_ROLE role.
    /// @dev Throw if msg.value < mintFee. Message: "Insufficient fee"
    /// @dev Throw if ipfsHash length is zero. Message: "Invalid IPFS hash"
    /// @param ipfsHash The hash obtained after store the data asset into IPFS by a client
    /// @param category An access level determined by the data asset owner
    function mintDataToken(string memory ipfsHash, DataCategory category) public payable onlyRole(DATA_PROVIDER_ROLE) {
        // Check if sender has sufficient balance
        require(msg.value >= mintFee, "Insufficient fee");

        // Check if sender has sufficient balance
        require(bytes(ipfsHash).length > 0, "Invalid IPFS hash");

        // Mint the token and link it to the IPFS hash string
        uint256 tokenId = _tokenIdCounter + 1;
        _safeMint(msg.sender, tokenId);

        // Link the token to the IPFS data hash using setTokenURI
        _setTokenURI(tokenId, ipfsHash);
        dataCategories[tokenId] = category; // Store the category for later access control
        
        // Pay mintFee to the protocol owner
        payable(owner()).transfer(mintFee);

        // Emit the DataTokenCreated event with the correct hash
        emit DataTokenCreated(tokenId, ipfsHash, category, msg.sender);
    }

    /// @notice Lists a data token for sale at a specified price
    /// @dev Throw if msg.sender has not DATA_PROVIDER_ROLE role.
    /// @dev Throw if msg.sender is not the token owner. Message: "Only token owner can perform this action"
    /// @dev Throw if price is zero. Message: "Price must be greater than zero"
    /// @param tokenId The token id of the desired data asset 
    /// @param price The price to list the data asset
    function listDataForSale(uint256 tokenId, uint256 price) public onlyRole(DATA_PROVIDER_ROLE) onlyOwnerOf(tokenId) {
        require(price > 0, "Price must be greater than zero");
        tokenPrices[tokenId] = price;
        emit DataListedForSale(tokenId, price, msg.sender);
    }

    /// @notice Enables a consumer to purchase a data token. Also transfer platform fees to the protocol owner
    /// @dev Throw if msg.sender has not CONSUMER_ROLE role.
    /// @dev Throw if tokenPrice is zero. Message: "Token has not price set yet"
    /// @dev Throw if msg.value is less than tokenPrice. Message: "Insufficient funds"
    /// @param tokenId The token id of the desired data asset
    function purchaseData(uint256 tokenId) public payable onlyRole(CONSUMER_ROLE) {
        uint256 tokenPrice = priceOf(tokenId);
        require(tokenPrice > 0, "Token has not price set yet");
        require(msg.value >= tokenPrice, "Insufficient funds");
        uint256 sellerValue = tokenPrice * (100 - platformFee) / 100;
        uint256 platformValue = tokenPrice - sellerValue;
        safeTransferFrom(ownerOf(tokenId), msg.sender, tokenId);
        payable(ownerOf(tokenId)).transfer(sellerValue);
        payable(owner()).transfer(platformValue); 
    }

    /// @notice Retrieve the price of a listed token
    /// @param tokenId The token id of the desired data asset
    function priceOf(uint256 tokenId) public view returns (uint256) {
        return tokenPrices[tokenId];
    }

    /// @notice Grants a consumer access to data based on their subscription retrieving the token uri.
    /// @dev Throw if msg.sender has not CONSUMER_ROLE role.
    /// @dev Throw if the subscription expired. Message: "Subscription expired"
    /// @dev Throw if the subscription does not match the category of access level. Message: "Insufficient access level"
    /// @param tokenId The token id of the desired data asset
    function requestDataAccess(uint256 tokenId) public payable onlyRole(CONSUMER_ROLE) returns (string memory) {
        Subscription memory subscription = subscriptions[msg.sender][tokenId];
        require (subscription.expiresAt <= block.timestamp, "Subscription expired");
        require (subscription.category <= dataCategories[tokenId], "Insufficient access level");
        return tokenURI(tokenId);
    }

    /// @notice Allows a consumer to subscribe to a data token for a specified duration.
    /// @dev Throw if msg.sender has not CONSUMER_ROLE role.
    /// @dev Throw if the tokenId does not exist. Message: "Token does not exist"
    /// @dev Throw if the msg.value is less than the monthlyFee. Message: "Insufficient funds"
    /// @param tokenId The token id of the desired data asset
    function subscribeToToken(uint256 tokenId) public payable onlyRole(CONSUMER_ROLE) {
        require(tokenId <= _tokenIdCounter, "Token does not exist");
        require(msg.value >= monthlyFee, "Insufficient funds");

        // Require token approval or ownership
        require(isApprovedForAll(ownerOf(tokenId), msg.sender) || getApproved(tokenId) == msg.sender || ownerOf(tokenId) == msg.sender, "Token not approved");

        // Calculate subscription duration based on price and rate (e.g., 1 month per 0.002 ETH)
        uint256 duration = 30 * 1 days;

        // Create subscription
        subscriptions[msg.sender][tokenId] = Subscription({
            expiresAt: block.timestamp + duration,
            category: dataCategories[tokenId] // Grant access to the token's category
        });

        // Process payments to owner and platform fees
        uint256 ownerValue = monthlyFee * (100 - platformFee) / 100;
        uint256 platformValue = monthlyFee - ownerValue;
        payable(ownerOf(tokenId)).transfer(ownerValue);
        payable(owner()).transfer(platformValue); 

        emit SubscriptionCreated(msg.sender, tokenId, duration);
    }

    /// @notice Retrieves the IPFS hash associated with a data token
    /// @dev Throw if msg.sender has not DATA_PROVIDER_ROLE role.
    /// @dev Throw if msg.sender is not the token owner. Message: "Only token owner can perform this action"
    /// @param tokenId The token id of the desired data asset
    function getDataURI(uint256 tokenId) public view onlyRole(DATA_PROVIDER_ROLE) onlyOwnerOf(tokenId) returns (string memory) {
        // Get the IPFS hash
        return tokenURI(tokenId);
    }

    /// @notice Grants the DATA_PROVIDER_ROLE to an account.
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @param account The address to grant the role
    function grantDataProviderRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(DATA_PROVIDER_ROLE, account);
    }

    /// @notice Grants the ADMIN_ROLE to an account.
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @param account The address to grant the role
    function grantAdminRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(ADMIN_ROLE, account);
    }

    /// @notice Grants the CONSUMER_ROLE to an account.
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @param account The address to grant the role
    function grantConsumerRole(address account) public onlyRole(ADMIN_ROLE) {
        _grantRole(CONSUMER_ROLE, account);
    }

    /// @notice Revokes the DATA_PROVIDER_ROLE from an account.
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @param account The address to grant the role
    function revokeDataProviderRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(DATA_PROVIDER_ROLE, account);
    }

    /// @notice Revokes the ADMIN_ROLE from an account (preventing self-revocation).
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @dev Throw if msg.sender is the same account sent by param. Message: "Cannot revoke own admin role"
    /// @param account The address to grant the role
    function revokeAdminRole(address account) public onlyRole(ADMIN_ROLE) {
        require(account != msg.sender, "Cannot revoke own admin role"); // Prevent self-revocation
        _revokeRole(ADMIN_ROLE, account);
    }

    /// @notice Revokes the CONSUMER_ROLE from an account.
    /// @dev Throw if msg.sender has not ADMIN_ROLE role.
    /// @param account The address to grant the role
    function revokeConsumerRole(address account) public onlyRole(ADMIN_ROLE) {
        _revokeRole(CONSUMER_ROLE, account);
    }

    /// @notice Checks if the contract supports a given interface.
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721URIStorage) returns (bool) {
        if (interfaceId == type(IERC165).interfaceId) {
            return true; // Always support IERC165
        } else {
            return super.supportsInterface(interfaceId); // Delegate to base contracts
        }
    }
}