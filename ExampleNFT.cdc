import NonFungibleToken from 0x01

pub contract ExampleNFT: NonFungibleToken {
    pub var totalSupply: UInt64
    pub var mementoIdCount: UInt64 // Memento の ID カウント

    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    // 所有者のみが追加できる特別な付加情報
    pub resource interface Memento {
        pub let id: UInt64
        pub let sender: Address
    }

    // メッセージ
    pub resource Message: Memento {
        pub let id: UInt64
        pub let sender: Address
        pub let text: String

        init(initID: UInt64, sender: Address, text: String) {
            self.id = initID
            self.sender = sender
            self.text = text
        }
    }

    // 落書き
    pub resource Graffiti: Memento {
        pub let id: UInt64
        pub let sender: Address
        pub let svg: String

        init(initID: UInt64, sender: Address, svg: String) {
            self.id = initID
            self.sender = sender
            self.svg = svg
        }
    }

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub var metadata: {String: String}
        pub var mementos: @{UInt64: AnyResource{Memento}} // 所有者のみが追加できる特別な付加情報

        init(initID: UInt64) {
            self.id = initID
            self.metadata = {}
            self.mementos <- {}
        }

        destroy() {
            destroy self.mementos
        }
    }

    pub resource interface CollectionBorrow {
        pub fun borrowNFT(id: UInt64): &NFT
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver {
        pub var ownedNFTs: @{UInt64: NFT}

        init () {
            self.ownedNFTs <- {}
        }

        pub fun withdraw(withdrawID: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <-token
        }

        pub fun batchWithdraw(ids: [UInt64]): @Collection {
            let batchCollection <- create Collection()
            for id in ids {
                let nft <- self.withdraw(withdrawID: id)
                batchCollection.deposit(token: <-nft)
            }
            return <-batchCollection
        }

        pub fun deposit(token: @NFT) {
            let id: UInt64 = token.id
            let oldToken <- self.ownedNFTs[id] <- token
            emit Deposit(id: id, to: self.owner?.address)
            destroy oldToken
        }

        pub fun batchDeposit(tokens: @Collection) {
            for id in tokens.getIDs() {
                let nft <- tokens.withdraw(withdrawID: id)
                self.deposit(token: <-nft)
            }
            destroy tokens
        }

        // NFTに付加情報を追加する
        pub fun addMemento(id: UInt64, text: String) {
            let token <- self.ownedNFTs.remove(key: id) ?? panic("missing NFT")

            let mementoId = ExampleNFT.mementoIdCount
            let message <- create Message(initID: mementoId, sender: self.owner!.address, text: text)
            let oldMemento <- token.mementos[mementoId] <- message
            destroy oldMemento
            ExampleNFT.mementoIdCount = ExampleNFT.mementoIdCount + UInt64(1)

            let oldToken <- self.ownedNFTs[id] <- token
            destroy oldToken
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NFT {
            return &self.ownedNFTs[id] as &NFT
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

	pub resource NFTMinter {
		pub fun mintNFT(recipient: &{NonFungibleToken.Receiver}) {
			var newNFT <- create NFT(initID: ExampleNFT.totalSupply)
			recipient.deposit(token: <-newNFT)
            ExampleNFT.totalSupply = ExampleNFT.totalSupply + UInt64(1)
		}
	}

	init() {
        self.totalSupply = 0
        self.mementoIdCount = 0

        let collection <- create Collection()
        self.account.save(<-collection, to: /storage/NFTCollection)

        self.account.link<&{NonFungibleToken.Receiver, CollectionBorrow}>(
            /public/NFTReceiver,
            target: /storage/NFTCollection
        )

        let minter <- create NFTMinter()
        self.account.save(<-minter, to: /storage/NFTMinter)

        emit ContractInitialized()
	}
}
