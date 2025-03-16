// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import "../src/TokenSwapper.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract TokenSwapperTest is Test {
    TokenSwapper public swapper;
    
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    address public constant WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC; // Binance hot wallet
    
    uint256 public constant INITIAL_AMOUNT = 10 ether; // 10 WETH for testing
    
    function setUp() public {
        // Fork mainnet
        vm.createSelectFork("mainnet");
        
        // Deploy TokenSwapper
        swapper = new TokenSwapper(UNISWAP_ROUTER);
        
        // Use whale account to get tokens
        vm.startPrank(WHALE);
        
        // Get some WETH
        IWETH(WETH).deposit{value: INITIAL_AMOUNT}();
        
        // End impersonation
        vm.stopPrank();
    }
    
    function testSwapExactTokensForTokens() public {
        // Amount to swap
        uint256 amountIn = 1 ether; // 1 WETH
        
        // Starting balances
        vm.startPrank(WHALE);
        
        // Transfer WETH to this contract
        IERC20(WETH).transfer(address(this), amountIn);
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(WHALE);
        
        // Approve swapper to use our WETH
        IERC20(WETH).approve(address(swapper), amountIn);
        
        // Execute swap
        uint256 minAmountOut = 1; // Just a minimal check for test
        uint256 amountOut = swapper.swapExactTokensForTokens(
            WETH,
            DAI,
            amountIn,
            minAmountOut,
            WHALE
        );
        
        // Check results
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(WHALE);
        vm.stopPrank();
        
        // Assertions
        assertEq(IERC20(WETH).balanceOf(address(this)), wethBalance - amountIn, "WETH balance didn't decrease correctly");
        assertGt(daiBalanceAfter, daiBalanceBefore, "DAI balance didn't increase");
        assertEq(daiBalanceAfter - daiBalanceBefore, amountOut, "Received amount doesn't match return value");
    }
    
    function testSwapTokensForExactTokens() public {
        // Amount to receive
        uint256 daiAmount = 1000 * 1e18; // 1000 DAI
        uint256 amountInMax = 1 ether; // Max 1 WETH
        
        vm.startPrank(WHALE);
        
        // Transfer WETH to this contract
        IERC20(WETH).transfer(address(this), amountInMax);
        uint256 wethBalanceBefore = IERC20(WETH).balanceOf(address(this));
        uint256 daiBalanceBefore = IERC20(DAI).balanceOf(WHALE);
        
        // Approve swapper to use our WETH
        IERC20(WETH).approve(address(swapper), amountInMax);
        
        // Execute swap
        uint256 amountSpent = swapper.swapTokensForExactTokens(
            WETH,
            DAI,
            daiAmount,
            amountInMax,
            WHALE
        );
        
        // Check results
        uint256 daiBalanceAfter = IERC20(DAI).balanceOf(WHALE);
        uint256 wethBalanceAfter = IERC20(WETH).balanceOf(address(this));
        vm.stopPrank();
        
        // Assertions
        assertLt(amountSpent, amountInMax, "Used maximum amount, which is unlikely in normal market conditions");
        assertEq(wethBalanceBefore - wethBalanceAfter, amountSpent, "WETH used doesn't match reported amount");
        assertEq(daiBalanceAfter - daiBalanceBefore, daiAmount, "Didn't receive exact DAI amount requested");
    }
    
    // Receive function to allow contract to receive ETH
    receive() external payable {}
}