#!/bin/bash

echo "🚀 Setting up 404 Poverty Not Found API Demo"
echo "============================================"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Check if contracts are deployed
echo "🔍 Checking for deployed contracts..."

if [ ! -f "../solidity/broadcast/HackathonDemo.s.sol/31337/run-latest.json" ]; then
    echo "⚠️  Contracts not found. Deploying..."
    cd ../solidity
    forge script script/HackathonDemo.s.sol --broadcast --rpc-url local
    cd ../api
fi

# Extract contract addresses from deployment
echo "📋 Extracting contract addresses..."

# Create .env from template
cp .env.example .env

# Note: In a real setup, you'd parse the JSON and update .env automatically
# For hackathon demo, we'll show manual steps

echo ""
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Update .env file with your contract addresses from the deployment"
echo "2. Add your admin private key to .env"
echo "3. Run: npm run dev"
echo "4. Test: curl http://localhost:3000/api/health"
echo ""
echo "Contract addresses can be found in:"
echo "../solidity/broadcast/HackathonDemo.s.sol/31337/run-latest.json"