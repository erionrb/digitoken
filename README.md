# Digitoken

Digitoken is an advanced Smart Contract implementation that enables the tokenization of real-world assets on the blockchain. By integrating the ERC-1410, ERC-20, and ERC-1643 standards, it offers a comprehensive and secure solution for representing assets as fungible tokens with added functionalities. Developed using the Hardhat framework, Digitoken ensures thorough testing and reliability, making it a versatile and trusted choice for various tokenization scenarios. Whether it's real estate, commodities, or other tangible assets, Digitoken provides a seamless and efficient way to tokenize and manage assets on the blockchain, unlocking new possibilities for decentralized finance and asset management.

## Patterns & Stack used in the project
### ERC-1410

ERC-1410 is utilized to enable partial ownership and fractional transfers of assets. It complies with the requirement of reprePsenting real-world assets as fractions, allowing users to own and transact with smaller units of the asset.

### ERC-20

ERC-20 is employed as the standard for the main token implementation. This satisfies the requirement for a fungible token, ensuring compatibility with existing decentralized exchanges and wallets, providing easy liquidity for token holders.

### ERC-1643

ERC-1643 is used to manage external certificates and documents associated with the tokens. This aligns with the requirement for document management and provides verifiable proof of ownership for real-world assets represented by the tokens.

### Hardhat

Hardhat is chosen as the development environment to fulfill the requirement for a robust testing and debugging framework. It ensures that the smart contracts are thoroughly tested and reliable before deployment, enhancing security and overall project quality.

## How to test
Open a terminal a terminal and execute the following commands bellow __in the root of the of the project:__

If you did not installed dependencies yet, run it:
```
$ yarn
```
Execute test comand to run unit tests
```
$ yarn test
```
## Deployment
This project is deployed on Polygon Mumbai Testnet with the following information bellow:
 - Address **0x06CFF3F6048F65832275e0fC8Edd147b5af8C085**
 - [Polygon Scan](https://mumbai.polygonscan.com/address/0x06CFF3F6048F65832275e0fC8Edd147b5af8C085)
 - [Code verification](https://mumbai.polygonscan.com/address/0x06CFF3F6048F65832275e0fC8Edd147b5af8C085#code)
