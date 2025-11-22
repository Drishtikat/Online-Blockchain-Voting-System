async function main() {
  const candidateNames = ["BJP", "INC", "AAP", "OTH", "BSP"];

  const Voting = await ethers.getContractFactory("Voting");
  const voting = await Voting.deploy(candidateNames);
  await voting.waitForDeployment();

  console.log("Voting Contract deployed at:", voting.target);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
