# Decentralized Data Marketplace MVP

DeFiDataMarket is a decentralized data marketplace built on the Ethereum blockchain. It enables secure and efficient data exchange between data providers and consumers, while facilitating data tokenization, access control, and revenue sharing.

## Key features
- Data tokenization using non-fungible token (NFT) standards
- Data access control with fine-grained permissioning
- Data subscription model for recurrent revenue streams
- Secure and decentralized data storage using IPFS
- Data pricing and payments using ETH
- Data marketplace for data discovery and trade

## Core contracts
- DecentralizedDataMarket.sol

## External dependencies
### Openzeppelin libraries
We'll utilize these OpenZeppelin libraries:
- `ERC721`: For creating non-fungible tokens (NFTs) representing data ownership so we can keep our data asset tight to an specific owner.
- `ERC721URIStorage` : To be able to edit the token URI
- `AccessControl`: For managing roles and access permissions.
- `Ownable`: To implement ownable pattern.

## Getting started

### Prerequisites:
- Node.js
- Truffle
- Ganache (Optionally)

### Steps
1. Clone the repository
2. Install required packages
3. Compile and deploy contracts
4. Interact with contracts using a web3 or ethers library

### Deploy the protocol in a local network with hardhat
1. Open a terminal and run `npx hardhat node` to run a local hardhat node
2. Open a new terminal and run `npx hardhat run --network localhost scripts/deploy.js` to deploy the contract in the local network

### Deploy the protocol in seploia
2. Open a new terminal and run `npx hardhat run --network sepolia scripts/deploy.js` to deploy the contract in sepolia testnet

## Key features and functionality

### Data tokenization
Data providers can create NFTs representing their data assets. Each NFT is associated with a unique data hash and stored on IPFS.
1. Tokenize data assets: it will be done with ERC721 Open Zeppelin library
2. Decentralized storage: 
    1. **IPFS Integration:** Instead of hardcoding data within the smart contract, we utilize an IPFS library to interact with the InterPlanetary File System. This library allows storing data off-chain in a decentralized and tamper-proof manner.
    2. **Data Hashing:** Before storing data on IPFS, it's hashed using a cryptographic function like SHA-256. This creates a unique identifier for the data regardless of its content.
3. Enable users to mint tokens representing ownership or access rights to their data assets: 
    1. We’ll provide a function to mint data assets called `mintDataToken`
        1. **Mint Function:** 
            - Receives the IPFS hash (the client who is requesting this method already stored the file there).
            - Also the client provides a type of access level for specific asset.
            - Mints an ERC721 token representing ownership of the data.
            - Associates the token with the IPFS hash of the data using `setTokenURI`.
    2. Considerations: we assume we are testing with small media or text files on IPFS for this MVP.
    3. Observations: for future implementations we can consider use some optimization strategies such as:
        - **IPFS chunking:** Break down large files into smaller chunks stored and referenced separately on IPFS.
        - **Off-chain storage:** Consider leveraging off-chain storage solutions like Arweave for large media while maintaining on-chain control and references.
        - **Gas optimization:** Choose efficient IPFS libraries and carefully evaluate function gas costs.


### Data access control
Data providers can define access rules for their NFTs, specifying who can access the data and under what conditions.

### Data subscription
Data consumers can purchase subscriptions to access data for a specific period of time.

### Data marketplace
A marketplace allows data providers to list their NFTs for sale and data consumers to discover and purchase them.

### Revenue sharing
Data providers can earn revenue by selling their data or by setting up subscription plans.

## Future releases
Here are some notes showing how I would improve the code given more time.

1. Provide the ability to modify platform fees, minting fees and subscription fees. Now they are hardcoded and unable to change.
2. Provide a DataCategory admin manager so Administrators can add/remove category types as they want.
3. Add a Subscription.sol contract to treat this logic separately. Now is in the main contract.
4. Provide different types of subscription models. The current logic charges an specific amount for 1 month of subscription
