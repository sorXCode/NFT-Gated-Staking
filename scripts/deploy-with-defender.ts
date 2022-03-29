// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import {
  DefenderRelaySigner,
  DefenderRelayProvider,
} from "defender-relay-client/lib/ethers";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const credentials = {
    apiKey: process.env.RELAYER_API_KEY || "",
    apiSecret: process.env.RELAYER_API_SECRET || "",
  };
  const provider = new DefenderRelayProvider(credentials);
  const signer = new DefenderRelaySigner(credentials, provider, {
    speed: "fast",
  });
  const initialSupply = ethers.utils.parseEther("1");
  const BoredApeToken = await ethers.getContractFactory(
    "BoredApeToken",
    signer
  );

  const BAP = await BoredApeToken.deploy(initialSupply);

  await BAP.deployed();

  console.log("BoredApeToken deployed to:\t", BAP.address);
  console.log(
    "BoredApeToken totalSupply:\t",
    (await BAP.totalSupply()).toString()
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
