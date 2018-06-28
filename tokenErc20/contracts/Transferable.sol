pragma solidity ^0.4.21;

/**
 * @title   Token trnasfer Contract
 * @dev     This interface contains function for ERC20 token transfer.
 */
contract Transferable {
    function transfer(address _to, uint _amount) external returns (bool success);
}