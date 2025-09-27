// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// PyUSD Interface
interface IPYUSD is IERC20 {
    function decimals() external view returns (uint8);
}

// DEX Interface for ETH/PyUSD swaps (e.g., Uniswap V3)
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) 
        external payable returns (uint256 amountOut);
}

// WETH Interface
interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 wad) external;
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
}

// Price Oracle Interface (for better price feeds)
interface IPriceOracle {
    function getPrice(address token) external view returns (uint256);
}

/**
 * @title PyUSDManager
 * @dev Handles all PyUSD-related functionality in a modular way
 */
contract PyUSDManager is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IPYUSD;
    
    // State variables
    IPYUSD public pyusdToken;
    ISwapRouter public swapRouter;
    IWETH9 public wethToken;
    IPriceOracle public priceOracle;
    
    // Configuration
    uint24 public constant POOL_FEE = 3000; // 0.3% fee tier
    uint256 public slippageTolerance = 300; // 3% slippage tolerance (basis points)
    uint256 public maxSlippageTolerance = 1000; // 10% max slippage
    bool public isActive = false;
    
    // Authorized callers (InvestmentEngine contracts)
    mapping(address => bool) public authorizedCallers;
    
    // Tracking
    mapping(address => uint256) public userPyUSDAllocations;
    mapping(uint256 => uint256) public investmentPyUSDAmounts; // investmentId => pyusdAmount
    mapping(address => mapping(uint256 => uint256)) public userInvestmentPyUSD; // user => investmentId => amount
    
    // Events
    event PyUSDPurchased(
        address indexed user,
        uint256 indexed investmentId,
        uint256 ethAmount,
        uint256 pyusdAmount,
        address indexed caller
    );
    
    event PyUSDTransferred(
        address indexed user,
        uint256 indexed investmentId,
        uint256 amount,
        address destination,
        address indexed caller
    );
    
    event SlippageToleranceUpdated(uint256 oldTolerance, uint256 newTolerance);
    event AuthorizedCallerUpdated(address caller, bool authorized);
    event PyUSDManagerActivated(bool active);
    
    // Modifiers
    modifier onlyAuthorized() {
        require(authorizedCallers[msg.sender], "PyUSDManager: Not authorized caller");
        _;
    }
    
    modifier onlyActive() {
        require(isActive, "PyUSDManager: Not active");
        _;
    }
    
    constructor() Ownable(msg.sender) {
        // Contract starts inactive until properly initialized
    }
    
    /**
     * @dev Initialize PyUSD functionality
     * @param _pyusdToken PyUSD token contract address
     * @param _swapRouter DEX router for swaps
     * @param _wethToken WETH token contract address
     */
    function initialize(
        address _pyusdToken,
        address _swapRouter,
        address _wethToken
    ) external onlyOwner {
        require(!isActive, "PyUSDManager: Already initialized");
        require(_pyusdToken != address(0), "PyUSDManager: Invalid PyUSD address");
        require(_swapRouter != address(0), "PyUSDManager: Invalid swap router");
        require(_wethToken != address(0), "PyUSDManager: Invalid WETH address");
        
        pyusdToken = IPYUSD(_pyusdToken);
        swapRouter = ISwapRouter(_swapRouter);
        wethToken = IWETH9(_wethToken);
        
        isActive = true;
        emit PyUSDManagerActivated(true);
    }
    
    /**
     * @dev Main function called by InvestmentEngine to handle PyUSD conversion
     * @param user The user making the investment
     * @param investmentId The investment ID
     * @param ethAmount Amount of ETH to convert to PyUSD
     * @param destination Destination address for PyUSD (address(0) to keep in this contract)
     * @return pyusdReceived Amount of PyUSD received from conversion
     */
    function convertETHToPyUSD(
        address user,
        uint256 investmentId,
        uint256 ethAmount,
        address destination
    ) external payable onlyAuthorized onlyActive returns (uint256 pyusdReceived) {
        require(user != address(0), "PyUSDManager: Invalid user");
        require(ethAmount > 0, "PyUSDManager: Invalid ETH amount");
        require(msg.value >= ethAmount, "PyUSDManager: Insufficient ETH sent");
        
        // Convert ETH to PyUSD
        pyusdReceived = _swapETHForPyUSD(ethAmount);
        
        // Handle destination
        if (destination != address(0)) {
            pyusdToken.safeTransfer(destination, pyusdReceived);
            emit PyUSDTransferred(user, investmentId, pyusdReceived, destination, msg.sender);
        }
        
        // Update tracking
        userPyUSDAllocations[user] += pyusdReceived;
        investmentPyUSDAmounts[investmentId] += pyusdReceived;
        userInvestmentPyUSD[user][investmentId] += pyusdReceived;
        
        emit PyUSDPurchased(user, investmentId, ethAmount, pyusdReceived, msg.sender);
        
        // Return excess ETH if any
        if (msg.value > ethAmount) {
            payable(msg.sender).transfer(msg.value - ethAmount);
        }
        
        return pyusdReceived;
    }
    
    /**
     * @dev Internal function to swap ETH for PyUSD
     * @param ethAmount Amount of ETH to swap
     * @return pyusdReceived Amount of PyUSD received
     */
    function _swapETHForPyUSD(uint256 ethAmount) internal returns (uint256 pyusdReceived) {
        // Wrap ETH to WETH
        wethToken.deposit{value: ethAmount}();
        
        // Approve swap router
        wethToken.approve(address(swapRouter), ethAmount);
        
        // Calculate minimum output with slippage protection
        uint256 expectedPyUSD = getExpectedPyUSDAmount(ethAmount);
        uint256 minPyUSDOut = (expectedPyUSD * (10000 - slippageTolerance)) / 10000;
        
        // Execute swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: address(wethToken),
            tokenOut: address(pyusdToken),
            fee: POOL_FEE,
            recipient: address(this),
            deadline: block.timestamp + 300, // 5 minutes deadline
            amountIn: ethAmount,
            amountOutMinimum: minPyUSDOut,
            sqrtPriceLimitX96: 0
        });
        
        pyusdReceived = swapRouter.exactInputSingle(params);
        
        return pyusdReceived;
    }
    
    /**
     * @dev Get expected PyUSD amount for given ETH amount
     * @param ethAmount Amount of ETH
     * @return expectedPyUSD Expected PyUSD amount
     */
    function getExpectedPyUSDAmount(uint256 ethAmount) public view returns (uint256 expectedPyUSD) {
        if (address(priceOracle) != address(0)) {
            // Use price oracle if available
            uint256 ethPriceInUSD = priceOracle.getPrice(address(wethToken));
            expectedPyUSD = (ethAmount * ethPriceInUSD) / 1e12; // Adjust for decimals (ETH=18, PyUSD=6)
        } else {
            // Fallback to simplified calculation
            // 1 ETH ≈ 2000 USD, 1 PyUSD ≈ 1 USD
            uint256 ethPriceInUSD = 2000;
            expectedPyUSD = (ethAmount * ethPriceInUSD) / 1e12;
        }
        
        return expectedPyUSD;
    }
    
    /**
     * @dev Transfer PyUSD from this contract to destination
     * @param user The user (for tracking)
     * @param investmentId Investment ID (for tracking)
     * @param amount Amount to transfer
     * @param destination Destination address
     */
    function transferPyUSD(
        address user,
        uint256 investmentId,
        uint256 amount,
        address destination
    ) external onlyAuthorized onlyActive {
        require(destination != address(0), "PyUSDManager: Invalid destination");
        require(amount > 0, "PyUSDManager: Invalid amount");
        require(pyusdToken.balanceOf(address(this)) >= amount, "PyUSDManager: Insufficient balance");
        
        pyusdToken.safeTransfer(destination, amount);
        emit PyUSDTransferred(user, investmentId, amount, destination, msg.sender);
    }
    
    /**
     * @dev Get quote for ETH to PyUSD conversion (view function)
     * @param ethAmount Amount of ETH to convert
     * @return expectedPyUSD Expected PyUSD amount
     * @return minPyUSDOut Minimum PyUSD with slippage protection
     */
    function getConversionQuote(uint256 ethAmount) 
        external 
        view 
        returns (uint256 expectedPyUSD, uint256 minPyUSDOut) 
    {
        expectedPyUSD = getExpectedPyUSDAmount(ethAmount);
        minPyUSDOut = (expectedPyUSD * (10000 - slippageTolerance)) / 10000;
        return (expectedPyUSD, minPyUSDOut);
    }
    
    // View Functions
    function getPyUSDBalance() external view returns (uint256) {
        return pyusdToken.balanceOf(address(this));
    }
    
    function getUserPyUSDAllocation(address user) external view returns (uint256) {
        return userPyUSDAllocations[user];
    }
    
    function getInvestmentPyUSDAmount(uint256 investmentId) external view returns (uint256) {
        return investmentPyUSDAmounts[investmentId];
    }
    
    function getUserInvestmentPyUSD(address user, uint256 investmentId) external view returns (uint256) {
        return userInvestmentPyUSD[user][investmentId];
    }
    
    function isInitialized() external view returns (bool) {
        return isActive;
    }
    
    // Administrative Functions
    function setAuthorizedCaller(address caller, bool authorized) external onlyOwner {
        require(caller != address(0), "PyUSDManager: Invalid caller");
        authorizedCallers[caller] = authorized;
        emit AuthorizedCallerUpdated(caller, authorized);
    }
    
    function updateSlippageTolerance(uint256 _slippageTolerance) external onlyOwner {
        require(_slippageTolerance <= maxSlippageTolerance, "PyUSDManager: Slippage too high");
        
        uint256 oldTolerance = slippageTolerance;
        slippageTolerance = _slippageTolerance;
        
        emit SlippageToleranceUpdated(oldTolerance, _slippageTolerance);
    }
    
    function updateMaxSlippageTolerance(uint256 _maxSlippageTolerance) external onlyOwner {
        require(_maxSlippageTolerance <= 2000, "PyUSDManager: Max slippage too high"); // Max 20%
        maxSlippageTolerance = _maxSlippageTolerance;
    }
    
    function updateSwapRouter(address _swapRouter) external onlyOwner {
        require(_swapRouter != address(0), "PyUSDManager: Invalid swap router");
        swapRouter = ISwapRouter(_swapRouter);
    }
    
    function setPriceOracle(address _priceOracle) external onlyOwner {
        priceOracle = IPriceOracle(_priceOracle);
    }
    
    function setActive(bool _active) external onlyOwner {
        isActive = _active;
        emit PyUSDManagerActivated(_active);
    }
    
    // Emergency Functions
    function emergencyWithdrawPyUSD(uint256 amount) external onlyOwner {
        require(amount <= pyusdToken.balanceOf(address(this)), "PyUSDManager: Insufficient balance");
        pyusdToken.safeTransfer(owner(), amount);
    }
    
    function emergencyWithdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "PyUSDManager: Insufficient ETH balance");
        payable(owner()).transfer(amount);
    }
    
    function emergencyWithdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "PyUSDManager: Invalid token");
        IERC20(token).safeTransfer(owner(), amount);
    }
    
    // Pause functionality
    function pause() external onlyOwner {
        isActive = false;
        emit PyUSDManagerActivated(false);
    }
    
    function unpause() external onlyOwner {
        require(address(pyusdToken) != address(0), "PyUSDManager: Not initialized");
        isActive = true;
        emit PyUSDManagerActivated(true);
    }
    
    // Receive ETH for swaps
    receive() external payable {
        // Allow contract to receive ETH
    }
    
    fallback() external payable {
        revert("PyUSDManager: Function not found");
    }
}