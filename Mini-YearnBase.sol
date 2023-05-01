// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

// Loading Mini-Yearn Contract....

interface IEthGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;

    function withdrawETH(address lendingPool, uint256 amount, address to) external;
}


contract MiniYearn {

    address owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if(msg.sender!=owner) revert NotOwnership();
        _;
    }

    /**
      * @ param amount: Amount of ether the user have deposited to Mini-yearn
      * @ param depositsDate: Datetime of the deposit
      * @ mapping UsersDeposit: takes into account the balances of Mini-Yearn´s Users
    */
    
    struct Deposits {
        uint256 amount;
        uint256 depositsDate;
    }

    mapping(address => Deposits) usersDeposit;
 
    error IncorrectAmount();
    error NotOwnership();
    error NotEnoughFunds();

    function deposit() public payable {
        if(msg.value == 0) revert IncorrectAmount();
        if(msg.value < 1 ether) revert NotEnoughFunds();

        Deposits storage deposits = usersDeposit[msg.sender];
        deposits.amount = msg.value;
        deposits.depositsDate = block.timestamp;

        address ethGateway = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;
        address wethPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

        IEthGateway(ethGateway).depositETH{value:msg.value}(ethGateway, msg.sender, 0);

        //To be continued...
    }

    function depositUsingParameter(uint256 amount) public payable {
        if(msg.value == 0) revert IncorrectAmount();
        if(msg.value < 1 ether) revert NotEnoughFunds();

        Deposits storage deposits = usersDeposit[msg.sender];
        deposits.amount = amount;
        deposits.depositsDate = block.timestamp;

        address ethGateway = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
        //address wethPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

        IEthGateway(ethGateway).depositETH{value:msg.value}(ethGateway, msg.sender, 0);

        //To be continued...
    }
