#!/usr/bin/env node

const { ethers } = require("ethers");
const { HermesClient } = require("@pythnetwork/hermes-client");

// Configuration for Unichain Sepolia
const CONTRACT_ADDRESS = "0x5c29bc86f34505f20a23CB1501E010c52e6C41Ac";
const PYTH_HERMES_URL = "https://hermes.pyth.network";
const UNICHAIN_SEPOLIA_RPC = "https://sepolia.unichain.org";

// Price Feed IDs
const ETH_USD_FEED_ID =
  "0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace";

// Contract ABI (simplified)
const CONTRACT_ABI = [
  "function getETHPrice(bytes[] calldata priceUpdate) external payable returns (int64)",
  "function getBTCPrice(bytes[] calldata priceUpdate) external payable returns (int64)",
  "function getUpdateFee(bytes[] calldata priceUpdate) external view returns (uint256)",
  "function getCachedPrice(bytes32 priceFeedId) external view returns (tuple(int64 price, uint64 conf, int32 expo, uint publishTime))",
];

async function testUnichainContract() {
  console.log("🦄 Testing Pyth Oracle on Unichain Sepolia...\n");

  // Setup provider and wallet
  const provider = new ethers.JsonRpcProvider(UNICHAIN_SEPOLIA_RPC);
  const privateKey = process.env.PRIVATE_KEY;

  if (!privateKey) {
    console.error("❌ Please set PRIVATE_KEY environment variable");
    process.exit(1);
  }

  const wallet = new ethers.Wallet(privateKey, provider);
  const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, wallet);

  console.log(`📍 Contract Address: ${CONTRACT_ADDRESS}`);
  console.log(`👛 Wallet Address: ${await wallet.getAddress()}`);
  console.log(
    `💰 Wallet Balance: ${ethers.formatEther(
      await provider.getBalance(wallet.address)
    )} ETH`
  );
  console.log(`🌐 Network: Unichain Sepolia (Chain ID: 1301)\n`);

  try {
    // Step 1: Get price update data from Hermes
    console.log("📡 Fetching price updates from Hermes...");
    const hermesClient = new HermesClient(PYTH_HERMES_URL);
    const priceUpdates = await hermesClient.getLatestPriceUpdates([
      ETH_USD_FEED_ID,
    ]);

    // Handle the response format
    const rawUpdateData =
      priceUpdates.binary?.data || priceUpdates.binaryPriceUpdates || [];
    if (!rawUpdateData || rawUpdateData.length === 0) {
      console.error("❌ No price updates received from Hermes");
      return;
    }

    // Convert hex strings to proper format
    const updateData = rawUpdateData.map((data) => {
      if (typeof data === "string" && !data.startsWith("0x")) {
        return "0x" + data;
      }
      return data;
    });

    console.log(`✅ Retrieved ${updateData.length} price updates\n`);

    // Step 2: Check update fee
    console.log("💸 Checking update fee...");
    const updateFee = await contract.getUpdateFee(updateData);
    console.log(`💵 Update fee: ${ethers.formatEther(updateFee)} ETH\n`);

    // Step 3: Get ETH price (this will update and return price)
    console.log("📊 Fetching ETH price on Unichain...");
    const tx = await contract.getETHPrice(updateData, {
      value: updateFee,
    });
    const receipt = await tx.wait();

    console.log(`✅ Transaction successful on Unichain!`);
    console.log(`🔗 Transaction hash: ${receipt.hash}`);
    console.log(`⛽ Gas used: ${receipt.gasUsed.toString()}\n`);

    // Step 4: Read cached price (no gas cost)
    console.log("📋 Reading cached ETH price...");
    const cachedPrice = await contract.getCachedPrice(ETH_USD_FEED_ID);

    // Pyth prices are scaled by 10^expo
    const priceValue =
      Number(cachedPrice.price) * Math.pow(10, Number(cachedPrice.expo));
    const confValue =
      Number(cachedPrice.conf) * Math.pow(10, Number(cachedPrice.expo));

    console.log(`💲 ETH/USD Price: $${priceValue.toFixed(2)}`);
    console.log(
      `📅 Last Updated: ${new Date(
        Number(cachedPrice.publishTime) * 1000
      ).toISOString()}`
    );
    console.log(`🎯 Confidence: ±${confValue.toFixed(2)}`);
    console.log(`🔢 Raw price: ${cachedPrice.price.toString()}`);
    console.log(`🔢 Exponent: ${cachedPrice.expo.toString()}\n`);

    console.log("🎉 Unichain Sepolia test completed successfully!");
    console.log("🦄 Your Pyth Oracle is now live on Unichain!");
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    if (error.data) {
      console.error("Error data:", error.data);
    }
  }
}

// Run the test
testUnichainContract().catch(console.error);
