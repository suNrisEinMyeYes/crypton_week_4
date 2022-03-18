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
  let hardhatToken : Contract;
  let nftToken : Contract;

  let owner : Signer;
  let addr1 : Signer;
  let addr2 : Signer;

  let nftOwner : Signer;

  let user : Signer;


  beforeEach(async function () {
      


    erc20 = await ethers.getContractFactory("Test"); 
    [user] = await ethers.getSigners();     
    erc20Token = await erc20.deploy();

    nft = await ethers.getContractFactory("GameItem"); 
      [nftOwner] = await ethers.getSigners();     
      nftToken = await nft.deploy();

      Token = await ethers.getContractFactory("MarketPlace");
      [owner, addr1, addr2] = await ethers.getSigners();
      
      hardhatToken = await Token.deploy(erc20Token.address, nftToken.address);

      


      
    });

    describe("create", function () {
      
      it("upload some tokens", async function () {
       
        
        await nftToken.connect(nftOwner).awardItem(addr1.getAddress());
        console.log("1")
        //await hardhatToken.connect(owner).awardItem(addr1.getAddress())
        await nftToken.connect(addr1).approve(hardhatToken.address,1)
        console.log("1")

        await expect( hardhatToken.connect(addr1).createItem(nftToken.address,1,parseEther("0"))).to.be.revertedWith("Price should be >0");
        console.log("1")
        await expect( hardhatToken.connect(addr2).createItem(nftToken.address,1,parseEther("50"))).to.be.revertedWith("Not an owner");
        console.log("1")

        await hardhatToken.connect(addr1).createItem(nftToken.address, 1, parseEther("50"));
        console.log("1")

        await expect(await nftToken.ownerOf(1)).to.equal(hardhatToken.address);
        


      });
      it("mint some tokens", async function () {
        /*
          impement my inerface
        */

        


      });
    });

    describe("listing", function () {
      
      it("list, cancel, buy", async function () {

        

        await nftToken.connect(nftOwner).awardItem(addr1.getAddress());
        //await hardhatToken.connect(owner).awardItem(addr1.getAddress())
        await nftToken.connect(addr1).approve(hardhatToken.address,1)

        await hardhatToken.connect(addr1).createItem(nftToken.address, 1, parseEther("50"));

        await expect(hardhatToken.connect(addr1).listingItem(1,parseEther("0"))).to.be.revertedWith("Price should be >0")

        await expect(hardhatToken.connect(addr2).listingItem(1,parseEther("50"))).to.be.revertedWith("Not an owner")


        await hardhatToken.connect(addr1).listingItem(1,parseEther("50"))

        await expect((await hardhatToken.getItem(1)).price).to.equal(parseEther("50"))

        await expect((await hardhatToken.getItem(1)).status).to.equal(await hardhatToken.getStatusListing())
        //console.log(await hardhatToken.getItem(1))
        //console.log(await addr1.getAddress())
        await expect(hardhatToken.connect(addr1).cancel(2)).to.be.revertedWith("Not listed")
        console.log("1")

        await expect(hardhatToken.connect(addr2).cancel(1)).to.be.revertedWith("Not an owner")
        //console.log("1")

        await hardhatToken.connect(addr1).cancel(1);

        await expect((await hardhatToken.getItem(1)).status).to.equal(await hardhatToken.getStatusExist())
        console.log("1")
        await hardhatToken.connect(addr1).listingItem(1,parseEther("50"))

        await erc20Token.earn(await user.getAddress(), parseEther("50"))
        await erc20Token.connect(user).transfer(await addr1.getAddress(), parseEther("50"))

        console.log(await erc20Token.balanceOf(await addr1.getAddress()));

        /*
          to buy check need to implement my interface
        */




      });
      
    });

    describe("auction", function () {
      
      it("initiate cancel finish bid", async function () {
        
        

        await hardhatToken.connect(owner).awardItem(addr1.getAddress())
        expect(await hardhatToken.ownerOf(1)).to.equal((await addr1.getAddress()).toString());


      });
    });

  });