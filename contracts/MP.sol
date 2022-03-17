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
    /*
        unknown - default value when token does not listed in MP
        exist - item is in MP
        selling_via_listing - currently is available to buy on stock
        selling_via_auction - currently is available to buy on auction

    */

    enum Status {
        unknown,
        exist, 
        selling_via_listing,
        selling_via_auction
    }

    struct Item {
        uint itemId; //unique to each item in marketplace
        address nftContract; //batch of tokenIds
        uint256 tokenId; //tokenId of NFTcontract | unique for contract but not for mp
        address payable seller;
        address payable owner;
        uint256 price;
        Status status; 
    }
    struct Listing{
        uint itemId;
        uint256 price;
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

    event ListingEnitiated (
        uint indexed itemId,
        address owner,
        uint256 price,
        Status status 
    );
    event ListingCancelled (
        uint indexed itemId,
        Status status 
    );

    event LListingCommited (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        Status status 
    );

    mapping(uint256 => Item) private idToItem;
    mapping(uint256 => Listing) private listing;
    
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
        IERC721(nftContract).approve(address(this), tokenId);
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);//already minted, what to do if i dont know wether it was minted?
        emit ItemCreated(itemId, nftContract, tokenId, msg.sender, address(0), price, Status.exist); 
    }

    function listingItem(uint itemId, uint256 price) public payable{
        listing[itemId] = Listing(
            itemId,
            price
        );
        idToItem[itemId].status = Status.selling_via_listing;
        emit ListingEnitiated(itemId, idToItem[itemId].owner, price, Status.selling_via_listing);
    }

    function cancel(uint itemId) public{
        listing[itemId] = Listing(
            0,
            0
        );
        idToItem[itemId].status = Status.exist;
        emit ListingCancelled(itemId, Status.exist);
    }

    function buyItem(uint itemId) public payable{
        IERC721
    }
   
}
