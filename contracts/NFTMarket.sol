// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

/// @author tbtstl
/// @title A Simple NFT Market
contract NFTMarket {

    /// List an NFT for sale.
    /// @param _nftAddress the address of the NFT contract
    /// @param _tokenID the token ID for the NFT being sold
    /// @param _amount the amount in wei to sell the NFT for
    function list(address _nftAddress, uint256 _tokenID, uint256 _amount) public {
        // TODO: Implement this function!
    }

    /// Purchase a specified NFT
    /// @param _nftAddress the address of the NFT contract
    /// @param _tokenID the token ID for the NFT being sold
    function purchase(address _nftAddress, uint256 _tokenID) public payable {
        // TODO: Implement this function!
    }

    /// Return the lowest listed NFT for sale in a given collection
    /// @param _nftAddress the address of the NFT contract
    function getFloorPrice(address _nftAddress) public returns (uint256) {
        // TODO: Implement this function!

        return 1;
    }

    /// Purchase the cheapest NFT in a specified collection.
    /// @param _nftAddress the address of the NFT contract
    function buyFloor(address _nftAddress) public payable {
        // TODO: Implement this function!
    }
}