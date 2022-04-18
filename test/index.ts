import { expect } from "chai";
import { Contract, Signer } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { ethers } from "hardhat";
import { addressNFT, addressTkns, myWallet } from "../config";

describe("Token contract", function () {

  let Token;
  let nft;
  let erc20;
  let erc20Token : Contract;
  let marketPlace : Contract;
  let nftToken : Contract;

  let owner : Signer;
  let addr1 : Signer;
  let addr2 : Signer;

  let nftOwner : Signer;

  let erc20User : Signer;


  beforeEach(async function () {
      


    erc20 = await ethers.getContractFactory("Test"); 
    [erc20User] = await ethers.getSigners();     
    erc20Token = await erc20.deploy();

    nft = await ethers.getContractFactory("GameItem"); 
    [nftOwner] = await ethers.getSigners();     
    nftToken = await nft.deploy();

    Token = await ethers.getContractFactory("MarketPlace");
    [owner, addr1, addr2] = await ethers.getSigners();
    marketPlace = await Token.deploy(erc20Token.address, nftToken.address);

      


      
    });

    describe("create", function () {
      
      it("upload some tokens", async function () {
       
        
        await nftToken.connect(nftOwner).awardItem(addr1.getAddress());
        console.log("1")
        //await hardhatToken.connect(owner).awardItem(addr1.getAddress())
        await nftToken.connect(addr1).approve(marketPlace.address,1)
        console.log("1")

        await expect( marketPlace.connect(addr1).createItem(nftToken.address,1,parseEther("0"))).to.be.revertedWith("Price should be >0");
        console.log("1")
        await expect( marketPlace.connect(addr2).createItem(nftToken.address,1,parseEther("50"))).to.be.revertedWith("Not an owner");
        console.log("1")

        await marketPlace.connect(addr1).createItem(nftToken.address, 1, parseEther("50"));
        console.log("1")

        await expect(await nftToken.ownerOf(1)).to.equal(marketPlace.address);
        


      });
      it("mint some tokens", async function () {
        await erc20Token.connect(erc20User).earn(await addr1.getAddress(), parseEther("50"))
        await erc20Token.connect(addr1).approve(marketPlace.address, parseEther("10"))
        await expect(marketPlace.connect(addr1).mint(parseEther("60"))).to.be.revertedWith("Not enough tokens to buy");
        await marketPlace.connect(addr1).mint(parseEther("10"))


        


      });
    });

    describe("listing", function () {
      
      it("list, cancel, buy", async function () {

        

        await nftToken.connect(nftOwner).awardItem(addr1.getAddress());
        //await hardhatToken.connect(owner).awardItem(addr1.getAddress())
        await nftToken.connect(addr1).approve(marketPlace.address,1)

        await marketPlace.connect(addr1).createItem(nftToken.address, 1, parseEther("50"));

        await expect(marketPlace.connect(addr1).listingItem(1,parseEther("0"))).to.be.revertedWith("Price should be >0")

        await expect(marketPlace.connect(addr2).listingItem(1,parseEther("50"))).to.be.revertedWith("Not an owner")


        await marketPlace.connect(addr1).listingItem(1,parseEther("50"))

        await expect((await marketPlace.getItem(1)).price).to.equal(parseEther("50"))

        await expect((await marketPlace.getItem(1)).status).to.equal(await marketPlace.getStatusListing())
        //console.log(await marketPlace.getItem(1))
        //console.log(await addr1.getAddress())
        await expect(marketPlace.connect(addr1).cancel(2)).to.be.revertedWith("Not listed")
        console.log("1")

        await expect(marketPlace.connect(addr2).cancel(1)).to.be.revertedWith("Not an owner")
        //console.log("1")

        await marketPlace.connect(addr1).cancel(1);

        await expect((await marketPlace.getItem(1)).status).to.equal(await marketPlace.getStatusExist())
        console.log("1")
        await marketPlace.connect(addr1).listingItem(1,parseEther("50"))

        await erc20Token.connect(erc20User).earn(await addr2.getAddress(), parseEther("50"))
        await erc20Token.connect(erc20User).earn(await erc20User.getAddress(), parseEther("50"))

        await erc20Token.connect(addr2).approve(marketPlace.address, parseEther("50"))
        await marketPlace.connect(addr2).buyItem(1, nftToken.address, {value: parseEther("50")})

        expect(await marketPlace.connect(addr1).getOwner(1)).to.equal(await addr2.getAddress())
        await expect(marketPlace.connect(addr1).startAuction(1, {value : parseEther("10")})).to.be.revertedWith("Not an owner")

        await marketPlace.connect(addr2).startAuction(1, {value : parseEther("10")})
        expect(await marketPlace.connect(addr2).getStatus(1)).to.equal(await marketPlace.getStatusAuction())
        await expect(marketPlace.connect(addr1).makeBid(1,{value : parseEther("1")})).to.be.revertedWith("Bid is lower than price")
        await marketPlace.connect(addr1).makeBid(1, {value:parseEther("12")})
        await expect(marketPlace.connect(addr2).cancelAuction(10)).to.be.revertedWith("Not listed on auction")
        await expect(marketPlace.connect(addr1).cancelAuction(1)).to.be.revertedWith("Not an owner")
        await marketPlace.connect(addr2).cancelAuction(1)
        expect (await marketPlace.connect(addr1).getStatus(1)).to.equal(await marketPlace.getStatusExist())


        await marketPlace.connect(addr2).startAuction(1, {value : parseEther("10")})
        await marketPlace.connect(erc20User).makeBid(1, {value:parseEther("12")})
        await expect(marketPlace.connect(addr1).finishAuction(1)).to.be.revertedWith("Auction is not finished")
        await ethers.provider.send('evm_increaseTime', [7 * 24 * 60 * 60]);
        await expect(marketPlace.connect(addr2).makeBid(1,{value : parseEther("25")})).to.be.revertedWith("Auction is finished")

        await expect(marketPlace.connect(addr1).cancelAuction(1)).to.be.revertedWith("Auction is finished")


        //await erc20Token.connect(erc20User).earn(await addr1.getAddress(), parseEther("100"))
        //await erc20Token.connect(erc20User).earn(await addr2.getAddress(), parseEther("100"))

        await erc20Token.connect(erc20User).approve(await addr2.getAddress(), parseEther("15"))
        console.log(await erc20Token.allowance(await erc20User.getAddress(), await addr2.getAddress()))
        //await erc20Token.transferFrom(await addr1.getAddress(), await addr2.getAddress(), parseEther("12"))


        //console.log(await erc20Token.connect(addr1).allowance(await addr1.getAddress(), await addr2.getAddress()))
        //console.log(await addr2.getAddress())
        //console.log(await marketPlace.connect(addr1).getOwner(1));

        console.log(await marketPlace.connect(addr1).getOwner(1));
        await marketPlace.connect(addr1).finishAuction(1)
        //expect(marketPlace.connect(addr1).getOwner(1)).to.equal(await addr1.getAddress())






        //await expect(marketPlace.connect(addr2).makeBid(1,{value : parseEther("25")})).to.be.revertedWith("Auction is finished")

        //await expect(marketPlace.connect(addr1).makeBid(10,{value : parseEther("1")})).to.be.revertedWith("Auction is finished")





      });
      
    });

    describe("auction", function () {
      
      it("initiate cancel finish bid", async function () {
        
        
        await erc20Token.connect(erc20User).earn( addr1.getAddress(), parseEther("15"))
        await erc20Token.connect(addr1).approve(erc20User.getAddress(), parseEther("5"))
        console.log(await erc20Token.allowance(addr1.getAddress(), addr2.getAddress()))
        console.log(await erc20Token.balanceOf(addr1.getAddress()))
        await erc20Token.connect(erc20User).transferFrom(addr1.getAddress(), erc20User.getAddress(), parseEther("3"))


      });
    });

  });