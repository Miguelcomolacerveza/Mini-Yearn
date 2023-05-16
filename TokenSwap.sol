

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;


import "../interfaces/IERC20.sol";
import "../contracts/IERC20.sol";
import "hardhat/console.sol";


contract TokenA is ERC20 {

    constructor(address swapper) ERC20("TOKENA","TA") {
        _mint(swapper, 1_000_000 * 1e18);
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

contract TokenB is ERC20 {

    constructor (address swapper) ERC20("TOKENB","TB") {
        _mint(swapper, 1_000_000 * 1e18);
    }   
    
    function mint(uint256 amount) external{
        _mint(msg.sender, amount);
    }
}

contract Swapper {

    address public owner;
    address public tokenA;
    address public tokenB;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender != owner) revert NotOwnership();
        _;
    }

    event SwapDone(uint256 amount, uint256 amountToReceive);
    
    error NotOwnership();
    error WrongTokens();
    error WrongAmount();
    error InsufficientTokens();
    error InsufficientLiquidity();


    function assignTokenAddresses(address _tokenA, address _tokenB) onlyOwner public {
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function swap(uint256 amount,address tokenToSend, address tokenToReceive)  public {

        if(amount == 0) revert WrongAmount();
        if(tokenToSend != tokenA && tokenToSend != tokenB) revert WrongTokens();
        if(tokenToReceive != tokenA && tokenToReceive != tokenB) revert WrongTokens();
        if(IERC20(tokenToSend).balanceOf(msg.sender) < amount) revert InsufficientTokens();
        
        
        uint256 tokenValue = getTokenPrice(tokenToReceive, tokenToSend);
        uint256 amountToReceive = (amount * tokenValue) / 1e18;

        if(IERC20(tokenToReceive).balanceOf(address(this)) < amountToReceive) revert InsufficientLiquidity();

        // Approving the msg.sender token so the contract can take it
        IERC20(tokenToSend).approve(address(this), amount);
        
        // Sending the token from msg.sender to this contract
        if(IERC20(tokenToReceive).balanceOf(address(this)) < amountToWithdraw) revert InsufficientTokens();
        
        // Validating the pool has sufficient liquidity to achieve the user´s order
        IERC20(tokenToSend).transferFrom(tokenToSend, address(this), amount);
       
       // Transfering tokens to msg.sender
        IERC20(tokenToReceive).transfer(tokenToReceive, amountToReceive);

        emit SwapDone(amount, amountToReceive);
    }

    function getTokenPrice(address tokenToReceive, address tokenToSend) public view returns(uint256) {
        return (IERC20(tokenToReceive).balanceOf(address(this)) 
                / 
                IERC20(tokenToSend).balanceOf(address(this))) * 1e18;   
    }
}
