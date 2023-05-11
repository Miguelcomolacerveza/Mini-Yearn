// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/*
    Benefits of using Mini-Yearn Token
        - Open position with this token
        - Don´t waste time re-programming this contract, just use the token
        
    Useful info (Aave v3):
        - address ethGateway = 0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;
        - address wethPool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        - address aWeth = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;

*/

import "../interfaces/IERC20.sol";
import "hardhat/console.sol";


abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// Loading Mini-Yearn Contract....

interface IEthGateway {
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;

    function withdrawETH(address lendingPool, uint256 amount, address to) external;
}


contract MiniYearn is ERC20 {

    address owner;

    event success(uint256 amountToWithdraw);

    constructor() ERC20("MINI-YEARN", "MY", 18) {
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
        deposits.amount += msg.value;
        deposits.depositsDate = block.timestamp;


        IEthGateway(0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C)
        .depositETH{value:msg.value}
            (0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2, // Pool's Address
            address(this),                               // This Address will receive aWeth
            0                                            // Referral = none
        );

        //Sending Mini-yearn tokens to the user
        _mint(msg.sender, msg.value); // We create Mini-yearn token and send them to the sender.

    }

    function withdraw(uint amount) external payable {
        // balancesOf is a mapping on the ERC20 Contract

        if(amount > balanceOf[msg.sender]) revert IncorrectAmount();
        
        uint256 amountToWithdraw = (getMiniYearnPrice() * amount) / 1e18;

        // approve wETH Token, giving permission to wETH Gateway.

        IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).approve(
            0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C, // wETH Gateway Address
            amountToWithdraw                            // Amount of wETH to withdraw 
        );

        // Our contract withdraw the aWeth to Weth and send them back to the user(sender).
    
        IEthGateway(0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C)
        .withdrawETH(
            0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2, // wETH Pool´s adress
            amountToWithdraw,                           // Amount of wETH to withdraw
            msg.sender                                  // This address will receive the wETH
        );
        _burn(msg.sender, amount); // We burn Mini-yearn token and delete them from the user (sender).
    }

    function getBalance(address _user) public view returns(uint) {
        return usersDeposit[_user].amount;
    }

    /* In order to see the aWeth balances, we need two addresses
          1.-The aWeth´s address
          2.-The address that we want to see the balance, in this case the address of this contract. 
    */
    function getAwethBalance(IERC20 _token) public view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    // To get the price of Mini-Yearn the amount of Mini-Yearn divided by the total supply.
    // We must use 1e18 to take into account all the decimals otherwise the value returned would be smaller.
    // Total suplply comes from ERC20 Contract
    
    function getPrice() public view returns(uint256) {
        return IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).balanceOf(address(this)) * 1e18 / totalSupply;
    }

    // getAtokenBalance -> gets the total amount of aWeth balance in this contract

    function getAtokenBalance() public view returns(uint) {
        return IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8).balanceOf(address(this));
    }

     // getMiniYearnPrice() -> calculates the value of each Mini-Yearn    
    function getMiniYearnPrice() public view returns(uint) {
        uint256 miniYearnPrice = (getAtokenBalance() * 1e18) / totalSupply;
        return miniYearnPrice;
    }
}
