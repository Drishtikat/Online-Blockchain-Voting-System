# 🗳️ Decentralized Blockchain-Based Electronic Voting System

---

## 📘 Overview
This project is a **prototype implementation of a Blockchain-Based Electronic Voting System** enhanced with:

- **Biometric verification** for voter authentication  
- **PUF (Physically Unclonable Function)** for hardware-level security  
- **Blockchain smart contracts** for immutable vote recording  

It demonstrates how India’s existing **EVM–VVPAT system** can be extended into a **transparent, decentralized, and verifiable architecture**.

The system combines:

- Blockchain for immutability and transparency  
- Biometrics for voter authentication  
- PUF technology for hardware attestation  
- A user-friendly MATLAB GUI for secure voting  

---

## 🎯 Objectives

- Ensure end-to-end transparency in the voting process  
- Eliminate single points of failure and insider tampering  
- Guarantee **one-person-one-vote** using biometric authentication  
- Enable auditability through blockchain and VVPAT slips  
- Provide a realistic prototype aligned with India’s electoral ecosystem  

---

## 🧠 Prototype Workflow

### 🔹 1. System Initialization
- Power ON and establish secure BU–CU connection  
- CU performs **PUF challenge–response verification**  
  - Valid → Proceed  
  - Invalid → Device flagged as tampered  

### 🔹 2. Voter Authentication
- Fingerprint scanned → hashed and compared against voter database  
  - Verified & not voted → Unlock ballot unit  
  - Invalid / Already voted → Deny access, log attempt  

### 🔹 3. Vote Casting and Confirmation
- Voter selects candidate using on-screen GUI  
- VVPAT generates a **paper slip** showing candidate and unique hash  along with vote timestamp

### 🔹 4. Blockchain Recording
- Vote → anonymized hash (voterID + candidateID)  
- Digitally signed by the CU’s private key  
- Sent to Ethereum smart contract → stored immutably  

### 🔹 5. Result Verification
- Votes tallied directly from blockchain  
- Admin can verify via on-chain data  
- Blockchain results cross-verified with **VVPAT audit slips**  

---

## 🔗 Technology Stack

| Layer               | Technology           | Description                                         |
|--------------------|-------------------|-----------------------------------------------------|
| Smart Contract      | Solidity (Ethereum) | Secure blockchain backend for immutable voting     |
| Frontend            | MATLAB UIFigure     | Interactive GUI for voter and admin panels         |
| Backend             | Node.js + Express   | API server connecting blockchain with frontend     |
| Blockchain Library  | Ethers.js           | Handles blockchain deployment and interactions     |
| Styling             | MATLAB UI Styling   | Responsive GUI layout and improved UX              |
| Local Blockchain    | Hardhat             | Simulated Ethereum network for testing             |

---

## 💻 Installation & Setup

### 1. Clone Repository
Clone repository using repository link

### 2. Install Dependencies
```npm install```

### 3. Deploy Smart Contract
```npx hardhat run scripts/deploy.js --network localhost```

### 4. Start Backend Server
```node server.js```

### 5. Run MATLAB Voting Simulator
``` HardwareSimulator```
