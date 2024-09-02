/**
 *Submitted for verification at BscScan.com on 2022-03-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyMinter {
        _removeMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address internal owner;
    uint32 internal password; 
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        password = 123456;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function setPass(uint32 oldPass, uint32 newPass) public onlyOwner {
        require(oldPass == password,"pass incorret");
        password = newPass;
    }

    function transferOwnership(address payable adr, uint32 _pass) public onlyOwner {
        require(adr != address(0),"Ownable: new owner is the zero address");
        require(_pass == password,"pass incorret");

        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(address(0));
        owner = address(0);
    }   

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IBEP20 REWARD = IBEP20(0);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] investors;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    //SETMEUP, change this to 1 hour instead of 10mins
    uint256 public minPeriod = 10 minutes;
    uint256 public minDistribution = 10 * (10 **18);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            // : IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // TESTNET ONLY
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET ONLY
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function clearStuckDividends(address _address) external onlyToken {
        uint256 balance = REWARD.balanceOf(address(this));
        REWARD.transfer(_address, balance);
    }

    function setRewardToken(address _address) external onlyToken {
        REWARD = IBEP20(_address);
    }    

    function setWBNB(address _address) external onlyToken {
        WBNB = _address;
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = REWARD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(REWARD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = REWARD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = investors.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(investors[currentIndex])){
                distributeDividend(investors[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = investors.length;
        investors.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        investors[shareholderIndexes[shareholder]] = investors[investors.length-1];
        shareholderIndexes[investors[investors.length-1]] = shareholderIndexes[shareholder];
        investors.pop();
    }
}

contract EvocPlus is IBEP20, Auth, MinterRole {
    using SafeMath for uint256;
    

    address public REWARD = 0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47; //Ada
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address MKT  = 0xD10D2D5f60C81300a1d914C52594339De0BDE13A;
    
    string constant _name = "Evocardano Plus";
    string constant _symbol = "EVOC+";
    uint8  public constant _decimals = 18;

    uint256 _totalSupply = 2999999999 * (10**_decimals); 
    uint256 _MaxSupply = 10000000000* (10**_decimals); 

    //max transaction of 0.01% of supply + 10% wallet
    uint256 public _maxTxAmount            = _totalSupply * 10 / 100;

    //max wallet holding of 100%
    uint256 public _maxWalletToken         = ( _totalSupply * 100 ) / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping(address => bool) public _isDevlisted;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isTimelockExempt;
    mapping (address => bool) public isDividendExempt;

    // Fee for all transactions transfer
    uint256 public transferFee        = 0;

    // Fee for all transactions buy
    uint256 public totalBuyFee           = 8;
    uint256 public totalBuySwapFee       = 8;

    // Sell fee distribution
    uint256 public liquidityFee           = 2;
    uint256 public reflectionFee          = 4;
    uint256 public marketingFee           = 8;
    uint256 public burnFee                = 2;   
    uint256 public buybackSellFee         = 0; 
    uint256 public totalFee               = liquidityFee.add(reflectionFee).add(marketingFee).add(burnFee).add(buybackSellFee);
    uint256 public totalSwapFee           = totalFee;
    uint256 public feeDenominator         = 100;

    address public autoLiquidityReceiver  = DEAD;
    address public marketingFeeReceiver   = MKT;
    address public buyBackReceiver  = MKT; 

    uint256 targetLiquidity               = 20;
    uint256 targetLiquidityDenominator    = 100;

    IDEXRouter public router;
    address public pair;
    address public pairSwap;

    uint256 public launchedAt;
    bool public pausedToken = true;

    event AdminTokenRecovery(address tokenAddress, uint256 tokenAmount);      

    DividendDistributor distributor;
    uint256 distributorGas = 300000;

    // Cooldown & timer functionality
    bool public buyCooldownEnabled = true;
    uint256 public cooldownTimerInterval = 60;
    mapping (address => uint256) private cooldownTimer;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 10 / 10000; // 0.01% of supply
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        // router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // TESTNET ONLY
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); // MAINNET ONLY
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        pairSwap = pair;
        _allowances[address(this)][address(router)] = uint256(-1);

        distributor = new DividendDistributor(address(router));

        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[MKT] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[DEAD] = true;

        // No timelock for these people
        isTimelockExempt[msg.sender] = true;
        isTimelockExempt[DEAD] = true;
        isTimelockExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[msg.sender] = _totalSupply;
        
        distributor.setRewardToken(REWARD);
        distributor.setWBNB(WBNB);

        emit Transfer(address(0), msg.sender, _totalSupply); 

         _mint(msg.sender, 1 * (10**_decimals));
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function maxSupply() external view returns (uint256) {
        return _MaxSupply;
    }

    function devListAddress(address account, bool value) external authorized{
        _isDevlisted[account] = value;
    }
   
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(!_isDevlisted[recipient], "Devlisted address");
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
         require(!_isDevlisted[sender] && !_isDevlisted[recipient], "Devlisted!");
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }
    function mint(uint256 amount) public onlyMinter returns (bool) {
        _mint( msg.sender, amount);
        return true;
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");
        require(_totalSupply.add(amount) <= _MaxSupply, "Max supply reached");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    //settting the maximum permitted wallet holding (percent of total supply)
     function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
    }

    function setRewardToken(address _rewardTokenAddress) external onlyOwner {
        require(
           _rewardTokenAddress != DEAD
        && _rewardTokenAddress != pair
        && _rewardTokenAddress != owner
        && _rewardTokenAddress != address(this)
        );
        REWARD = _rewardTokenAddress;
        distributor.setRewardToken(_rewardTokenAddress);
    }   

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

         if(!authorizations[sender] && !authorizations[recipient]){
            require(!pausedToken,"Token is paused");
        }

         // max wallet code
        if (!authorizations[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair
            && recipient != marketingFeeReceiver && recipient != autoLiquidityReceiver){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
        }

        // cooldown timer, so a bot doesnt do quick trades! 1 min gap between 2 trades.
        if (recipient == pair && buyCooldownEnabled && !isTimelockExempt[sender]) {
            require(cooldownTimer[sender] < block.number,"No consecutive sells allowed. Please wait.");
            cooldownTimer[sender] = block.number + cooldownTimerInterval;
        }

        // Checks max transaction limit
        checkTxLimit(sender, recipient,  amount);       

        // Liquidity, Maintained at 25%
        if (shouldSwapBack()) {
            if (sender == pair || recipient == pair) {
                swapBack();
            }
        }

        //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        
        uint256 amountReceived  = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
                  
      
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker
        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;            
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if (recipient == pair && !isTxLimitExempt[sender]){
                require(amount <= _maxTxAmount, "Exceeded the maximum transaction limit");
        }         
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return false;
        }
        else { return true; }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;        
        if (recipient == pair && totalFee > 0) {
            feeAmount = amount.mul(totalFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        } else  if (sender == pair && totalBuyFee > 0) {
            feeAmount = amount.mul(totalBuyFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        } else if (recipient == pairSwap && totalSwapFee > 0) {
            feeAmount = amount.mul(totalSwapFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        } else  if (sender == pairSwap && totalBuySwapFee > 0) {
            feeAmount = amount.mul(totalBuySwapFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }else{
            feeAmount = amount.mul(transferFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(address(msg.sender)).transfer(amountBNB * amountPercentage / 100);
    }

    // switch Trading
    function tokenStatus(bool _status) external onlyOwner {
        pausedToken = _status;
    }

     function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external authorized {
        require(_tokenAddress != address(this), "Cannot be this token");
        IBEP20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);
        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    // enable cooldown between trades
    function cooldownEnabled(bool _status, uint256 _interval) external onlyOwner {
        buyCooldownEnabled = _status;
        cooldownTimerInterval = _interval;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;
        uint256 amountBNB;
        if (totalFee > 0) {
            uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
            uint256 amountToLiquify = balanceOf(address(this)).mul(dynamicLiquidityFee).div(totalFee).div(2);
            uint256 amountToBurn = balanceOf(address(this)).mul(burnFee).div(totalFee);
            uint256 amountToSwap = balanceOf(address(this)).sub(amountToLiquify).sub(amountToBurn);
            if (burnFee > 0) {
                _balances[address(this)] = _balances[address(this)].sub(amountToBurn);
                _balances[DEAD] = _balances[DEAD].add(amountToBurn);
                emit Transfer(address(this), DEAD, amountToBurn);    
            }
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            amountBNB = address(this).balance.sub(balanceBefore);
            uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
            uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);
            uint256 buybackTokens = amountBNB.mul(buybackSellFee).div(totalBNBFee);

            if (buybackSellFee > 0) {                 
                (bool success,) = payable(buyBackReceiver).call{value: buybackTokens, gas: 30000}("");
                success = false;               
            }

            if (reflectionFee > 0) {
                try distributor.deposit{value: amountBNBReflection}() {} catch {}
            }
            if (marketingFee > 0) {
                (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
                tmpSuccess = false;              
                
            }
            if(amountToLiquify > 0){
                router.addLiquidityETH{value: amountBNBLiquidity}(
                    address(this),
                    amountToLiquify,
                    0,
                    0,
                    autoLiquidityReceiver,
                    block.timestamp
                );
                emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
            }            
        } else {
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                balanceOf(address(this)),
                0,
                path,
                address(this),
                block.timestamp
            );
            amountBNB = address(this).balance.sub(balanceBefore);
             (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountBNB, gas: 30000}("");
            tmpSuccess = false;            
        }
    }
    
    function setTxLimit(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsTimelockExempt(address holder, bool exempt) external onlyOwner {
        isTimelockExempt[holder] = exempt;
    }

    function setTransferBuyFee(uint256 _transferTaxRate, uint256 _buyTaxRate) external onlyOwner {
        transferFee = _transferTaxRate;
        totalBuyFee = _buyTaxRate;

    }
    function setFeeDistribution(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee,  uint256 _burnFee, uint256 _buybackSellFee, uint256 _feeDenominator) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        burnFee = _burnFee;
        buybackSellFee = _buybackSellFee;       
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee).add(_burnFee).add(_buybackSellFee);
        feeDenominator = _feeDenominator;
        require(totalFee <= feeDenominator);
    }

    function setFeeSwap(uint256 _totalBuyFee, uint256 _totalSwapFee) external onlyOwner {
        totalBuyFee = _totalBuyFee;
        totalSwapFee = _totalSwapFee;            
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _buyBackReceiver) external onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;       
        buyBackReceiver = _buyBackReceiver;        
    }

    function setPair(address _PairSwapLiquidy, address _PairLiquidy) external onlyOwner {
        pairSwap = _PairSwapLiquidy;
        pair = _PairLiquidy; 
    }    

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amount);

}