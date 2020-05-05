// Sender: 0x01
// NFTに Memento を記録する

import NonFungibleToken from 0x01
import ExampleNFT from 0x02

transaction {
    let token: @ExampleNFT.NFT
    let receiverRef: &{NonFungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        let collectionRef = signer.borrow<&ExampleNFT.Collection>(from: /storage/NFTCollection)!

        collectionRef.addMemento(id: 0, text: "great2!")

        self.token <- collectionRef.withdraw(withdrawID: 0)
        self.receiverRef = signer.getCapability(/public/NFTReceiver)!.borrow<&{NonFungibleToken.Receiver}>()!
    }

    execute {
        log("token:")
        log(self.token.id)
        log(self.token.metadata)
        // self.receiverRef.deposit(token: <-self.token)

        let recipient = getAccount(0x01)
        let receiverRef = recipient
            .getCapability(/public/NFTReceiver)!
            .borrow<&{NonFungibleToken.Receiver}>()!
        receiverRef.deposit(token: <-self.token)

        log("ok")
    }
}
