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

// FanMintCollectibles contract deployed to: 0xA8e2D0949d6A3457CE4bf128aC754Fc9fcc0970E
