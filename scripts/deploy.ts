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

// contract address : 0xa9265e612543985ed1691dEED9A1117FF518aC80
