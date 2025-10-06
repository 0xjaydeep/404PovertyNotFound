#!/usr/bin/env node

const { ethers } = require("ethers");
const { HermesClient } = require("@pythnetwork/hermes-client");

//       console.log(`💲 Fresh AAPL/USD Price: $${freshPriceValue.toFixed(2)}`);onfiguration for Unichain Sepolia
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

    // Step 4: Read both cached and fresh price
    console.log("📋 Reading cached AAPL price (unsafe)...");
    const cachedPrice = await contract.getCachedPrice(AAPL_USD_FEED_ID);

    // Pyth prices are scaled by 10^expo
    const cachedPriceValue =
      Number(cachedPrice.price) * Math.pow(10, Number(cachedPrice.expo));
    const cachedConfValue =
      Number(cachedPrice.conf) * Math.pow(10, Number(cachedPrice.expo));

    console.log(`💲 Cached AAPL/USD Price: $${cachedPriceValue.toFixed(2)}`);
    console.log(
      `📅 Cached Last Updated: ${new Date(
        Number(cachedPrice.publishTime) * 1000
      ).toISOString()}`
    );
    console.log(`🎯 Cached Confidence: ±${cachedConfValue.toFixed(2)}`);

    // Now try to get fresh price (will work only if recent)
    console.log("\n� Attempting to read fresh price (max 60 seconds old)...");
    try {
      // This calls the Pyth contract directly for fresh price
      const pythContract = new ethers.Contract(
        "0x2880aB155794e7179c9eE2e38200202908C17B43", // Pyth contract address on Unichain Sepolia
        [
          "function getPriceNoOlderThan(bytes32 id, uint age) view returns (tuple(int64 price, uint64 conf, int32 expo, uint publishTime))",
        ],
        provider
      );

      const freshPrice = await pythContract.getPriceNoOlderThan(
        AAPL_USD_FEED_ID,
        60
      );
      const freshPriceValue =
        Number(freshPrice.price) * Math.pow(10, Number(freshPrice.expo));
      const freshConfValue =
        Number(freshPrice.conf) * Math.pow(10, Number(freshPrice.expo));

      console.log(`� Fresh ETH/USD Price: $${freshPriceValue.toFixed(2)}`);
      console.log(
        `📅 Fresh Last Updated: ${new Date(
          Number(freshPrice.publishTime) * 1000
        ).toISOString()}`
      );
      console.log(`🎯 Fresh Confidence: ±${freshConfValue.toFixed(2)}`);
    } catch (error) {
      console.log(`⚠️  Fresh price not available: ${error.message}`);
      console.log(
        `ℹ️  This means the last price update was more than 60 seconds ago`
      );
    }

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
