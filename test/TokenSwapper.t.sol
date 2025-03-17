// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenSwapper.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockSwapRouter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenSwapperTest is Test {
    TokenSwapper public swapper;
    MockSwapRouter public mockRouter;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    address public user = address(1);

    function setUp() public {
        // Deploy mock tokens
        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");

        // Deploy mock router
        mockRouter = new MockSwapRouter();

        // Deploy the contract under test
        swapper = new TokenSwapper(ISwapRouter(address(mockRouter)));

        // Give tokens to the test user
        tokenA.transfer(user, 1000 * 10 ** 18);
        tokenB.transfer(user, 1000 * 10 ** 18);
    }

    function testSwapExactOutputSingle() public {
        uint256 amountOut = 100 * 10 ** 18;
        uint256 amountInMaximum = 200 * 10 ** 18;
        uint256 actualAmountIn = 150 * 10 ** 18;

        mockRouter.setAmountIn(actualAmountIn);

        vm.startPrank(user);
        tokenA.approve(address(swapper), amountInMaximum);

        uint256 userTokenABefore = tokenA.balanceOf(user);

        uint256 amountIn = swapper.swapExactOutputSingle(
            address(tokenA),
            address(tokenB),
            amountOut,
            amountInMaximum
        );

        assertEq(
            amountIn,
            actualAmountIn,
            "Returned amountIn should match the expected value"
        );

        assertEq(
            tokenA.balanceOf(user),
            userTokenABefore - actualAmountIn,
            "User's Token A balance should be reduced by the actual amount in"
        );

        vm.stopPrank();
    }

    function testSwapExactOutputSingleWithRefund() public {
        uint256 amountOut = 100 * 10 ** 18;
        uint256 amountInMaximum = 200 * 10 ** 18;
        uint256 actualAmountIn = 150 * 10 ** 18;

        mockRouter.setAmountIn(actualAmountIn);

        vm.startPrank(user);
        tokenA.approve(address(swapper), amountInMaximum);

        uint256 userTokenABefore = tokenA.balanceOf(user);

        swapper.swapExactOutputSingle(
            address(tokenA),
            address(tokenB),
            amountOut,
            amountInMaximum
        );

        assertEq(
            tokenA.balanceOf(user),
            userTokenABefore - actualAmountIn,
            "User should be refunded the difference between maxAmountIn and actualAmountIn"
        );

        vm.stopPrank();
    }

    function testExpectRevertIfInsufficientApproval() public {
        uint256 amountOut = 100 * 10 ** 18;
        uint256 amountInMaximum = 200 * 10 ** 18;

        vm.startPrank(user);
        tokenA.approve(address(swapper), amountInMaximum - 1);

        vm.expectRevert();
        swapper.swapExactOutputSingle(
            address(tokenA),
            address(tokenB),
            amountOut,
            amountInMaximum
        );

        vm.stopPrank();
    }

    function testExpectRevertIfInsufficientBalance() public {
        uint256 amountOut = 100 * 10 ** 18;
        uint256 amountInMaximum = 2000 * 10 ** 18;

        vm.startPrank(user);
        tokenA.approve(address(swapper), amountInMaximum);

        vm.expectRevert();
        swapper.swapExactOutputSingle(
            address(tokenA),
            address(tokenB),
            amountOut,
            amountInMaximum
        );

        vm.stopPrank();
    }
}
