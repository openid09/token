pragma solidity 0.4.23;

/**
 * @title   Lockable Token
 * @dev     This contract contains token transfer unlock function for each account.
 */
contract LockableToken {

    function lock(address _account) public returns (bool);
    function unlock(address _account) public returns (bool);
    function isLock(address _account) public view returns (bool);

    event Locked(address indexed _account);
    event UnLocked(address indexed _account);
}