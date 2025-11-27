const express = require("express");
const cors = require("cors");
const { ethers } = require("ethers");
require("dotenv").config();

const mapping = require("./mapping.json");

const app = express();
app.use(cors());
app.use(express.json());

/* ---------------- CONNECT TO BLOCKCHAIN ---------------- */
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const VotingABI = require("../hardhat/artifacts/contracts/Voting.sol/Voting.json").abi;
const contractAddress = process.env.CONTRACT_ADDRESS;

const voting = new ethers.Contract(contractAddress, VotingABI, wallet);

/* ---------------- HEALTHCHECK ---------------- */
app.get("/healthcheck", (req, res) => {
  res.json({ status: "OK", blockchain: true });
});

/* ---------------- PUF VERIFICATION ---------------- */
app.post("/verifyPUF", (req, res) => {
  const { deviceId } = req.body;

  if (deviceId === "BU001") {
    return res.json({ verified: true });
  }
  return res.json({ verified: false });
});

/* ---------------- RECORD VOTE ---------------- */
app.post("/recordVote", async (req, res) => {
  try {
    const { voterId, candidateId } = req.body;

    if (!voterId || !candidateId) {
      return res.status(400).json({ success: false, message: "Invalid payload" });
    }

    const numericVoterId = parseInt(voterId.replace(/\D/g, ""));
    const mappedCandidate = mapping[candidateId];

    if (!mappedCandidate) {
      return res.status(400).json({ success: false, message: "Unknown candidate" });
    }

    console.log("Recording vote:", numericVoterId, mappedCandidate);

    const tx = await voting.recordVote(numericVoterId, mappedCandidate);
    await tx.wait();

    return res.status(200).json({
      success: true,
      message: "Vote recorded successfully",
      txHash: tx.hash
    });

  } catch (err) {
    console.log("BLOCKCHAIN ERROR:", err);
    return res.status(500).json({
      success: false,
      error: err.reason || err.message
    });
  }
});

/* ---------------- FETCH RESULTS ---------------- */
app.get("/getResults", async (req, res) => {
  try {
    let result = {};
    for (let i = 1; i <= 5; i++) {
      const data = await voting.getCandidate(i);
      result[String(i)] = { 
        name: data[0], 
        voteCount: Number(data[1]) 
      };
    }

    res.setHeader("Content-Type", "application/json");
    res.json(result);

  } catch (err) {
    console.log("RESULT ERROR:", err);
    res.status(500).json({ success: false, message: "Unable to fetch results" });
  }
});