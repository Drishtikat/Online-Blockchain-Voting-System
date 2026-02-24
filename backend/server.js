const express = require("express");
const multer = require("multer");
const fs = require("fs");
const crypto = require("crypto");
const cors = require("cors");
const path = require("path");
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

/* ---------------- VOTER BIOMETRIC -------------- */
const upload = multer({ dest: 'temp_uploads/' });

function getFileHash(filePath) {
    const fileBuffer = fs.readFileSync(filePath);
    return crypto.createHash('sha256').update(fileBuffer).digest('hex');
}

app.post('/verify-fingerprint', upload.single('fingerprint'), (req, res) => {
    console.log("POST /verify-fingerprint HIT");
    try {
        const voterId = req.body.voterId;  
        const uploadedFilePath = req.file.path;

        // Path to stored fingerprint
        const storedFilePath = path.join(
            __dirname,
            '..',
            'dataset',
            'real_data',
            `${voterId}.bmp`
        );

        if (!fs.existsSync(storedFilePath)) {
            fs.unlinkSync(uploadedFilePath);
            return res.json({ verified: false, message: "Voter not found" });
        }

        const uploadedHash = getFileHash(uploadedFilePath);
        const storedHash   = getFileHash(storedFilePath);

        fs.unlinkSync(uploadedFilePath);

        if (uploadedHash === storedHash) {
            return res.json({ verified: true });
        } else {
            return res.json({ verified: false, message: "Fingerprint mismatch" });
        }

    } catch (err) {
        console.log("FINGERPRINT ERROR:", err);
        return res.status(500).json({ verified: false, message: "Server error" });
    }
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
    const receipt = await tx.wait();

    const event = receipt.logs
    .map(log => voting.interface.parseLog(log))
    .find(e => e && e.name === "Voted");

    return res.status(200).json({
      success: true,
      message: "Vote recorded successfully",
      txHash: tx.hash,
      voterHash: event.args.voterHash,
      candidateId: mappedCandidate
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
      const hashes = await voting.getCandidateVoters(i);

      result[String(i)] = { 
        name: data[0], 
        voteCount: Number(data[1]),
        voterHashes: hashes.map(h => h) 
      };
    }

    res.setHeader("Content-Type", "application/json");
    res.json(result);

  } catch (err) {
    console.log("RESULT ERROR:", err);
    res.status(500).json({ success: false, message: "Unable to fetch results" });
  }
});

/* ---------------- FETCH VOTER HASHES FOR EACH CANDIDATE ---------------- */
app.get("/getCandidateVoters/:id", async (req, res) => {
  try {
    const candidateId = parseInt(req.params.id);

    const hashes = await voting.getCandidateVoters(candidateId);

    // Convert bytes32[] to hex strings
    const formatted = hashes.map(h => h);

    res.json({
      success: true,
      candidateId,
      voterHashes: formatted
    });

  } catch (err) {
    console.log("HASH FETCH ERROR:", err);
    res.status(500).json({ success: false, message: "Unable to fetch voter hashes" });
  }
});

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
