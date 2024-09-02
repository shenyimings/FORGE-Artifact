// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface InterfaceLP {
    function sync() external;
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

    IBEP20 USDTRewards = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 10000 * (10 ** 5);

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
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
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

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = USDTRewards.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(USDTRewards);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = USDTRewards.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
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
            USDTRewards.transfer(shareholder, amount);
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
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract TetherMintFinance is IBEP20, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "TetherMint Finance";
    string constant _symbol = "$TMF";
    uint8 constant _decimals = 5;

    mapping (address => uint256) _rBalance;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isDividendExempt;

    uint256 public TMFLiquidityProtocolFee        = 20;
    uint256 public TMFSustainabilityProtocolFee   = 40;
    uint256 public USDTReflectorFee               = 70;
    uint256 public TMFTreasuryFee                 = 20;
    uint256 public TMFIncineratorFee              = 10;
    uint256 public totalFee            = TMFSustainabilityProtocolFee + TMFTreasuryFee + USDTReflectorFee + TMFLiquidityProtocolFee + TMFIncineratorFee;
    uint256 public feeDenominator      = 1000;
    uint256 public sellFee             = 16;

    address public TMFTreasuryFeeReceiver;
    address public TMFSustainabilityFeeReceiver;
    address public TMFAutoLiquidityReceiver;

    IDEXRouter public router;
    address public pair;
    InterfaceLP public pairContract; 

    bool public tradingOpen = false;

    DividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 100000000 * (10**_decimals);
    uint256 public swapThreshold = rSupply / 1000;
    uint256 public rebase_count = 0;
    uint256 public rate;
    uint256 public _totalSupply;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant MAX_SUPPLY = 1000 * (10**7) * (10**_decimals);
    uint256 private constant rSupply = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // Auto Rebase settings
    bool public autoRebase;
    uint256 public rebaseRate;
    uint256 private _lastRebasedTime;

    function rebase_percentage(uint256 _percentage_base1000000000) public onlyOwner returns (uint256 newSupply){
        newSupply = rebase(0,uint(_totalSupply.div(1000000000).mul(_percentage_base1000000000)));
    }

    function _rebase_percentage(uint256 _percentage_base1000000000) private returns (uint256 newSupply){
            
        newSupply = rebase(0,uint256(_totalSupply.div(1000000000).mul(_percentage_base1000000000)));
    }

    // Sauce
    function rebase(uint256 epoch, uint256 supplyDelta) private returns (uint256) {
        rebase_count++;
        if(epoch == 0){
            epoch = rebase_count;
        }

        require(!inSwap, "Try again");

        if (supplyDelta > 0) { 
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        rate = rSupply.div(_totalSupply);
        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }



    constructor (address newOwner) Auth(newOwner) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(router)] = uint256(-1);

        
        pairContract = InterfaceLP(pair);
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        rate = rSupply.div(_totalSupply);


        distributor = new DividendDistributor(address(router));

        isFeeExempt[newOwner] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        autoRebase = false;
        rebaseRate = 235500;
        _lastRebasedTime = block.timestamp;

        TMFTreasuryFeeReceiver = 0xf119ee0F7729649b21b618d3b80e0c2D2287d6AA;
        TMFSustainabilityFeeReceiver = 0xD01F50063b950Ff692972D999c39083DaB999Db4;
        TMFAutoLiquidityReceiver = 0x227e59B72E53dD947E42435e0A23A5d9d73D129f;

        _rBalance[newOwner] = rSupply;
        emit Transfer(address(0), newOwner, _totalSupply);
    }

    receive() external payable { }

    
    
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }

    function balanceOf(address account) public view override returns (uint256) {
        return _rBalance[account].div(rate);
    }
    
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, uint256(-1));
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(-1)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){
            require(tradingOpen,"Trading not open yet");
        }

        uint256 rAmount = amount.mul(rate);

        if(shouldSwapBack()){ swapBack(); }

        if(shouldRebase()){ 
            _rebase_percentage(rebaseRate); 
            _lastRebasedTime = block.timestamp;
        }

        //Exchange tokens
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? rAmount : takeFee(sender, rAmount,(recipient == pair));
        _rBalance[recipient] = _rBalance[recipient].add(amountReceived);

        // Dividend tracker
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, balanceOf(sender)) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} 
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived.div(rate));
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 rAmount = amount.mul(rate);
        _rBalance[sender] = _rBalance[sender].sub(rAmount, "Insufficient Balance");
        _rBalance[recipient] = _rBalance[recipient].add(rAmount);
        emit Transfer(sender, recipient, rAmount.div(rate));
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 rAmount, bool isSell) internal returns (uint256) {
        
        uint256 _finalFee = totalFee;
        if(isSell){
            _finalFee += sellFee;
        } 

        uint256 feeAmount = rAmount.div(feeDenominator).mul(_finalFee);

        _rBalance[address(this)] = _rBalance[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount.div(rate));

        return rAmount.sub(feeAmount);
    }

    function shouldRebase() internal view returns (bool) {
        return
            autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            msg.sender != pair  &&
            !inSwap &&
            block.timestamp >= (_lastRebasedTime + 15 minutes);
    }

    function autoRebaseEnabled(bool enabled) public onlyOwner {
        autoRebase = enabled;
    }

    function setRebaseRate(uint256 newRate_base1000000000) public onlyOwner {
        rebaseRate = newRate_base1000000000;
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _rBalance[address(this)] >= swapThreshold;
    }

    function clearStuckBNB(uint256 amountPercentage) external authorized {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB * amountPercentage / 100);
    }

    // enable trading
    
    function openTrading() external onlyOwner {
        tradingOpen = true;
        autoRebase = true;
    }

    function swapBack() internal swapping {
        uint256 tokensToSell = balanceOf(address(this));

        uint256 amountToLiquify = tokensToSell.div(totalFee).mul(TMFLiquidityProtocolFee).div(2);
        uint256 amountToBurn = tokensToSell.div(totalFee).mul(TMFIncineratorFee);
        uint256 amountToSwap = tokensToSell.sub(amountToLiquify).sub(amountToBurn);

        _basicTransfer(address(this), DEAD, amountToBurn);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(TMFLiquidityProtocolFee.div(2)).sub(TMFIncineratorFee);
        
        uint256 amountBNBLiquidity = amountBNB.mul(TMFLiquidityProtocolFee).div(totalBNBFee).div(2);
        uint256 amountBNBReflection = amountBNB.mul(USDTReflectorFee).div(totalBNBFee);
        uint256 amountBNBTreasury = amountBNB.mul(TMFTreasuryFee).div(totalBNBFee);
        uint256 amountBNBSustainability = amountBNB.mul(TMFSustainabilityProtocolFee).div(totalBNBFee);

        try distributor.deposit{value: amountBNBReflection}() {} catch {}

        payable(TMFTreasuryFeeReceiver).transfer(amountBNBTreasury);
        payable(TMFSustainabilityFeeReceiver).transfer(amountBNBSustainability);

        

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                TMFAutoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify.div(rate));
        }
    }    
    
    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }
    
    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setFeeReceivers(address _TMFTreasuryFeeReceiver, address _TMFSustainabilityFeeReceiver, address _TMFAutoLiquidityReceiver ) external authorized {
        TMFTreasuryFeeReceiver = _TMFTreasuryFeeReceiver;
        TMFSustainabilityFeeReceiver = _TMFSustainabilityFeeReceiver;
        TMFAutoLiquidityReceiver = _TMFAutoLiquidityReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentage_base100000) external authorized {
        swapEnabled = _enabled;
        swapThreshold = rSupply.div(100000).mul(_percentage_base100000);
    }

    function manualSync() external {
        InterfaceLP(pair).sync();
    }
    
    function setLP(address _address) external onlyOwner {
        pairContract = InterfaceLP(_address);
        isFeeExempt[_address];
    }

    function checkSwapThreshold() external view returns (uint256) {
        return swapThreshold.div(rate);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }
    
    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 900000);
        distributorGas = gas;
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        return (rSupply.sub(_rBalance[DEAD]).sub(_rBalance[ZERO])).div(rate);
    }

    


