// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @author tbtstl & gzork
/// @title A Simple NFT Market
contract NFTMarket {

    struct listedNftToken {
        address owner;
        uint256 price;
    }

    struct listedNft {
        mapping(uint256 => listedNftToken) tokens;
        mapping(uint256 => uint256) indexOfToken;
        uint256[] tokensArray;
        uint256[] floorTokens;
        uint256 floorPrice;
        bool active;
    }

    mapping(address => listedNft) private listedNfts;
    address[] private listedNftsArray;

    // This function can be very costly to execute depending on the size of the NFT listing
    // This means it wouldn't scale well so the goal is to keep its usage to a minimum
    // and to find a more efficient approach
    function buildFloor(address _nftAddress) internal {
        if (listedNfts[_nftAddress].tokensArray.length > 1) {
            for (uint256 i = 0; i<listedNfts[_nftAddress].tokensArray.length-1; i++){
                if (listedNfts[_nftAddress].floorPrice == 0 || listedNfts[_nftAddress].tokens[listedNfts[_nftAddress].tokensArray[i]].price < listedNfts[_nftAddress].floorPrice) {
                    listedNfts[_nftAddress].floorPrice = listedNfts[_nftAddress].tokens[listedNfts[_nftAddress].tokensArray[i]].price;
                    delete listedNfts[_nftAddress].floorTokens;
                    listedNfts[_nftAddress].floorTokens.push(listedNfts[_nftAddress].tokensArray[i]);
                } else if (listedNfts[_nftAddress].tokens[listedNfts[_nftAddress].tokensArray[i]].price == listedNfts[_nftAddress].floorPrice) {
                    listedNfts[_nftAddress].floorTokens.push(listedNfts[_nftAddress].tokensArray[i]);
                }
            }
        } else if (listedNfts[_nftAddress].tokensArray.length == 1) {
            delete listedNfts[_nftAddress].floorTokens;
            listedNfts[_nftAddress].floorTokens = listedNfts[_nftAddress].tokensArray;
            listedNfts[_nftAddress].floorPrice = listedNfts[_nftAddress].tokens[listedNfts[_nftAddress].tokensArray[0]].price;
        } else {
            delete listedNfts[_nftAddress].floorTokens;
            listedNfts[_nftAddress].floorPrice = 0;
        }
    }

    function _removeArrayItem(uint256 _index, uint256[] storage _array) internal returns (uint256[] memory) {
        if (_index >= _array.length) return _array;
        if (_array.length > 1) {
            for (uint256 i = _index; i<_array.length-1; i++){
                _array[i] = _array[i+1];
            }
        }
        delete _array[_array.length-1];
        _array.pop();
        return _array;
    }

    function removeTokensArrayItem(address _nftAddress, uint256 _tokenID) internal {
        listedNfts[_nftAddress].tokensArray = _removeArrayItem(listedNfts[_nftAddress].indexOfToken[_tokenID], listedNfts[_nftAddress].tokensArray);
        delete listedNfts[_nftAddress].indexOfToken[_tokenID];
    }

    function getAllListedNfts() public view returns (address[] memory) {
        return listedNftsArray;
    }

    function getNftListedTokens(address _nftAddress) external view returns (uint256[] memory) {
        return listedNfts[_nftAddress].tokensArray;
    }

    function getNftListedFloorTokens(address _nftAddress) external view returns (uint256[] memory) {
        return listedNfts[_nftAddress].floorTokens;
    }

    function getNftTokenInfo(address _nftAddress, uint256 _tokenID) external view returns (listedNftToken memory) {
        return listedNfts[_nftAddress].tokens[_tokenID];
    }

    function getNftListings(address _nftAddress) internal view returns (listedNft storage) {
        return listedNfts[_nftAddress];
    }

    function _addListedNft(address _nftAddress) internal {
        // https://ethereum.stackexchange.com/questions/27510/solidity-list-contains/27518
        if (!listedNfts[_nftAddress].active) {
            listedNfts[_nftAddress].active = true;
            listedNftsArray.push(_nftAddress);
        }
    }

    function _purchase(address _nftAddress, uint256 _tokenID) internal {
        require(msg.value == listedNfts[_nftAddress].tokens[_tokenID].price);
        ERC721 nftContract = ERC721(_nftAddress);
        address owner = listedNfts[_nftAddress].tokens[_tokenID].owner;
        _delist(_nftAddress, _tokenID);
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenID);
        (bool success,) = owner.call{value: msg.value}("");
        require(success, "Failed to send ether");
    }

    function _delist(address _nftAddress, uint256 _tokenID) internal {
        uint256 price = listedNfts[_nftAddress].tokens[_tokenID].price;
        delete listedNfts[_nftAddress].tokens[_tokenID];
        removeTokensArrayItem(_nftAddress, _tokenID);
        if (listedNfts[_nftAddress].floorPrice == price) {
            for (uint i=0; i < listedNfts[_nftAddress].floorTokens.length; i++) {
                if (listedNfts[_nftAddress].floorTokens[i] == _tokenID) {
                    listedNfts[_nftAddress].floorTokens = _removeArrayItem(i, listedNfts[_nftAddress].floorTokens);
                }
            }
            if (listedNfts[_nftAddress].floorTokens.length == 0) {
                listedNfts[_nftAddress].floorPrice = 0;
                buildFloor(_nftAddress);
            }
        }
    }

    function delist(address _nftAddress, uint256 _tokenID) external {
        require(msg.sender == listedNfts[_nftAddress].tokens[_tokenID].owner);
        ERC721 nftContract = ERC721(_nftAddress);
        _delist(_nftAddress, _tokenID);
        nftContract.safeTransferFrom(address(this), msg.sender, _tokenID);
    }

    /// List an NFT for sale.
    /// @param _nftAddress the address of the NFT contract
    /// @param _tokenID the token ID for the NFT being sold
    /// @param _amount the amount in wei to sell the NFT for
    function list(address _nftAddress, uint256 _tokenID, uint256 _amount) external {
        ERC721 nftContract = ERC721(_nftAddress);
        _addListedNft(_nftAddress);
        if (listedNfts[_nftAddress].floorPrice == 0 || _amount < listedNfts[_nftAddress].floorPrice) {
            listedNfts[_nftAddress].floorPrice = _amount;
            delete listedNfts[_nftAddress].floorTokens;
            listedNfts[_nftAddress].floorTokens.push(_tokenID);
        } else if (_amount == listedNfts[_nftAddress].floorPrice) {
            listedNfts[_nftAddress].floorTokens.push(_tokenID);
        }
        listedNfts[_nftAddress].indexOfToken[_tokenID] = listedNfts[_nftAddress].tokensArray.length;
        listedNfts[_nftAddress].tokensArray.push(_tokenID);
        listedNfts[_nftAddress].tokens[_tokenID].owner = msg.sender;
        listedNfts[_nftAddress].tokens[_tokenID].price = _amount;
        nftContract.transferFrom(msg.sender, address(this), _tokenID);
    }

    /// Purchase a specified NFT
    /// @param _nftAddress the address of the NFT contract
    /// @param _tokenID the token ID for the NFT being sold
    function purchase(address _nftAddress, uint256 _tokenID) external payable {
        // This will guarantee the owner is not 0x0 and therefore the token is listed
        require(listedNfts[_nftAddress].tokens[_tokenID].owner != address(0));
        _purchase(_nftAddress, _tokenID);
    }

    /// Return the lowest listed NFT for sale in a given collection
    /// @param _nftAddress the address of the NFT contract
    function getFloorPrice(address _nftAddress) view external returns (uint256) {
        return listedNfts[_nftAddress].floorPrice;
    }

    /// Purchase the cheapest NFT in a specified collection.
    /// @param _nftAddress the address of the NFT contract
    function buyFloor(address _nftAddress) public payable {
        // TODO: Implement this function!
    }
}