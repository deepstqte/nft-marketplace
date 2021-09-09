# ZORA Solidity Take Home Challenge

Thanks for your interest in joining ZORA! This file outlines a quick test to assess your solidity and problem solving skills.  

ZORA uses typescript and solidity very heavily – as such, we've designed this repository to be as close to our internal tooling as possible. 

## Background

Selling an NFT on-chain can quickly become a complicated problem. We want to ensure that a contract on-chain (a DAO, for example) has access to the same information that an EOA has. 

For example, a user may want to scan all NFTs in a collection, and buy one that they like. Alternatively, a user may simply want to buy the cheapest NFT in a collection. It is quite trivial to manage this off-chain, but significantly more interesting to surface pricing entirely on-chian.

## The Task

In the `contracts/` directory, design a contract named `NFTMarket` that implements the following methods:
- `list(address _nftAddress, uint256 _tokenID, uint256 _amount)`
    - `list` should take an NFT into escrow and list it for sale for the given `_amount` in wei
- `purchase(address _nftAddress, uint256 _tokenID)`
    - `purchase` should transfer the `_amount` from `list()` to the seller, and transfer the NFT to the buyer.
- `getFloorPrice(address _nftAddress)` _(bonus)_
    - `getFloorPrice` should return a `uint256` wei price for the current cheapest NFT in a given collection.
- `buyFloor(address _nftAddress)` _(bonus)_
    - `buyFloor` should purchase the cheapest NFT in a specified collection.
    
## Requirements
We've provided some sample tests that should all pass if the methods are implemented correctly.

If you'd like, you can also add tests to check additional behaviour.

**Note that `getFloorPrice` and `buyFloor` are _difficult_, and not required. Major props if you can implement them efficiently!** You may also decide to change the parameters around for these functions. 

## Setup
First, install the dependencies
```shell
yarn
```

Compile your contracts with `hardhat`
```shell
npx hardhat compile
```

Run your tests with `hardhat`
```shell
npx hardhat test
```

## What we're looking for
We're interested in your coding style, your familiarity with developer tooling for smart contracts or your ability to learn the tooling, and your Solidity proficiency. We're also looking to see your eye for security and gas efficiency.

## How to complete this challenge
Fork this repo, _and make your new repo private_. Write your code in the `contracts/` and `test/` directory.

Send [t@zora.co](mailto:t@zora.co) your repository when complete (you can add `tbtstl` as a contributor).

Good luck!
