const hre = require("hardhat");

async function main() {
  const deployedContract = await hre.ethers.deployContract("Counter");
  await deployedContract.waitForDeployment();
  console.log(`Contract deployed to ${deployedContract.target}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
