import chai, { expect } from 'chai';
import asPromised from 'chai-as-promised';
import { ethers } from 'hardhat';
import { Signer } from 'ethers';
import { NftMarket, Nft } from '../typechain'

chai.use(asPromised);

const ONE_ETH = ethers.utils.parseEther('1')

describe('NFTMarket', () => {
  let deployer: Signer
  let seller: Signer
  let buyer: Signer
  let nftMarket: NftMarket
  let nft: Nft

  beforeEach(async () => {
    const signers  = await ethers.getSigners()
    deployer = signers[0]
    seller = signers[1]
    buyer = signers[2]

    const NFTMarketFactory = await ethers.getContractFactory('NFTMarket')
    nftMarket = (await NFTMarketFactory.deploy()) as NftMarket
    await nftMarket.deployed()

    const NFTFactory = await ethers.getContractFactory('NFT')
    nft = (await NFTFactory.deploy()) as Nft
    await nft.deployed()

    await nft.mint(await seller.getAddress(), 1)
    await nft.connect(seller).approve(nftMarket.address, 1)
  })

  describe('#list', () => {
    it('should take an NFT into escrow', async () => {
      await nftMarket.connect(seller).list(nft.address, 1, ONE_ETH)

      const owner = await nft.ownerOf(1)
      expect(owner).to.eq(nftMarket.address)
    })
  })

  describe('#purchase', () => {
    beforeEach(async () => {
      await nftMarket.connect(seller).list(nft.address, 1, ONE_ETH)
    })

    it('should transfer ownership of the NFT to the buyer', async () => {
      await nftMarket.connect(buyer).purchase(nft.address, 1, {value: ONE_ETH})
      const owner = await nft.ownerOf(1)

      expect(owner).to.eq(await buyer.getAddress())
    })

    it('should transfer the purchase amount to the seller', async () => {
      const beforeBalance = await seller.getBalance()
      await nftMarket.connect(buyer).purchase(nft.address, 1, {value: ONE_ETH})
      const afterBalance = await seller.getBalance()

      expect(afterBalance.toString()).to.eq(beforeBalance.add(ONE_ETH).toString())
    })
  })

  describe('#getFloorPrice',  () => {
    beforeEach(async () => {
      await nft.mint(await seller.getAddress(), 2)
      await nft.mint(await seller.getAddress(), 3)
      await nft.mint(await seller.getAddress(), 4)
      await nft.connect(seller).approve(nftMarket.address, 2)
      await nft.connect(seller).approve(nftMarket.address, 3)
      await nft.connect(seller).approve(nftMarket.address, 4)
      await nftMarket.connect(seller).list(nft.address, 1, ONE_ETH)
      await nftMarket.connect(seller).list(nft.address, 2, ONE_ETH.div(4))
      await nftMarket.connect(seller).list(nft.address, 3, ONE_ETH.div(3))
      await nftMarket.connect(seller).list(nft.address, 4, ONE_ETH.div(2))
    })

    it('should return the floor price', async () => {
      const floor = await nftMarket.getFloorPrice(nft.address)
      expect(floor.toString()).to.eq(ONE_ETH.div(4).toString())
    })

    it('should keep track of the floor price if the floor has changed', async () => {
      await nftMarket.connect(buyer).purchase(nft.address, 2, {value: ONE_ETH.div(4)})

      const floor = await nftMarket.getFloorPrice(nft.address)

      expect(floor.toString()).to.eq(ONE_ETH.div(3).toString())
    })
  })

  describe('#buyFloor', () => {
    beforeEach(async () => {
      await nft.mint(await seller.getAddress(), 2)
      await nft.mint(await seller.getAddress(), 3)
      await nft.mint(await seller.getAddress(), 4)
      await nft.connect(seller).approve(nftMarket.address, 2)
      await nft.connect(seller).approve(nftMarket.address, 3)
      await nft.connect(seller).approve(nftMarket.address, 4)
      await nftMarket.connect(seller).list(nft.address, 1, ONE_ETH)
      await nftMarket.connect(seller).list(nft.address, 2, ONE_ETH.div(4))
      await nftMarket.connect(seller).list(nft.address, 3, ONE_ETH.div(3))
      await nftMarket.connect(seller).list(nft.address, 4, ONE_ETH.div(2))
    })

    it('should purchase the floor NFT', async () => {
      await nftMarket.connect(buyer).buyFloor(nft.address)
      await nftMarket.connect(buyer).buyFloor(nft.address)

      expect(await nft.ownerOf(2)).to.eq(await buyer.getAddress())
      expect(await nft.ownerOf(3)).to.eq(await buyer.getAddress())
    })
  })
})