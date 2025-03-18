// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SwapAndSend.sol";
import "./mocks/MockERC20Mint.sol";
import "./mocks/MockSwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SwapAndSendTest is Test {
    SwapAndSend public swapAndSend;
    MockSwapRouter public mockRouter;
    MockERC20 public sourceToken;
    MockERC20 public destinationToken;

    address public owner = address(1);
    address public user = address(2);
    address public recipient = address(3);

    uint256 public constant INITIAL_BALANCE = 1000 ether;
    uint256 public constant TRANSFER_AMOUNT = 100 ether;
    uint256 public constant MIN_DESTINATION_AMOUNT = 90 ether;

    uint256 public deadline;

    function setUp() public {
        sourceToken = new MockERC20("Source Token", "SRC", 18);
        destinationToken = new MockERC20("Destination Token", "DST", 18);

        deadline = block.timestamp + 3600;

        mockRouter = new MockSwapRouter();

        vm.prank(owner);
        swapAndSend = new SwapAndSend(ISwapRouter(address(mockRouter)));

        sourceToken.mint(user, INITIAL_BALANCE);

        destinationToken.mint(address(mockRouter), INITIAL_BALANCE);

        mockRouter.setSwapResult(address(destinationToken), TRANSFER_AMOUNT);
    }

    function testBridgeTransfer() public {
        vm.startPrank(user);
        sourceToken.approve(address(swapAndSend), TRANSFER_AMOUNT);
        
        swapAndSend.bridgeTransfer(
            recipient,
            address(sourceToken),
            address(destinationToken),
            TRANSFER_AMOUNT,
            MIN_DESTINATION_AMOUNT,
            deadline
        );
        vm.stopPrank();
        
        assertEq(sourceToken.balanceOf(user), INITIAL_BALANCE - TRANSFER_AMOUNT, "Source token balance should be reduced");
        assertEq(destinationToken.balanceOf(recipient), TRANSFER_AMOUNT, "Recipient should receive destination tokens");
    }

    function test_RevertFailBridgeTransferWithInvalidRecipient() public {
        vm.startPrank(user);
        sourceToken.approve(address(swapAndSend), TRANSFER_AMOUNT);
        
        vm.expectRevert("Invalid recipient address");

        swapAndSend.bridgeTransfer(
            address(0),
            address(sourceToken),
            address(destinationToken),
            TRANSFER_AMOUNT,
            MIN_DESTINATION_AMOUNT,
            deadline
        );

        vm.stopPrank();
    }

    function test_RevertFailBridgeTransferWithZeroAmount() public {
        vm.startPrank(user);
        sourceToken.approve(address(swapAndSend), TRANSFER_AMOUNT);

        vm.expectRevert("Amount must be greater than 0");
        
        swapAndSend.bridgeTransfer(
            recipient,
            address(sourceToken),
            address(destinationToken),
            0,
            MIN_DESTINATION_AMOUNT,
            deadline
        );
        vm.stopPrank();
    }

    function test_RevertFailBridgeTransferWithInsufficientBalance() public {
        uint256 excessiveAmount = INITIAL_BALANCE + 1 ether;
        vm.startPrank(user);
        sourceToken.approve(address(swapAndSend), excessiveAmount);
        
        vm.expectRevert();

        swapAndSend.bridgeTransfer(
            recipient,
            address(sourceToken),
            address(destinationToken),
            excessiveAmount,
            MIN_DESTINATION_AMOUNT,
            deadline
        );
        vm.stopPrank();
    }
}
