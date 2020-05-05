// Sender: 0x02
// NFTを発行する（受取人: 0x01）

import NonFungibleToken from 0x01
import ExampleNFT from 0x02

transaction {
    let minter: &ExampleNFT.NFTMinter

    prepare(signer: AuthAccount) {
        self.minter = signer.borrow<&ExampleNFT.NFTMinter>(from: /storage/NFTMinter)!
    }

    execute {
        let recipient = getAccount(0x01)

        let receiver = recipient
            .getCapability(/public/NFTReceiver)!
            .borrow<&{NonFungibleToken.Receiver}>()!

        self.minter.mintNFT(recipient: receiver)

        log("ok")
    }
}