/* Airdrop Begins */

function multiTransfer(address[] calldata addresses, uint256[] calldata tokens) external onlyOwner {

    require(addresses.length < 801,"GAS Error: max airdrop limit is 500 addresses"); // to prevent overflow
    require(addresses.length == tokens.length,"Mismatch between Address and token count");

    uint256 SCCC = 0;

    for(uint i=0; i < addresses.length; i++){
        SCCC = SCCC + tokens[i];
    }

    require(balanceOf(msg.sender) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(msg.sender,addresses[i],tokens[i]);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[msg.sender]) {
        try distributor.setShare(msg.sender, balanceOf(msg.sender)) {} catch {}
    }
}

function multiTransfer_fixed(address[] calldata addresses, uint256 tokens) external onlyOwner {

    require(addresses.length < 2001,"GAS Error: max airdrop limit is 2000 addresses"); // to prevent overflow

    uint256 SCCC = tokens * addresses.length;

    require(balanceOf(msg.sender) >= SCCC, "Not enough tokens in wallet");

    for(uint i=0; i < addresses.length; i++){
        _basicTransfer(msg.sender,addresses[i],tokens);
        if(!isDividendExempt[addresses[i]]) {
            try distributor.setShare(addresses[i], balanceOf(addresses[i])) {} catch {} 
        }
    }

    // Dividend tracker
    if(!isDividendExempt[msg.sender]) {
        try distributor.setShare(msg.sender, balanceOf(msg.sender)) {} catch {}
    }
}

event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

}