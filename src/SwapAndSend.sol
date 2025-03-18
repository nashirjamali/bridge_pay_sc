// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v3-periphery/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapAndSend is ReentrancyGuard, Ownable {
    ISwapRouter public immutable swapRouter;

    uint24 public constant poolFee = 3000;

    event Transfer(
        address indexed sender,
        address sourceToken,
        uint256 sourceAmount
    );

    event Swap(
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount
    );

    event Delivery(
        address indexed recipient,
        address destinationToken,
        uint256 destinationAmount
    );

    event CompletedBridgeTransfer(
        address indexed sender,
        address indexed recipient,
        address sourceToken,
        address destinationToken,
        uint256 sourceAmount,
        uint256 destinationAmount,
        uint256 fee
    );

    constructor(ISwapRouter _swapRouter) Ownable(msg.sender) {
        swapRouter = _swapRouter;
    }

    /**
     * @dev Fungsi internal untuk swap token ke token
     */
    function _swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum,
        address _recipient,
        uint256 _deadline
    ) internal returns (uint256) {
        // Approve router untuk menggunakan token
        TransferHelper.safeApprove(_tokenIn, address(swapRouter), _amountIn);

        // Parameter untuk swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: _recipient,
                deadline: _deadline,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // Eksekusi swap
        return swapRouter.exactInputSingle(params);
    }

    /**
     * @dev Fungsi utama untuk bridge transfer: token -> token
     * alur: (1) transfer token ke smart contract, (2) swap, (3) kirim hasil ke penerima
     */
    function bridgeTransfer(
        address _recipient,
        address _sourceToken,
        address _destinationToken,
        uint256 _sourceAmount,
        uint256 _minDestinationAmount,
        uint256 _deadline
    ) external nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        require(_sourceAmount > 0, "Amount must be greater than 0");

        // 1. Transfer token dari pengirim ke smart contract
        TransferHelper.safeTransferFrom(
            _sourceToken,
            msg.sender,
            address(this),
            _sourceAmount
        );

        emit Transfer(msg.sender, _sourceToken, _sourceAmount);

        // Hitung fee platform
        uint256 fee = (_sourceAmount * 2) / 10000;
        uint256 amountToSwap = _sourceAmount - fee;

        // 2. Swap token menggunakan Uniswap V3
        uint256 destinationAmount = _swapTokens(
            _sourceToken,
            _destinationToken,
            _sourceAmount,
            _minDestinationAmount,
            address(this), // Hasil swap dikirim dulu ke smart contract
            _deadline
        );
        emit Swap(
            _sourceToken,
            _destinationToken,
            amountToSwap,
            destinationAmount
        );

        // 3. Kirim token hasil swap ke penerima
        TransferHelper.safeTransfer(
            _destinationToken,
            _recipient,
            destinationAmount
        );

        emit Delivery(_recipient, _destinationToken, destinationAmount);

        // Emit event utama
        emit CompletedBridgeTransfer(
            msg.sender,
            _recipient,
            _sourceToken,
            _destinationToken,
            _sourceAmount,
            destinationAmount,
            fee
        );
    }
}
