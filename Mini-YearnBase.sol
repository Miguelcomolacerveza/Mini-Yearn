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
        if(msg.sender!=owner) revert NoOwnership();
        _;
    }

    /**
      * @ param amount: Amount of the deposit the user have done to Mini-tearn
      * @ param depositsDate: Datetime of the deposit
      * @ mapping UsersDeposit: takes into account the balances of Mini-Yearn´s Users
    */
    
    struct Deposits {
        uint256 amount;
        uint256 depositsDate;
    }

    mapping(address => Deposits) usersDeposit;
 
    error IncorrectAmount();
    error NoOwnership();
    error NotEnoughFunds();
    
    event DepositDone();

    function deposit() public payable {
        if(msg.value == 0) revert IncorrectAmount();
        if(msg.value < 10 ether) revert NotEnoughFunds();

        Deposits storage deposits = usersDeposit[msg.sender];
        deposits.amount = msg.value;
        deposits.depositsDate = block.timestamp;

        address ethGateway = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;

        IEthGateway(ethGateway).depositETH{value:msg.value}(ethGateway, msg.sender, 0);

        emit DepositDone();

        //To be continued...
    }

}
