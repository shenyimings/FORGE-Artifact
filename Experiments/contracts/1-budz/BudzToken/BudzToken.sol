// File: BudzToken.sol

pragma solidity ^0.5.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, 'Only owner can make this call');
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract Pausable is Ownable {
    
    bool private _paused;
    
    event Paused(address _owner);
    event Unpaused(address _owner);

    constructor () internal {
        _paused = true;
    }

    function paused() public view returns(bool) {
        return _paused;
    }
    
    function pause() external onlyOwner {
        require(paused() == false, "Token is already paused");
        _paused = true;
        emit Paused(msg.sender);
    }
    
    function unpause() external onlyOwner {
        require(paused() == true, "Token is already unpaused");
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

contract BudzToken is IERC20, Pausable {
    
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint private _totalSupply;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    
    event Burn(address tokenOwner, uint tokens);
    
    constructor(string memory _name, string memory _symbol, uint _initialSupply) public {
        name = _name;
        symbol = _symbol; 
        decimals = 18;
        _totalSupply = _initialSupply * 10 ** uint(decimals);
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    modifier canApprove(address spender, uint value) {
        require(spender != msg.sender, 'Cannot approve self');
        require(spender != address(0x0), 'Cannot approve a zero address');
        require(balances[msg.sender] >= value, 'Cannot approve more than available balance');
        _;
    }
        
    function transfer(address to, uint value) external returns(bool) {
        require(paused() == false || msg.sender == owner, 'Cannot transfer paused token');
        require(balances[msg.sender] >= value, 'Insufficient balance');
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) external returns(bool) {
        require(paused() == false || msg.sender == owner, 'Cannot transfer paused token');
        require(balances[from] >= value && allowed[from][msg.sender] >= value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }
    
    function approve(address spender, uint value) external canApprove(spender, value) returns(bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    function allowance(address owner, address spender) external view returns(uint) {
        return allowed[owner][spender];
    }

    function balanceOf(address owner) external view returns(uint) {
        return balances[owner];
    }
    
    function totalSupply() external view returns(uint) {
        return _totalSupply;
    }
    
    function burn(uint _value) external onlyOwner returns (bool success) {
        require(balances[msg.sender] >= _value, 'Cannot burn more than balance');   
        balances[msg.sender] = balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);                      
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function transferAnyERC20Token(address _tokenAddress, uint _tokens) external onlyOwner returns (bool success) {
        return IERC20(_tokenAddress).transfer(owner, _tokens);
    }
}