# Solidity-Calldata-Cache
In rollups such as Optimism or Arbitrum, the cost of a byte of calldata is bigger than a byte of storage. In cases in which the smart contract needs to perform an operation using
inputs of the function, It's a good idea to store the results so next time the operation is repeated the result is stored in the contract.

## Using foundry
```bash
$ curl -L https://foundry.paradigm.xyz | bash
$ foundryup

```
