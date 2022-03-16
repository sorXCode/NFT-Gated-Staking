/* eslint-disable prettier/prettier */
// import { BigNumber, BigNumberish, BytesLike } from 'ethers'
import { Signer} from 'ethers'
import { ethers } from "hardhat";
const hre = require('hardhat');

async function getBalanceOf() {
  const address = "0x75cc431c0b332f6a94a4ae170b2a8399c2871798";
  const randAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266'
  const USDC = await ethers.getContractAt(
    "IERC20",
    // usdc address
    "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174"
  );

// @ts-ignore
    await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [address],
      })

     const signer: Signer = await ethers.getSigner(address);
     await USDC.connect(signer).transfer(randAddress, 20000);
     const bal = await USDC.balanceOf(address);
     const balran = await USDC.balanceOf(randAddress);
     console.log(balran);
     console.log(bal);
    }

getBalanceOf().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

//   const bal = await (await USDC).balanceOf(address);
//   console.log(bal);
// }