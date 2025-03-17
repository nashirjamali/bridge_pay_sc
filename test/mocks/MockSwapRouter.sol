// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v3-periphery/interfaces/ISwapRouter.sol";

contract MockSwapRouter is ISwapRouter {
    uint256 public amountInReturned;

    function setAmountIn(uint256 _amountIn) external {
        amountInReturned = _amountIn;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata
    ) external payable override returns (uint256) {
        return 0;
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

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external pure {
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