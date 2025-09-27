# Postman API Testing Guide (V3)

This guide provides a step-by-step walkthrough for testing the 404PovertyNotFound V3 API using the provided Postman collection.

## Prerequisites

1.  **Postman:** Ensure you have the Postman desktop client installed.
2.  **Running Local Environment:**
    *   A local blockchain node (e.g., Anvil or Hardhat) must be running.
    *   The API server must be running (`npm run dev` in the `api` directory).

## 1. Import the Postman Collection

1.  Open Postman.
2.  Click **File > Import...**
3.  Select the `api/postman-collection.json` file from this project.
4.  The collection "404 Poverty Not Found - DeFi Investment API" will appear in your Postman sidebar.

## 2. Configure the Environment

The collection comes with pre-configured variables. You can view and edit them by clicking on the collection name and then the "Variables" tab.

*   `baseUrl`: The base URL for the API. Defaults to `http://localhost:3000`.
*   `userAddress`: A sample user address for testing.
*   `planId`: A sample plan ID.
*   `investmentId`: A sample investment ID.
*   `usdcAddress`, `wethAddress`, `wbtcAddress`: Token addresses that will be populated by the deployment script.

**No changes are needed if you are running the API and blockchain locally with the default settings.**

## 3. Deploy Smart Contracts

Before you can test the API, you must deploy the smart contracts to your local blockchain and configure the API to use them.

1.  **Start a local blockchain node:**

    ```bash
    anvil
    ```

2.  **Deploy the contracts:** In a separate terminal, navigate to the `solidity` directory and run the V3 deployment script:

    ```bash
    cd solidity
    forge script script/DeployV3.s.sol --broadcast --rpc-url local
    ```

3.  **Copy the contract addresses:** The script will output a list of deployed contract addresses.

4.  **Configure the API:**
    *   Create a `.env` file in the `api` directory if it doesn't exist (`cp .env.example .env`).
    *   Paste the contract addresses from the script output into the corresponding `LOCAL_` variables in the `api/.env` file.

5.  **Start the API server:**

    ```bash
    cd api
    npm run dev
    ```

## 4. API Testing Flow (The "Happy Path")

Follow these steps in order to test the core functionality of the V3 API.

### Step 1: Check API Health

*   In the Postman collection, open the `🏥 Health & System` folder.
*   Run the **`Health Check`** request.
*   You should receive a `200 OK` response with `{"status":"UP"}`.

### Step 2: Create an Investment Plan

*   Open the `📋 Investment Plans` folder.
*   Run the **`Create Balanced Plan`** request.
*   This will create a new investment plan on the blockchain.
*   The response will contain the `transactionHash` and the `planId` of the newly created plan.

### Step 3: View Investment Plans

*   Open the `🚀 V3 Engine` folder.
*   Run the **`Get V3 Plans`** request.
*   The response should now include the plan you created in the previous step.

### Step 4: Get an Investment Quote

*   Run the **`Get Investment Quote`** request.
*   This request simulates getting a quote for investing `1000` USDC into the plan with `planId` 1.
*   The response will show you how the investment amount will be allocated across the different tokens in the plan.

### Step 5: Prepare the Investment Transaction

*   Run the **`Prepare Investment`** request.
*   This is a crucial step. The API prepares the blockchain transaction data that a frontend application would use to make the actual investment.
*   The response will include the raw transaction data (`data`), the contract to interact with (`to`), and whether an `approve` transaction is needed first.

### Step 6: Simulate an Investment (Conceptual)

The `Prepare Investment` response is as far as the API's responsibility goes for making an investment. The next step would be for a frontend application to take the transaction data from the previous step and use a library like Ethers.js to prompt the user to sign and send the transaction to the blockchain.

### Step 7: View User's Portfolio

*   Assuming an investment has been made, you can view the user's portfolio.
*   Run the **`Get User Portfolio`** request in the `🚀 V3 Engine` folder.
*   This will show the token balances for the `userAddress`.

By following these steps, you can test the core "happy path" of the V3 API and confirm that the system is working as expected.
