import { expect } from "chai";
import { ethers } from "hardhat";

describe("BoredApeToken", function () {
  const deployerAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
  const tokenAddr = "0x4bf010f1b9beDA5450a8dD702ED602A104ff65EE";

  it("Deployer should have token balance", async function () {
    const BAP = await ethers.getContractAt("BoredApeToken", tokenAddr);

    expect(await BAP.balanceOf(deployerAddr)).to.equal(
      ethers.utils.parseEther("1")
    );

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
