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

// contract address : 0x34a608794e6B2E61e5c68E264eF198D416E26137
