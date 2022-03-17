//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract MarketPlace {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsIds;

    address payable owner;
    address private _erc20Tkns;

    constructor(address _erc20Tokens){
        owner = payable(msg.sender);
        _erc20Tkns = _erc20Tokens;

    }

    enum Status {
        exist,
        selling_via_listing,
        selling_via_auction,
        sold
    }

    struct Item {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        Status status; 
    }

    event ItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        Status status 
    );

    mapping(uint256 => Item) private idToItem;

    
    function createItem(address nftContract, uint256 tokenId, uint256 price) public payable {
        require(price>0, "Price should be >0");
        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();

        idToItem[itemId] = Item(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            Status.exist
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);//already minted, what to do if i dont know wether it was minted?
    }
   
}
