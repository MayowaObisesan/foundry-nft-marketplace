TASK:

```create an erc721 marketplace that uses onchain orders coupled with vrs signatures to create and confirm orders

- the marketplace should allow users to create erc721 orders for their erc721 tokens
- the order should have the following info 
    - order creator/token owner(obviously)
    - erc721 token address, tokenID
    - price(we'll be using only ether as currency)
    - active
    - signature(the seller must sign the previous data i.e the hash of the token address,tokenId,price,owner etc
    - deadline, if the token isn't sold before the deadline, it cannot be bought again

- when the order is being created by the buyer, the signature is being verified to be the owner's  address among other checks
- order fulfillment has its own checks too

- you are to write a test for this contract

you do not need to emit events for the contract since you're time constrained(you can decide to add events if you want your test traces to be more colorful)
```

FUNCTIONALITIES

- Have a counter to keep track of the number of orders created
- Create an order to sell an ERC721 token
  - Verify the validity of an order using a signature
- Have a mapping (of uint to the `order` struct) that stores the created orders.
- Fulfill an order by buying an ERC721 token

METHODS

- createOrder:
  - Allows a user to create an order to sell an ERC721 token.
  - The user specifies the token address, token ID, price, signature, and deadline for the order.
  - The function verifies the validity of the order and stores it in the orders mapping.

- fulfillOrder:
  - Allows a user to fulfill an order by buying an ERC721 token.
  - The user specifies the token address and token ID of the order to be fulfilled. - The function verifies the validity of the order, transfers the token from the seller to the buyer, and transfers the payment from the buyer to the seller.

- recoverSigner:
  - Internal function used to recover the signer of a message given a signature.
  - It verifies the length of the signature and uses assembly code to extract the r, s, and v values.
  - It then uses the ecrecover function to recover the signer's address.

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

<https://book.getfoundry.sh/>

## Usage

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Anvil

```shell
anvil
```

### Deploy

```shell
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
cast <subcommand>
```

### Help

```shell
forge --help
anvil --help
cast --help
```
