import NonFungibleToken from 0x01
import ExampleNFT from 0x02

pub fun main() {
    let owner = getAccount(0x01)
    let collectionBorrow = owner
        .getCapability(/public/NFTReceiver)!
        .borrow<&{ExampleNFT.CollectionBorrow}>()!

    let id = UInt64(0)
    let nft = collectionBorrow.borrowNFT(id: id)
    log("nft:")
    log(nft)
}