pragma solidity ^0.4.21;

/**
 * @title   ERC20 Basic Token contract
 * @dev     ..
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

    function transfer(address _to, uint _tokens) public returns (bool);
    function transferFrom(address _from, address _to, uint _tokens) public returns (bool);

    function allowance(address _owner, address _spender) public view returns (uint);
    function approve(address _spender, uint _tokens) public returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}