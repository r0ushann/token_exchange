const hre = require("hardhat");
//deployed with ethers@5.4.7

async function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy the Token Contract
  const Token = await hre.ethers.getContractFactory("Token");
  const tokenContract = await Token.deploy(); // Add constructor arguments if necessary
  await tokenContract.deployed();
  console.log("Token deployed to:", tokenContract.address);

  // Deploy the Exchange Contract
  const Exchange = await hre.ethers.getContractFactory("Exchange");
  const exchangeContract = await Exchange.deploy(tokenContract.address); // Add constructor arguments if necessary
  await exchangeContract.deployed();
  console.log("Exchange deployed to:", exchangeContract.address);

  // Wait for 30 seconds to let Etherscan catch up on contract deployments
  await sleep(30 * 1000);

  // Verify the contracts on Etherscan
  await hre.run("verify:verify", {
    address: tokenContract.address,
    constructorArguments: [], // Add constructor arguments if necessary
    contract: "contracts/Token.sol:Token",
  });

  await hre.run("verify:verify", {
    address: exchangeContract.address,
    constructorArguments: [tokenContract.address], // Add constructor arguments if necessary
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

/* code below is unstable with latest ethereum version* /

//  const hre = require("hardhat");

// async function sleep(ms) {
//   return new Promise((resolve) => setTimeout(resolve, ms));
// }

// /* 
// const [deployer] = await ethers.getSigners();
//   console.log("Deploying contracts with the account:", deployer.address);
//   const token = await ethers.deployContract("Token");
//   console.log("Token address:", await token.getAddress());
// */
// async function main() {
//   // Deploy the Token Contract
//   const [deployer] = await ethers.getSigners();
//   const tokenContract = await ethers.deployContract("Token");
//   // await tokenContract.waitForDeployment();
//   console.log("Token deployed to:", await tokenContract.getAddress());

//   // Deploy the Exchange Contract
//   const exchangeContract = await ethers.deployContract("Exchange", [
//     tokenContract.target,
//   ]);
//   // await exchangeContract.waitForDeployment();
//   console.log("Exchange deployed to:", await exchangeContract.getAddress());

//   // Wait for 30 seconds to let Etherscan catch up on contract deployments
//   await sleep(30 * 1000);

//   // Verify the contracts on Etherscan
//   await hre.run("verify:verify", {
//     address: tokenContract.target,
//     constructorArguments: [],
//     contract: "contracts/Token.sol:Token",
//   });

//   await hre.run("verify:verify", {
//     address: exchangeContract.target,
//     constructorArguments: [tokenContract.target],
//   });
// }

// // We recommend this pattern to be able to use async/await everywhere
// // and properly handle errors.
// main().catch((error) => {
//   console.error(error);
//   process.exitCode = 1;
// }); 
