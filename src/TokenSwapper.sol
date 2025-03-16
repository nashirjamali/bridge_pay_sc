// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract TokenSwapper {
    IUniswapV2Router02 public immutable uniswapRouter;
    
    constructor(address _uniswapRouterAddress) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
    }
    
    /**
     * @notice Swap exact tokens for another token
     * @param _tokenIn Address of token to swap from
     * @param _tokenOut Address of token to swap to
     * @param _amountIn Amount of tokens to swap
     * @param _amountOutMin Minimum amount of tokens to receive
     * @param _to Address to send the swapped tokens to
     * @return Amount of tokens received
     */
    function swapExactTokensForTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) external returns (uint256) {
        // Transfer tokens to this contract
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);
        
        // Approve router to spend tokens
        IERC20(_tokenIn).approve(address(uniswapRouter), _amountIn);
        
        // Create path for the swap
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        // Execute the swap
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp + 15 minutes
        );
        
        // Return the amount of tokens received
        return amounts[1];
    }
    
    /**
     * @notice Swap tokens for exact amount of output tokens
     * @param _tokenIn Address of token to swap from
     * @param _tokenOut Address of token to swap to
     * @param _amountOut Exact amount of tokens to receive
     * @param _amountInMax Maximum amount of tokens to spend
     * @param _to Address to send the swapped tokens to
     * @return Amount of input tokens spent
     */
    function swapTokensForExactTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut,
        uint256 _amountInMax,
        address _to
    ) external returns (uint256) {
        // Transfer tokens to this contract
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountInMax);
        
        // Approve router to spend tokens
        IERC20(_tokenIn).approve(address(uniswapRouter), _amountInMax);
        
        // Create path for the swap
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        
        // Execute the swap
        uint[] memory amounts = uniswapRouter.swapTokensForExactTokens(
            _amountOut,
            _amountInMax,
            path,
            _to,
            block.timestamp + 15 minutes
        );
        
        // Refund unused tokens to sender
        uint256 refundAmount = _amountInMax - amounts[0];
        if (refundAmount > 0) {
            IERC20(_tokenIn).transfer(msg.sender, refundAmount);
        }
        
        // Return the amount of input tokens spent
        return amounts[0];
    }
}