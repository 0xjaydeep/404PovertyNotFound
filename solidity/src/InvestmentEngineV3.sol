// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IPlanManager.sol";
import "./interfaces/IUniswapV3Router.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title InvestmentEngineV3Simple
 * @dev DEX-Integrated Investment Engine with Pyth oracle for live prices.
 */
contract InvestmentEngineV3Simple {
    using SafeERC20 for IERC20;

    address public owner;
    address public planManager;
    IUniswapV3Router public router;
    IPyth public pyth;
    address public baseToken; // USDC
    uint24 public fee = 3000; // 0.3%
    uint256 public slippage = 500; // 5%

    mapping(address => bytes32) public priceFeedIds;
    bytes32 internal baseTokenPriceFeedId = 0xc1da76235f64b635b813a174fd33c86363732834a2ead6079d7cda42f6e76692; // PYUSD / USD

    uint256 private _investmentCounter;
    mapping(uint256 => Investment) public investments;

    struct Investment {
        address user;
        uint256 planId;
        uint256 amount;
        uint256 timestamp;
    }

    event InvestmentExecuted(
        uint256 indexed investmentId,
        address indexed user,
        uint256 indexed planId,
        uint256 amount
    );

    event TokenSwapped(
        address indexed user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _planManager, address _router, address _baseToken, address _pyth) {
        owner = msg.sender;
        planManager = _planManager;
        router = IUniswapV3Router(_router);
        baseToken = _baseToken;
        pyth = IPyth(_pyth);
    }

    function depositAndInvest(
        uint256 amount,
        uint256 planId
    ) external returns (uint256 investmentId) {
        require(amount > 0, "Amount must be > 0");

        IPlanManager.InvestmentPlan memory plan = IPlanManager(planManager)
            .getPlan(planId);
        require(plan.isActive, "Plan not active");

        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), amount);

        _investmentCounter++;
        investmentId = _investmentCounter;
        investments[investmentId] = Investment({
            user: msg.sender,
            planId: planId,
            amount: amount,
            timestamp: block.timestamp
        });

        for (uint256 i = 0; i < plan.allocations.length; i++) {
            IPlanManager.AssetAllocation memory allocation = plan.allocations[
                i
            ];
            uint256 allocationAmount = (amount * allocation.targetPercentage) /
                10000;

            if (allocationAmount > 0) {
                if (allocation.tokenAddress == baseToken) {
                    IERC20(baseToken).safeTransfer(
                        msg.sender,
                        allocationAmount
                    );
                } else {
                    _swapToken(allocation.tokenAddress, allocationAmount);
                }
            }
        }

        emit InvestmentExecuted(investmentId, msg.sender, planId, amount);
        return investmentId;
    }

    function _swapToken(address tokenOut, uint256 amountIn) internal {
        int256 priceTokenIn = getPythPrice(baseTokenPriceFeedId);
        int256 priceTokenOut = getPythPrice(priceFeedIds[tokenOut]);

        uint256 expectedAmountOut = (amountIn * uint256(priceTokenIn)) /
            uint256(priceTokenOut);
        uint256 minAmountOut = (expectedAmountOut * (10000 - slippage)) / 10000;

        IERC20(baseToken).approve(address(router), amountIn);

        IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router
            .ExactInputSingleParams({
                tokenIn: baseToken,
                tokenOut: tokenOut,
                fee: fee,
                recipient: msg.sender,
                deadline: block.timestamp + 300,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        try router.exactInputSingle(params) returns (uint256 amountOut) {
            emit TokenSwapped(
                msg.sender,
                baseToken,
                tokenOut,
                amountIn,
                amountOut
            );
        } catch {
            IERC20(baseToken).safeTransfer(msg.sender, amountIn);
        }
    }

    function getPythPrice(bytes32 priceId) public view returns (int256) {
        PythStructs.Price memory price = pyth.getPrice(priceId);
        require(price.price > 0, "Invalid price");
        return price.price;
    }

    function getInvestment(
        uint256 investmentId
    ) external view returns (Investment memory) {
        return investments[investmentId];
    }

    function getTotalInvestments() external view returns (uint256) {
        return _investmentCounter;
    }

    function setPlanManager(address _planManager) external onlyOwner {
        planManager = _planManager;
    }

    function setRouter(address _router) external onlyOwner {
        router = IUniswapV3Router(_router);
    }

    function setInitialPriceFeeds(address[] memory tokens, bytes32[] memory ids) external onlyOwner {
        require(tokens.length == ids.length, "Mismatched arrays");
        for (uint i = 0; i < tokens.length; i++) {
            priceFeedIds[tokens[i]] = ids[i];
        }
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 2000, "Max 20%");
        slippage = _slippage;
    }

    function setPriceFeedId(address token, bytes32 priceId) external onlyOwner {
        priceFeedIds[token] = priceId;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
}
