// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
        function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}


abstract contract Ownable {
    address private _owner;
    mapping(address => bool) private authorized;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        authorized[msgSender] = true;
        emit OwnershipTransferred(address(0), msgSender);
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    function authorize(address account, bool _authorize) public onlyOwner{
        authorized[account] = _authorize;
    }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Ownable: caller is not authorized");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20 is IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }
    
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        
        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
contract RDividendDistributor is IDividendDistributor {
    
    address _token;
    address public _owner;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // BSC Polkadot-PEG  
    IERC20 REWARD = IERC20(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402); 
    
    IUniswapV2Router _uniswapV2Router;
    
    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;

    mapping(address => Share) public shares;

    uint256 public totalShares;             
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    
    uint256 public minPeriod = 60 * 60;
    
    uint256 public minDistribution = 1 * (10**3);

    uint256 currentIndex;

    bool initialized;
    
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token || msg.sender == _owner);
        _;
    }
    
    constructor(address _router, address owner_) {
        _uniswapV2Router = IUniswapV2Router(_router);
        _token = msg.sender;
        _owner = owner_;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken
    {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(
            shares[shareholder].amount
        );
    }

    function deposit() public payable  {
        
        address[] memory path =  new address[](2);
        path[0] = _uniswapV2Router.WETH();
        path[1] = address(REWARD);
        _uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
            );
        uint256 newBalance = REWARD.balanceOf(address(this));
        
        totalDividends = totalDividends + newBalance;
        dividendsPerShare = dividendsPerShare + 
            dividendsPerShareAccuracyFactor * newBalance / totalShares;
    }
    
    receive() external payable {
        this.deposit{value: msg.value}();
    }

    function process(uint256 gas) external override {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool)
    {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp &&
                getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed + amount;
            //(bool success, ) = shareholder.call{value: amount, gas: 3000}(""); success; //Handle
            REWARD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder]
                .totalRealised + amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(
                shares[shareholder].amount);
        }
    }

    function claimDividend() external {
        distributeDividend(msg.sender);
    }

    function getUnpaidEarnings(address shareholder)
        public
        view
        returns (uint256)
    {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(
            shares[shareholder].amount
        );
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share)
        internal
        view
        returns (uint256)
    {
        return
            share * dividendsPerShare / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////





contract ARABIANSHINJA is ERC20, Ownable {                                                                                          ///////////////
   
    IUniswapV2Router public uniswapV2Router;
    address public immutable uniswapV2Pair;

    

    RDividendDistributor public dividendDistributor;
    
    address public deadAddress = address(0x0000000000000000000000000000000000000000);
    address public marketingAddress;
    address public devAddress;
    address public treasuryAddress;
    
    
    uint256 private constant TOTAL_SUPPLY = 1000000000000; // 1 T tokens                                                                         /////////////
    uint256 private constant DECIMALS = 1e18;
    
    uint256 public maxTx = 5 * TOTAL_SUPPLY / 1000 * (DECIMALS);               // 0.5%  of total supply
    uint256 public swapTokensAtAmount = 0 * TOTAL_SUPPLY / 1e4 * (DECIMALS);   // 0.05% of total supply                                             /////////
    uint256 public maxWallet = 20 * TOTAL_SUPPLY / 1000 * (DECIMALS);          // 2.0%  of total supply
    uint256 public rewardsFee;
    uint256 public liquidityFee;  
    uint256 public marketingFee; 
    uint256 public TreasuryFee; 
    uint256 public devFee; 
    uint256 public sellFeeIncrease;
    uint256 public totalFees;   
    
    bool private swapping;
    
    uint256 private nAntiBotBlocks;
    uint256 private antiBotDuration;
    uint256 private launchBlock;
    uint256 private tradeCooldown;
    bool private antiBotActive = false;
    mapping (address => uint256) timeLastTrade;
    mapping (address => bool) launchSniper;
    
    bool private tradingIsEnabled = false;
    bool private hasLaunched = false;
    
    bool public intensify = false;
    bool public shouldBurnFee = false;
    uint256 public intensifyDuration;
    uint256 public intensifyStart;
    
    uint256 public burnAmount = 0;
    bool public accumulatingForBurn = false;
    bool private inBurn = false;
    
    // use by default 400,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 4e5;

    mapping (address => bool) public isExcludedFromFees;
    mapping (address => bool) public isExcludedFromDividends;

    mapping (address => bool) public isPair;


    event Launch(uint256 indexed nAntiBotBlocks);
    event SetFees(uint256 indexed marketingFee, uint256 indexed devFee, uint256 indexed TreasuryFee);
    event SetTradeRestrictions(uint256 indexed maxTx, uint256 indexed maxWallet);
    event SetSwapTokensAtAmount(uint256 indexed swapTokensAtAmount);  
    
    event UpdateDividendDistributor(address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromDividends(address indexed account, bool indexed shouldExclude);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived
    );

    event SendDividends(
    	uint256 FTMRewards
    );

    event ProcessedDividendDistributor(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20("ARABIANSHINJA", "$ARABIANSHINJA") {                                                     /////////////////////////////////
        
        uint256 _rewardsFee = 0;                                                                    /////////////////////////////
        uint256 _liquidityFee = 1;
        uint256 _marketingFee = 3;
        uint256 _TreasuryFee = 1;
        uint256 _devfee = 1;
        uint256 _sellFeeIncrease = 4;

        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        devFee = _devfee;
        TreasuryFee = _TreasuryFee;
        sellFeeIncrease = _sellFeeIncrease;
        totalFees = _rewardsFee + _liquidityFee + _marketingFee + _TreasuryFee + _devfee;

    	// BSC Mainnet PancakeSwap
    	IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        dividendDistributor = new RDividendDistributor(address(_uniswapV2Router), owner());
    	marketingAddress = address(0xCA4eA7B1523Bd1368caDb56192F1329435c7B262);
        devAddress = address(0x2D526686df4C213ed8484C1515391F2378b90A34);
        treasuryAddress = address(0xc6779dAD64EAc07058A03258d59470469938b48F);

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(dividendDistributor), true);
        excludeFromDividends(address(_uniswapV2Router), true);

        excludeFromFees(deadAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(owner(), true);

        /*
            _mint is an internal function in that is only called here,
            and CANNOT be called ever again.
        */
        _mint(owner(), TOTAL_SUPPLY * (DECIMALS));
    }
    
    modifier inSwap {
        swapping = true;
        _;
        swapping = false;
    }
    
    modifier inburn{
        inBurn = true;
        _; 
        inBurn = false;
    }
    
    function initiateAntiBot(uint256 _antiBotDuration) public onlyOwner{
        require(!tradingIsEnabled, "Project already launched.");
        antiBotDuration = _antiBotDuration;
        antiBotActive = true;
        tradingIsEnabled = true;
    }
    
    function launch(uint256 _nAntiBotBlocks,uint256 _tradeCooldown) public onlyOwner{
        require(!hasLaunched, "Project already launched.");
        nAntiBotBlocks = _nAntiBotBlocks;
        launchBlock = block.number;
        tradeCooldown = _tradeCooldown;
        hasLaunched = true;
        
        emit Launch(_tradeCooldown);
    }

    function updateDividendDistributor(address newAddress) public onlyOwner {
        require(newAddress != address(dividendDistributor), " The dividend distributor already has that address");

        RDividendDistributor newDividendDistributor = RDividendDistributor(payable(newAddress));

        require(newDividendDistributor._owner() == address(this), " The new dividend distributor must be owned by the Test token contract");

        excludeFromDividends(address(newDividendDistributor), true);
        excludeFromDividends(address(this), true);
        excludeFromDividends(address(uniswapV2Router), true);

        emit UpdateDividendDistributor(newAddress, address(dividendDistributor));

        dividendDistributor = newDividendDistributor;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Test: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(isExcludedFromFees[account] != excluded, "Test: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function excludeFromDividends(address account, bool shouldExclude) public onlyOwner {
        isExcludedFromDividends[account] = shouldExclude;
        emit ExcludeFromDividends(account, shouldExclude);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Test: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(isPair[pair] != value, "Test: Automated market maker pair is already set to that value");
        isPair[pair] = value;

        if(value) {
            excludeFromDividends(pair, true);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 800000, "Test: gasForProcessing must be between 200,000 and 800,000");
        require(newValue != gasForProcessing, "Test: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) public onlyOwner{
        
        dividendDistributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }
    
    function getClaimWait() external view returns(uint256) {
        return dividendDistributor.minPeriod();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendDistributor.totalDistributed();
    }
   
    function claim() external {
		dividendDistributor.claimDividend();
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256) {
        return dividendDistributor.totalShares();
    }
    
    function setFees(uint256 _marketingFee, uint256 _devFee, uint256 _treasuryFee, uint256 _liquidityFee, uint256 _rewardsFee, uint256 _sellFeeIncrease) public onlyOwner{
        require(0 <= _rewardsFee && _rewardsFee <= 5, "Requested rewardsFee fee not within acceptable range.");
        require(0 <= _liquidityFee && _liquidityFee <= 5 , "Requested liquidity fee not within acceptable range.");
        require(0 <= _marketingFee && _marketingFee <= 5, "Requested marketing fee not within acceptable range.");
        require(0 <= _devFee && _devFee <= 5, "Requested marketing fee not within acceptable range.");
        require(0 <= _devFee && _treasuryFee <= 5, "Requested marketing fee not within acceptable range.");
        require(0 <= _sellFeeIncrease && _sellFeeIncrease <= 6, "Requested sell fee increase not within acceptable range.");
        require(0 < _marketingFee + _liquidityFee, "Total fee amount must be strictly positive.");
        
        rewardsFee = _rewardsFee;
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee; 
        devFee = _devFee;
        TreasuryFee = _treasuryFee;
        sellFeeIncrease = _sellFeeIncrease;
        totalFees = _rewardsFee + _liquidityFee + _marketingFee + _treasuryFee + _devFee;
        
        emit SetFees( marketingFee, TreasuryFee, devFee);  
    }
    
    function setTradeRestrictions(uint256 _maxTx, uint256 _maxWallet) public onlyOwner{
        require(_maxTx >= (5 * TOTAL_SUPPLY / 1000), "Requested max transaction amount too low.");
        require(_maxWallet >= (20 * TOTAL_SUPPLY / 1000), "Requested max allowable wallet amount too low.");
        
        maxTx = _maxTx * DECIMALS;
        maxWallet = _maxWallet * DECIMALS;
        
        emit SetTradeRestrictions(maxTx, maxWallet);
    }

    function setSwapTokensAtAmount(uint256 _swapTokensAtAmount) public onlyOwner{
        require(5 * TOTAL_SUPPLY / 1000 <= _swapTokensAtAmount && _swapTokensAtAmount <= 2 * TOTAL_SUPPLY / 100,
        "Requested contract swap amount out of acceptable range.");
        
        swapTokensAtAmount = _swapTokensAtAmount * DECIMALS;
         
         emit SetSwapTokensAtAmount(swapTokensAtAmount);  
    }
    
    function checkValidTrade(address from, address to, uint256 amount) private view{
        if (from != owner() && to != owner() && !isExcludedFromFees[from]) {
            require(tradingIsEnabled, "Project has yet to launch.");
            require(amount <= maxTx, "Transfer amount exceeds the maxTxAmount."); 
            if (isPair[from]){
                require(balanceOf(address(to)) + amount <= maxWallet, "Token purchase implies maxWallet violation.");
            }
        } 
    }
    
    function _transfer(address from, address to, uint256 amount) internal override {
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
    
        checkValidTrade(from, to, amount);
        bool takeFee = tradingIsEnabled && !swapping;
        
        if(isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        if(takeFee) {
            uint256 fees;
            bool _burnFees = false;
           if(antiBotActive){
               if(isPair[from]){
                   require(!launchSniper[to], "Do not buy before official launch.");
                   if(!hasLaunched){
                       super._transfer(from, address(this), amount);
                       launchSniper[to] = true;
                       return;
                   }
                   if(timeLastTrade[to] != 0){
                       require(block.number > timeLastTrade[to] + tradeCooldown, "Trade too frequent.");
                   }
                   timeLastTrade[to] = block.number;
               }
               
                if(block.number < launchBlock + nAntiBotBlocks){
                    fees = amount * 99 / 100;    
                }
                else{
                    antiBotActive = block.number > launchBlock + antiBotDuration ? false : antiBotActive;
                    (uint256 fee, bool burnFees) = calculateFee(from);
                    _burnFees = burnFees;
                    fees = amount * fee / 100;
                }
           }
           else{
            (uint256 fee, bool burnFees) = calculateFee(from);
            _burnFees = burnFees;
            fees = amount * fee / 100;   
           }

        	amount = amount - fees;
            super._transfer(from, (_burnFees ? deadAddress : address(this)), fees);
        }
        
        if(accumulatingForBurn){
            if(shouldBurn()){
                doBurn(burnAmount);
            }    
        }
        else if(shouldSwap(from)) { 
            swapTokens(swapTokensAtAmount);
        }
        
        super._transfer(from, to, amount);

        if(!isExcludedFromDividends[from])
            try dividendDistributor.setShare(payable(from), balanceOf(from)) {} catch {}
        if(!isExcludedFromDividends[to])
            try dividendDistributor.setShare(payable(to), balanceOf(to)) {} catch {}
        
        if(tradingIsEnabled && !swapping && !antiBotActive) {
	    	try dividendDistributor.process(gasForProcessing) {
	    	} catch {}
        }
    }
    
    function rush(bool _shouldBurn, uint256 _minutes) external onlyAuthorized{
        require(_minutes <= 120, "Rush may not last over two hours.");
        intensify = true;
        shouldBurnFee = _shouldBurn;
        intensifyDuration = _minutes * 1 minutes;
        intensifyStart = block.timestamp;
    }
    
    function calculateFee(address from) private returns (uint256, bool){
        uint256 fee;
        if(intensify){
            uint256 halfTime = intensifyStart  + intensifyDuration / 2;
            uint256 fullTime = intensifyStart  + intensifyDuration;
            
            if(block.timestamp < halfTime){
                fee = isPair[from] ? 0 : 20;
                return (fee, shouldBurnFee);
            }
            else if(block.timestamp < fullTime){
                fee = isPair[from] ? 5 : 15;
                return (fee, shouldBurnFee);
            }
            else{
                fee = isPair[from] ? totalFees : totalFees + sellFeeIncrease;
                intensify = false;
                return (fee, false);
            }
        }
        else{
            fee = isPair[from] ? totalFees : totalFees + sellFeeIncrease;
            return (fee, false);
        }
    }
    
    function shouldBurn() private view returns (bool){
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canBurn = contractTokenBalance >= burnAmount;
        return tradingIsEnabled && canBurn &&
        !inBurn && !antiBotActive;
    }
    
    function planBurn(uint256 _burnNumerator, uint256 _burnDenominator) public onlyAuthorized {
        burnAmount = TOTAL_SUPPLY * DECIMALS * _burnNumerator / _burnDenominator;
        accumulatingForBurn = true;
    } 
    
    function doBurn(uint256 _burnAmount) private inburn {
        super._transfer(address(this), deadAddress, _burnAmount);
        accumulatingForBurn = false;
    }
    
    function shouldSwap(address from) private view returns (bool){
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        return tradingIsEnabled && canSwap && !swapping &&
        !isPair[from] && !isExcludedFromFees[from] && !antiBotActive;
    }    
        
    function swapTokens(uint256 tokens) private inSwap {
        uint256 LPtokens = tokens * liquidityFee / totalFees;
        uint256 halfLPTokens = LPtokens / 2;
        uint256 marketingtokens = tokens * marketingFee / totalFees;
        uint256 devtokens = tokens * devFee / totalFees;
        uint256 treasurytokens = tokens * TreasuryFee / totalFees;
        uint256 rewardTokens = tokens - LPtokens - marketingtokens - devtokens - treasurytokens ;
        uint256 swapAmount = halfLPTokens + marketingtokens + devtokens + treasurytokens + rewardTokens;
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(swapAmount); 
         
        uint256 newBalance = address(this).balance - initialBalance;
        
        uint256 BNBForLP = newBalance * halfLPTokens / swapAmount;
        uint256 BNBForMarketing = newBalance * marketingtokens / swapAmount;
        uint256 BNBForDev = newBalance * devtokens / swapAmount;
        uint256 BNBForTreasury = newBalance * treasurytokens / swapAmount;

        (bool temp,) = payable(marketingAddress).call{value: BNBForMarketing, gas: 30000}(""); temp; //warning-suppresion 
        (bool temp1,) = payable(devAddress).call{value: BNBForDev, gas: 30000}(""); temp1; //warning-suppresion 
        (bool temp2,) = payable(treasuryAddress).call{value: BNBForTreasury, gas: 30000}(""); temp2; //warning-suppresion 

        if(halfLPTokens>0){
            addLiquidity(halfLPTokens, BNBForLP);
            emit SwapAndLiquify(halfLPTokens, BNBForLP);
        }
        uint256 BNBForRewards = address(this).balance;
        try dividendDistributor.deposit{value: BNBForRewards}() {} catch{} //warning-suppresion 
        emit SendDividends(BNBForRewards);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress,
            block.timestamp
        );
    }
    
    function buybackStuckBNB(uint256 percent) public onlyAuthorized {
        uint256 amountToBuyBack = address(this).balance * percent / 100;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountToBuyBack}(
            0, // accept any amount of Tokens
            path,
            deadAddress, 
            block.timestamp
        );
    } 
    
    receive() external payable {}
}