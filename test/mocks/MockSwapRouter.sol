// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/interfaces/ISwapRouter.sol";

contract MockSwapRouter is ISwapRouter {
    uint256 public amountInReturned;
    mapping(address => uint256) public swapResults;
    uint256 public conversionRate = 1;
    
    address public tokenIn;
    address public tokenOut;
    uint256 public amountIn;
    uint256 public amountOut;

    function setConversionRate(uint256 _rate) external {
        conversionRate = _rate;
    }

    function setAmountIn(uint256 _amountIn) external {
        amountInReturned = _amountIn;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable override returns (uint256) {
        // Store the token and amount data for tests
        tokenIn = params.tokenIn;
        tokenOut = params.tokenOut;
        amountIn = params.amountIn;
        
        // Get the configured swap result for the tokenOut
        uint256 resultAmount = swapResults[params.tokenOut];
        
        // If no swap result is configured, use the conversion rate
        if (resultAmount == 0) {
            resultAmount = params.amountIn * conversionRate;
        }
        
        // Check if the amount out is less than the minimum required
        if (resultAmount < params.amountOutMinimum) {
            revert("Too little received");
        }
        
        // Transfer the tokens to the recipient
        if (resultAmount > 0) {
            // Simulate the token transfer by transferring from this mock to the recipient
            // In real scenario, this would be handled by the pool contract
            IERC20(params.tokenOut).transfer(params.recipient, resultAmount);
        }
        
        // Store the amount out for tests
        amountOut = resultAmount;
        
        return resultAmount;
    }

    function exactInput(
        ExactInputParams calldata
    ) external payable override returns (uint256) {
        return 0;
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata /* params */
    ) external payable override returns (uint256) {
        // Transfer the 'amountOut' of tokenOut to the recipient
        // Return the pre-set amountIn
        return amountInReturned;
    }

    function exactOutput(
        ExactOutputParams calldata
    ) external payable override returns (uint256) {
        return 0;
    }

    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            require(success);
            results[i] = result;
        }
        return results;
    }

    function multicall(
        uint256 deadline,
        bytes[] calldata data
    ) external payable returns (bytes[] memory) {
        require(deadline >= block.timestamp, "Transaction too old");
        return this.multicall(data);
    }

    function setSwapResult(address /* tokenOut */, uint256 /* amountOut */) external {
        swapResults[tokenOut] = amountOut;
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external pure override {
        // Not implemented for testing
    }

    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // Not implemented for testing
    }

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // Not implemented for testing
    }

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // Not implemented for testing
    }

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        // Not implemented for testing
    }
}