// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  const initialSupply = ethers.utils.parseEther("1");
  const BoredApeToken = await ethers.getContractFactory("BoredApeToken");

  const BAP = await BoredApeToken.deploy(initialSupply);

  await BAP.deployed();

  console.log("BoredApeToken deployed to:\t", BAP.address);
  console.log(
    "BoredApeToken totalSupply:\t",
    (await BAP.totalSupply()).toString()
  );
  console.log(
    "Balance of ",
    deployer.address,
    "=>  ",
    (await BAP.balanceOf(deployer.address)).toString()
  );

  // Deploy GatedStaker
  const gateTokenName = "BOREDAPES NFT";
  const gateTokenAddr = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d";
  const stakedTokenAddr = BAP.address;

  const GatedStaker = await ethers.getContractFactory("GatedStaker");
  const gatedStaker = await GatedStaker.deploy(
    gateTokenName,
    gateTokenAddr,
    stakedTokenAddr
  );

  await gatedStaker.deployed();

  console.log("GatedStaker deployed to:\t", gatedStaker.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// BoredApeToken deployed to:       0x4bf010f1b9beDA5450a8dD702ED602A104ff65EE
// BoredApeToken totalSupply:       1000000000000000000
// Balance of  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 =>   1000000000000000000
// GatedStaker deployed to:         0x40a42Baf86Fc821f972Ad2aC878729063CeEF403
