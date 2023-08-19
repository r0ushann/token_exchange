//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;

    /*
    This constructor takes the contract address of the token and saves it. 
    The exchange will then further behave as an exchange for ETH <> Token.
    */
    constructor(address token) ERC20("ETH TOKEN LP token", "lpETHTOKEN") {
        require(token != address(0), "Token address passed is a null address");
        tokenAddress = token;
    }

    // function to view the balance of the token for the exchange contract
    function getReserve() public view returns (uint256) {
        return ERC20(tokenAddress).balanceOf(address(this));
    }

    //function to add liquidity feature with necessary checks and parameters for exchange
    function addLiquidity(
        uint256 amountOfToken
    ) public payable returns (uint256) {
        uint256 lpTokensToMint;
        uint256 ethReserveBalance = address(this).balance;
        uint256 tokenReserveBalance = getReserve();

        ERC20 token = ERC20(tokenAddress);

        // if the reserve balance is zero, then take any user supplied balance for liquidity
        if (tokenReserveBalance == 0) {
            // transfer token from user to exchange contract
            token.transferFrom(msg.sender, address(this), amountOfToken);
            // lpTokensToMint = ethReserveBalance = msg.value
            lpTokensToMint = ethReserveBalance;

            // mint lp tokens to the user
            _mint(msg.sender, lpTokensToMint);
            return lpTokensToMint;
        }

        // if balance is not empty or zero then calculate the amount of lptokens to mint
        uint256 ethReservePriorToFunctionCall = ethReserveBalance - msg.value;
        uint256 mintTokenAmountRequired = (msg.value * tokenReserveBalance) /
            ethReservePriorToFunctionCall;

        require(
            amountOfToken >= mintTokenAmountRequired,
            "Insufficient amount of tokens provided"
        );

        // Transfer token from user to exchange
        token.transferFrom(msg.sender, address(this), mintTokenAmountRequired);

        // Calculate the amount of lptokens to minted
        lpTokensToMint =
            (totalSupply() * msg.value) /
            ethReservePriorToFunctionCall;
        _mint(msg.sender, lpTokensToMint); // mint lp tokens to the user
        return lpTokensToMint;
    }

    // function to remove liquidity
    function removeLiquidity(
        uint256 amountOfLPTokens
    ) public returns (uint256, uint256) {
        // Check that the user wants to remove >0 LP tokens
        require(
            amountOfLPTokens > 0,
            "Amount of tokens to remove must be greater than 0"
        );

        uint256 ethReserveBalance = address(this).balance;
        uint256 lpTokenTotalSupply = totalSupply();

        // Calculate the amount of ETH and tokens to return to the user
        uint256 ethToReturn = (ethReserveBalance * amountOfLPTokens) /
            lpTokenTotalSupply;
        uint256 tokenToReturn = (getReserve() * amountOfLPTokens) /
            lpTokenTotalSupply;

        // Burn the LP tokens from the user, and transfer the ETH and tokens to the user
        _burn(msg.sender, amountOfLPTokens);
        payable(msg.sender).transfer(ethToReturn);
        ERC20(tokenAddress).transfer(msg.sender, tokenToReturn);

        return (ethToReturn, tokenToReturn);
    }

    // getOutputAmountFromSwap calculates the amount of output tokens to be received based on xy = (x + dx)(y - dy)
    function getOutputAmountFromSwap(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(
            inputReserve > 0 && outputReserve > 0,
            "Reserves must be greater than 0"
        );

        uint256 inputAmountWithFee = inputAmount * 99;

        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
    }

    // ethToTokenSwap allows users to swap ETH for tokens
    function ethToTokenSwap(uint256 minTokensToReceive) public payable {
        uint256 tokenReserveBalance = getReserve();
        uint256 tokensToReceive = getOutputAmountFromSwap(
            msg.value,
            address(this).balance - msg.value,
            tokenReserveBalance
        );

        require(
            tokensToReceive >= minTokensToReceive,
            "Tokens received are less than minimum tokens expected"
        );

        ERC20(tokenAddress).transfer(msg.sender, tokensToReceive);
    }

    // tokenToEthSwap allows users to swap tokens for ETH
    function tokenToEthSwap(
        uint256 tokensToSwap,
        uint256 minEthToReceive
    ) public {
        uint256 tokenReserveBalance = getReserve();
        uint256 ethToReceive = getOutputAmountFromSwap(
            tokensToSwap,
            tokenReserveBalance,
            address(this).balance
        );

        require(
            ethToReceive >= minEthToReceive,
            "ETH received is less than minimum ETH expected"
        );

        ERC20(tokenAddress).transferFrom(
            msg.sender,
            address(this),
            tokensToSwap
        );

        payable(msg.sender).transfer(ethToReceive);
    }
}
