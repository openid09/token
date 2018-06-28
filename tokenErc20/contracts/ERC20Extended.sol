pragma solidity ^0.4.21;

/**
 * @title   ERC20 Extended
 * @dev     This contract contains extended function for MyToken.
 */
contract ERC20Extended {

    function distribute(address _to, uint _amount) public returns (bool success);

    function mint(address _to, uint _amount) public returns (bool success);
    function burn(address _owner, uint _amount) public returns (bool success);

    function suspend(bool _suspended) external;

    event Mint(address indexed _to, uint _amount);
    event Burn(address indexed _owner, uint _amount);
    event Suspend(bool _suspended);
}