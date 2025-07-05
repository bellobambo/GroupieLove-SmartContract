import { ethers } from "hardhat";

async function main() {
  const Groupie = await ethers.getContractFactory("Groupie");
  const groupie = await Groupie.deploy();

  await groupie.waitForDeployment();

  const address = await groupie.getAddress();
  console.log(`Groupie contract deployed to: ${address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
