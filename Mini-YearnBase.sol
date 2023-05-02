// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

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

    function setDeposit() public payable {
        if(msg.value == 0) revert IncorrectAmount();
        if(msg.value < 1 ether) revert NotEnoughFunds();

        Deposits storage deposits = usersDeposit[msg.sender];
        deposits.amount = msg.value;
        deposits.depositsDate = block.timestamp;

        address ethGateway = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;
        address wethPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;


        //0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8 V3 aWeth Token Contract

        IEthGateway(ethGateway).depositETH{value:msg.value}(wethPool, address(this), 0);

        //To be continued...
    }

    function getBalance(address _user) public view returns(uint) {
        return usersDeposit[_user].amount;
    }


    function checkAwethBalance(IERC20 _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
}
