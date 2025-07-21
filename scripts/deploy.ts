import { ethers } from "hardhat";

async function main() {
  const FanMintCollectibles = await ethers.getContractFactory(
    "FanMintCollectibles"
  );
  const fanMintCollectibles = await FanMintCollectibles.deploy();

  await fanMintCollectibles.waitForDeployment();

  const address = await fanMintCollectibles.getAddress();
  console.log(`FanMintCollectibles contract deployed to: ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// FanMintCollectibles contract deployed to: 0x4d23c144e36E9fe0443D2aC25E4Ebe0Ff80dD8Cd
