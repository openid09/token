pragma solidity 0.4.21;

import "./SafeMath.sol";
import "./Transferable.sol";
import "./LockableToken.sol";
import "./ERC20Basic.sol";
import "./ERC20Extended.sol";

contract MyToken is ERC20Basic, ERC20Extended, LockableToken {
    using SafeMath for uint;

    address private tokenOwner;

    bool private suspended;

    uint8 public decimals;
    uint public totalSupply;

    string public name;
    string public symbol;

    mapping(address => uint) private balances;
    mapping(address => bool) private lockedAccount;

    mapping(address => mapping(address => uint)) private allowed;

    event DistributeBatch(address indexed _to, uint amount);
    event LockBatch(address indexed _account);
    event UnlockBatch(address indexed _account);

    modifier onlyTokenOwner() {
        require(tokenOwner == msg.sender);
        _;
    }

    modifier onlyUnlockAccount() {
        require(lockedAccount[msg.sender] != true);
        _;
    }

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _initialSupply
    ) public {
        tokenOwner = msg.sender;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        totalSupply = _initialSupply.mul(10 ** uint(_decimals));
        if (totalSupply == 0) {
            revert();
        }

        balances[tokenOwner] = totalSupply;
        suspended = true;
    }

    function() public payable {
        revert();
    }

    /**
     * @dev Returns amount of total supply token.
     */
    function totalSupply() public view returns (uint) {
        return totalSupply;
    }

    /**
     * @dev Returns the balance that is sum of free and lock token.
     * @param _owner The owner of token.
     */
    function balanceOf(address _owner) public view returns (uint) {
        return balances[_owner];
    }

    /**
     * @dev Transfer the tokens from msg.sender to reciver.
     * @param _to Recipient of token.
     * @param _tokens Tokens amount.
     */
    function transfer(address _to, uint _tokens) public onlyUnlockAccount returns (bool) {
        if (suspended) return false;
        if (_to == address(0x0)) return false;
        if (balances[msg.sender] < _tokens) return false;
        
        balances[msg.sender] = balances[msg.sender].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);
        emit Transfer(msg.sender, _to, _tokens);
        return true;
    }

    /**
     * @dev Transfer the tokens from sender to reciver.
     * @param _from Sender of token.
     * @param _to Recipient of token.
     * @param _tokens Tokens amount.
     */
    function transferFrom(address _from, address _to, uint _tokens) public onlyUnlockAccount returns (bool) {
        if (suspended) return false;
        if (_from == address(0x0) || _to == address(0x0)) return false;
        if (balances[_from] < _tokens) return false;
        if (allowed[_from][msg.sender] < _tokens) return false;
        
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_tokens);
        balances[_from] = balances[_from].sub(_tokens);
        balances[_to] = balances[_to].add(_tokens);

        emit Transfer(_from, _to, _tokens);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner The address which owns the tokens.
     * @param _spender The address which will spend the tokens.
     */
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the tokens.
     * @param _tokens Tokens amount.
     */
    function approve(address _spender, uint _tokens) public returns (bool) {
        if (suspended) return false;

        allowed[msg.sender][_spender] = _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _addedTokens The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedTokens) public returns (bool) {
        if (suspended) return false;

        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedTokens);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedTokens) public returns (bool) {
        if (suspended) return false;

        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedTokens > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedTokens);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Distribute the token as locked from the admin accounts.
     * @param _to Recipient of token.
     * @param _amount Tokens amount.
     */
    function distribute(address _to, uint _amount) public onlyTokenOwner returns (bool success) {
        if (_to == address(0x0)) return false;
        if (balances[tokenOwner] < _amount) return false;

        balances[_to] = balances[_to].add(_amount);
        balances[tokenOwner] = balances[tokenOwner].sub(_amount);
        emit Transfer(tokenOwner, _to, _amount);
        return true;
    }

    /**
     * @dev Batch function for token distribute.
     * @param _to List of Recipient.
     * @param _amount List of token amount.
     */
    function distributeBatch(address[] _to, uint[] _amount) external onlyTokenOwner returns (bool success) {
        require(_to.length < 100);

        for(uint i = 0; i < _to.length; i++) {
            if (!distribute(_to[i], _amount[i])) {
                emit DistributeBatch(_to[i], _amount[i]);
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Issue the new tokens.
     * @param _to Recipient of token.
     * @param _amount Tokens amount.
     */
    function mint(address _to, uint _amount) public onlyTokenOwner returns (bool success) {
        if (_to == address(0x0)) return false;

        balances[_to] = balances[_to].add(_amount);
        totalSupply = totalSupply.add(_amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
     * @dev Burn the distributed token.
     * @param _to The owner of distributed token.
     * @param _amount Tokens amount.
     */
    function burn(address _to, uint _amount) public onlyTokenOwner returns (bool success) {
        if (_to == address(0x0)) return false;

        balances[_to] = balances[_to].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        emit Burn(_to, _amount);
        return true;
    }

    /**
     * @dev transfer lock the account.
     * @param _account The address which will lock.
     */
    function lock(address _account) public onlyTokenOwner returns (bool) {
        require(_account != tokenOwner);
        require(_account != address(0x0));

        lockedAccount[_account] = true;
        emit Locked(_account);
        return true;
    }
    
    /**
     * @dev transfer unlock the account.
     * @param _account The address which will unlock.
     */
    function unlock(address _account) public onlyTokenOwner returns (bool) {
        require(_account != tokenOwner);
        require(_account != address(0x0));

        delete lockedAccount[_account];
        emit UnLocked(_account);
        return true;
    }

    /**
     * @dev Batch process the account lock.
     * @param _accounts The list of address which will lock.
     */
    function lockBatch(address[] _accounts) external onlyTokenOwner returns (bool) {
        require(_accounts.length < 100);

        for (uint i = 0; i < _accounts.length; i++) {
            if (!lock(_accounts[i])) {
                emit LockBatch(_accounts[i]);
                return false;
            }
        }
        return true;
    }

    /**
     * @dev Batch process the account unlock.
     * @param _accounts The list of address which will unlock.
     */
    function unlockBatch(address[] _accounts) external onlyTokenOwner returns (bool) {
        require(_accounts.length < 100);

        for (uint i = 0; i < _accounts.length; i++) {
            if (!unlock(_accounts[i])) {
                emit UnlockBatch(_accounts[i]);
                return false;
            }
        }
        return true;
    }


    /**
     * @dev Returns whether the account is locked.
     * @param _account The address to check for lock
     */
    function isLock(address _account) public view returns (bool) {
        return lockedAccount[_account];
    }

    /**
     * @dev Stop the transfer of all tokens.
     * @param _suspended Is stop or start
     */
    function suspend(bool _suspended) external onlyTokenOwner  {
        suspended = _suspended;
        emit Suspend(_suspended);
    }

    /**
     * @dev Destruct the this contract.
     */
    function destruct() public onlyTokenOwner {

        /**
         * The only possibility that code is removed from the blockchain is 
         * when a contract at that address performs the selfdestruct operation. 
         * The remaining Ether stored at that address is sent to a designated target 
         * and then the storage and code is removed from the state.
         */
        selfdestruct(msg.sender);
    }

    /**
     * @dev Withdraw the ERC20 Token in the MyToken contract.
     * @param _erc20 ERC20 Token address.
     * @param _to To receive tokens.
     * @param _amount Tokens amount.
     */
    function withdrawERC20Token(address _erc20, address _to, uint _amount) external onlyTokenOwner {
        require(_to != address(0x0));
        require(Transferable(_erc20).transfer(_to, _amount));
    }
}
