# 1. Decentralised Marketplace Solidity Smart Contract

Welcome to the **Decentralised Marketplace** project repository! This decentralized solana-based project from RiseIn's Solidity Fundamentals Course leverages the Solidity blockchain programming language to design, implement, and test a decentralised Marketplace smart contract for the Ethereum network. Participants can verify sellers, add and update items, buy and sell items as well as receive payments.


## 1.1. Table of Contents

- [1. Decentralised Marketplace Solidity Smart Contract](#1-decentralised-marketplace-solidity-smart-contract)
  - [1.1. Table of Contents](#11-table-of-contents)
  - [1.2. Overview](#12-overview)
  - [1.3. Features](#13-features)
  - [1.4. Smart Contracts](#14-smart-contracts)
  - [1.5. Contributing](#15-contributing)
  - [1.6. Usage](#16-usage)

## 1.2. Overview

The **Decentralised Marketplace** Solidity smart contract provides an intuitive overview of the inner workings of a potential Marketplace dApp. You can think of it as a decentralised Facebook Marketplace on an Ethereum network. This project ensures transparency and trust in the local business or products in a controlled, yet free environment through the use of smart contracts. You'll find the presence of market authorities in the smart contract whose major purpose serves to verify a seller (any address submitted to become a seller on the platform) and remove a seller should the seller be in violation. The marketplace is to serve all items that can be listed for sale. Visitors / buyers can verify seller information linked with an item, view items from a specific seller,ake purchases. Sellers can also perform same functions as buyers.
The **Decentralised Marketplace** Solidity smart contract provides an intuitive overview of the inner workings of a potential Marketplace dApp. You can think of it as a decentralised Facebook Marketplace on an Ethereum network. This project ensures transparency and trust in the local business or products in a controlled, yet free environment through the use of smart contracts. You'll find the presence of market authorities in the smart contract whose major purpose serves to verify a seller (any address submitted to become a seller on the platform) and remove a seller should the seller be in violation. The marketplace is to serve all items that can be listed for sale. Visitors / buyers can verify seller information linked with an item, view items from a specific seller, make purchases. Sellers can also perform same functions as buyers.


## 1.3. Features

- Owner and market authorities can add other market authorities
- Market authorities can verify Sellers
- Sellers can add & delete their listed items
- Sellers can view and withdraw sales balances from contract
- Buyers can retrieve seller and item information
- Contract returns excess value sent by buyres during purchase
- 

## 1.4. Smart Contracts

The Solidity smart contracts in this project facilitate the workings of the Decentralised Marketplace as described above.


## 1.5. Contributing

Contributions to this project are welcome! To contribute:
1. Fork the repository.
2. Create a new branch for your feature/bug fix.
3. Make changes and test thoroughly.
4. Commit with clear and concise messages.
5. Push changes to your fork.
6. Submit a pull request describing your changes.


## 1.6. Usage

Open this smart contract in [Remix](https://remix.ethereum.org/#lang=en&optimize=false&runs=200&evmVersion=null&version=soljson-v0.8.18+commit.87f61d96.js), deploy to a testnet or the Remix VM and have fun interacting. **OR** Clone this repository and interact with it on thirdweb via
```
npx thirdweb deploy
```
Must have installed ```npm``` to work with thirdweb.

---
Thank you for your interest in the Decentralised Marketplace project! For questions or suggestions, reach out to us or open an issue on [GitHub](https://github.com/Ikpong-Joseph/Decentralised-Marketplace). Happy reviewing! 🚀
