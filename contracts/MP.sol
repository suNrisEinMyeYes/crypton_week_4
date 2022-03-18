//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC721Added.sol";


contract MarketPlace {
    using Counters for Counters.Counter;
    Counters.Counter private _itemsIds;

    address payable owner;
    address private _erc20Tkns;
    address private _myNFTs;


    constructor(address _erc20Tokens, address myNFTs){
        owner = payable(msg.sender);
        _myNFTs = myNFTs;
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

    struct Item  {
        uint itemId; //unique to each item in marketplace
        address nftContract; //batch of tokenIds
        uint256 tokenId; //tokenId of NFTcontract | unique for contract but not for mp
        address owner;
        uint256 price;
        Status status;
        address lastBidder;
        uint256 auctionEndTime; 
    }

    event ItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
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
        address owner,
        uint256 price,
        Status status 
    );

    event AuctionEnitiated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 price,
        Status status 
    );

    event AuctionCancelled (
        uint indexed itemId,
        Status status 
    );

    event AuctionFinished (
        uint indexed itemId,
        address owner,
        uint256 price,
        Status status 
    );

    event BidMade (
        uint indexed itemId,
        uint256 price,
        address buyer
    );

    mapping(uint256 => Item) private idToItem;
    
    function createItem(address nftContract, uint256 tokenId, uint256 price) public {
        require(price > 0, "Price should be >0");
        address _owner = IERC721(nftContract).ownerOf(tokenId);
        require(_owner == msg.sender, "Not an owner");
        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();

        idToItem[itemId] = Item(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            price,
            Status.exist,
            address(0),
            0
        );
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        emit ItemCreated(itemId, nftContract, tokenId, msg.sender, price, Status.exist); 
    }

    function mint(uint256 price) public{
        uint256 balance = ERC20(_erc20Tkns).balanceOf(msg.sender);
        uint256 allowence = ERC20(_erc20Tkns).allowance(msg.sender, address(this));
        require(balance>price, "Not enough tokens to buy");
        require(allowence>price, "Not enough allowence");

        _itemsIds.increment();
        uint256 itemId = _itemsIds.current();
        ERC20(_erc20Tkns).transferFrom(msg.sender, address(this), price);
        uint256 tokenId = IERC721Added(_myNFTs).awardItem(address(this));

        idToItem[itemId] = Item(
            itemId,
            _myNFTs,
            tokenId,
            msg.sender,
            price,
            Status.exist,
            address(0),
            0
        );

        emit ItemCreated(itemId, _myNFTs, tokenId, msg.sender, price, Status.exist);  
    }

    function listingItem(uint itemId, uint256 price) public{
        require(msg.sender == idToItem[itemId].owner, "Not an owner");
        require(price > 0, "Price should be >0");

        idToItem[itemId].status = Status.selling_via_listing;
        idToItem[itemId].price = price;

        emit ListingEnitiated(itemId, idToItem[itemId].owner, price, Status.selling_via_listing);
    }

    function cancel(uint itemId) public{
        require(idToItem[itemId].status == Status.selling_via_listing, "Not listed");

        require(msg.sender == idToItem[itemId].owner, "Not an owner");

        idToItem[itemId].status = Status.exist;

        emit ListingCancelled(itemId, Status.exist);
    }

    function buyItem(uint itemId, address nftContract) public payable{
        uint256 balance = ERC20(_erc20Tkns).balanceOf(msg.sender);
        uint256 allowence = ERC20(_erc20Tkns).allowance(msg.sender, idToItem[itemId].owner);

        require(balance>msg.value, "Not enough tokens to buy");
        require(allowence>idToItem[itemId].price, "Not enough allowence");

        ERC20(_erc20Tkns).transferFrom(msg.sender, address(this), msg.value);
        //IERC721(nftContract).transferFrom(address(this), msg.sender, idToItem[itemId].tokenId);
        idToItem[itemId].owner = msg.sender;
        
        emit LListingCommited(itemId, nftContract, idToItem[itemId].tokenId, msg.sender, msg.value, Status.exist);
    }

    function stockCheck() public returns(uint, uint256){

    }

    function startAuction(uint itemId) public payable {
        require(msg.sender == idToItem[itemId].owner, "Not an owner");

        idToItem[itemId].price = msg.value;
        idToItem[itemId].auctionEndTime = block.timestamp + 3 minutes;
        idToItem[itemId].status = Status.selling_via_auction;

        emit AuctionEnitiated(itemId, idToItem[itemId].nftContract, idToItem[itemId].tokenId, msg.sender , msg.value, Status.selling_via_auction);

    }

    function makeBid(uint itemId) public payable {
        uint256 balance = ERC20(_erc20Tkns).balanceOf(msg.sender);
        require(balance>msg.value, "Not enough tokens to make a bid"); 
        require(msg.value>idToItem[itemId].price, "Bid is lower than price");
        require(block.timestamp < idToItem[itemId].auctionEndTime, "Auction is finished");

        idToItem[itemId].lastBidder = msg.sender;
        idToItem[itemId].price = msg.value;
        emit BidMade(itemId, msg.value, msg.sender);

    }

    function cancelAuction(uint itemId) public{
        require(block.timestamp < idToItem[itemId].auctionEndTime, "Auction is finished");
        require(idToItem[itemId].status == Status.selling_via_auction, "Not listed in auction");

        idToItem[itemId].status = Status.exist;

        emit AuctionCancelled(itemId, Status.exist);

    }

    function finishAuction(uint itemId) public{
        require(block.timestamp > idToItem[itemId].auctionEndTime, "Auction is not finished");
        if (idToItem[itemId].lastBidder == address(0)){

            emit AuctionFinished(itemId, idToItem[itemId].owner, idToItem[itemId].price, Status.exist);

        } else{
            uint256 balance = ERC20(_erc20Tkns).balanceOf(idToItem[itemId].lastBidder);
            uint256 allowence = ERC20(_erc20Tkns).allowance(idToItem[itemId].lastBidder, idToItem[itemId].owner);
            
            require(balance>idToItem[itemId].price, "Not enough tokens to buy");
            require(allowence>idToItem[itemId].price, "Not enough allowence");
            IERC20(_erc20Tkns).transferFrom(idToItem[itemId].lastBidder, idToItem[itemId].owner, idToItem[itemId].price);
            idToItem[itemId].owner = idToItem[itemId].lastBidder;
            emit AuctionFinished(itemId, idToItem[itemId].owner, idToItem[itemId].price, Status.exist);
            idToItem[itemId].lastBidder = address(0);
        }

        idToItem[itemId].status = Status.exist;
        idToItem[itemId].auctionEndTime = 0;
    }

    function setMyNFT(address addrNFT) public{
        _myNFTs = addrNFT;
    }

    /*function withdrawNFT(uint itemId) public{
        require(msg.sender == idToItem[itemId].owner, "Not an owner");
        IERC721(idToItem[itemId].nftContract).transferFrom(address(this), msg.sender, idToItem[itemId].tokenId);

    }

    */
    function getItem(uint itemId)public view returns ( Item memory){
        return idToItem[itemId];
    }

    function getStatusListing() public pure returns(Status){
        return Status.selling_via_listing;
    }

    function getStatusAuction() public pure returns(Status){
        return Status.selling_via_auction;
    }

    function getStatusExist() public pure returns(Status){
        return Status.exist;
    }

    function getStatusUknown() public pure returns(Status){
        return Status.unknown;
    }
   
}
