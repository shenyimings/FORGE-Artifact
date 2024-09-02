// SPDX-License-Identifier: Unlicensed 
// Not open source - Custom Contract by Gen t.me/GenTokens_GEN TokensByGen.com

/*

    GlobalReserveCoin (GRC)

    https://twitter.com/grcgold
    https://www.youtube.com/@GlobalReserveCoin
    https://t.me/globalreservecoin

    BUSD Rewards
    Backed by Gold

*/

pragma solidity 0.8.19;

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


interface IDividendDistributor {

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {require(b <= a, errorMessage);
            return a - b;}}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {require(b > 0, errorMessage);
            return a / b;}}
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}


library Address {
    
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "unable to send, recipient reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "low-level call with value failed");
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "insufficient balance for call");
        require(isContract(target), "call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "low-level static call failed");
    }
    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "low-level delegate call failed");
    }
    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                 assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}

interface IUniswapV2Router01 {

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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



contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // Reward Token BUSD
    IERC20 RWDTOKEN = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    
    // WBNB (BSC)
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    IUniswapV2Router02 public DivRouter;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 900; // 15 minutes (900 Seconds)
    uint256 public minDistribution = 1 * (10 ** 17); // $0.10 required for payout

    uint256 currentIndex;

    modifier onlyToken() {
        
        require(msg.sender == _token);
        _;
    }

    constructor () {

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); 
        DivRouter = _uniswapV2Router;
        _token = msg.sender;
    }



    function Claim_Rewards() external {
        distributeDividend(msg.sender);
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

        totalShares = totalShares + amount - shares[shareholder].amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {

        uint256 balanceBefore = RWDTOKEN.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWDTOKEN);

        DivRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = RWDTOKEN.balanceOf(address(this)) - balanceBefore;
        totalDividends += amount;
        dividendsPerShare = dividendsPerShare + (dividendsPerShareAccuracyFactor * amount / totalShares);

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

            gasUsed = gasUsed + (gasLeft - gasleft());
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

        if(shares[shareholder].amount == 0){

            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);

        if(amount > 0){

            totalDistributed += amount;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += amount;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            RWDTOKEN.transfer(shareholder, amount);
        }
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {


        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
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






contract GlobalReserveCoin is Context, IERC20 { 

    using SafeMath for uint256;
    using Address for address;

    // Contract Wallets
    address private _owner = 0x486A72846547268B3A9BbDdb7C5B75D92eE66f67;  
    address public Wallet_Liquidity = 0x486A72846547268B3A9BbDdb7C5B75D92eE66f67; 
    address payable public Wallet_Marketing = payable(0x486A72846547268B3A9BbDdb7C5B75D92eE66f67); 
    address payable public Wallet_Gold = payable(0x486A72846547268B3A9BbDdb7C5B75D92eE66f67); 

    // Burn Wallet
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // Token Info
    string private  constant _name = "GlobalReserveCoin";
    string private  constant _symbol = "GRC";
    uint256 private constant _decimals = 9;
    uint256 private constant _tTotal = 100_000_000_000 * 10 ** _decimals;

    // Project Links
    string private _Website;
    string private _Telegram;
    string private _LP_Lock;

    // Limits
    uint256 private max_Hold = _tTotal;
    uint256 private max_Tran = _tTotal;

    // Fees
    uint256 public _Fee__Buy_Gold;
    uint256 public _Fee__Buy_Liquidity;
    uint256 public _Fee__Buy_Marketing;
    uint256 public _Fee__Buy_Rewards;

    uint256 public _Fee__Sell_Gold;
    uint256 public _Fee__Sell_Liquidity;
    uint256 public _Fee__Sell_Marketing;
    uint256 public _Fee__Sell_Rewards;

    // Total Fee for Swap
    uint256 private _SwapFeeTotal_Buy;
    uint256 private _SwapFeeTotal_Sell;

    // Gas Amount
    uint256 distributorGas = 500000;

    // Factory
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;




    constructor () {

        // Set PancakeSwap Router Address

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);


        // Create Initial Pair With BNB
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // Create Reward Tracker Contract
        distributor = new DividendDistributor();

        // Set Initial LP Pair
        _isPair[uniswapV2Pair] = true;   

        // Wallets Excluded From Limits
        _isLimitExempt[address(this)] = true;
        _isLimitExempt[DEAD] = true;
        _isLimitExempt[uniswapV2Pair] = true;
        _isLimitExempt[_owner] = true;

        // Wallets With Pre-Launch Access
        _isWhitelisted[_owner] = true;

        // Wallets Excluded From Fees
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[DEAD] = true;
        _isExcludedFromFee[_owner] = true;

        // Wallets Excluded From Rewards
        _isExcludedFromRewards[uniswapV2Pair] = true;
        _isExcludedFromRewards[address(this)] = true;
        _isExcludedFromRewards[_owner] = true;
        _isExcludedFromRewards[DEAD] = true;

        // Transfer Supply To Owner
        _tOwned[_owner] = _tTotal;

        // Emit token transfer to owner
        emit Transfer(address(0), _owner, _tTotal);

        // Emit Ownership Transfer
        emit OwnershipTransferred(address(0), _owner);

    }

    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event updated_Wallet_Limits(uint256 max_Tran, uint256 max_Hold);
    event updated_Buy_fees(uint256 Marketing, uint256 Liquidity, uint256 Rewards, uint256 Gold);
    event updated_Sell_fees(uint256 Marketing, uint256 Liquidity, uint256 Rewards, uint256 Gold);
    event updated_SwapAndLiquify_Enabled(bool Swap_and_Liquify_Enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);


    // Restrict Function to Current Owner
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    // Mappings
    mapping (address => uint256) private _tOwned;                               // Tokens Owned
    mapping (address => mapping (address => uint256)) private _allowances;      // Allowance to spend another wallets tokens
    mapping (address => bool) public _isExcludedFromFee;                        // Wallets that do not pay fees
    mapping (address => bool) public _isLimitExempt;                            // Wallets that are excluded from HOLD and TRANSFER limits
    mapping (address => bool) public _isPair;                                   // Address is liquidity pair
    mapping (address => bool) public _isWhitelisted;                            // Pre-Launch Access
    mapping (address => bool) public _isExcludedFromRewards;                    // Excluded from Rewards
    mapping (address => bool) public _isExcludedFromProcess;                    // Excluded from triggering reward processing (Used during airdrops!)

    // Set Distributor
    DividendDistributor public distributor;


    // Public Token Info
    function Token_Information() external view returns(address Owner_Wallet,
                                                       uint256 Transaction_Limit,
                                                       uint256 Max_Wallet,
                                                       uint256 Fee_When_Buying,
                                                       uint256 Fee_When_Selling,
                                                       string memory Website,
                                                       string memory Telegram,
                                                       string memory Liquidity_Lock,
                                                       string memory Contract_Created_By) {

                                                           
        string memory Creator = "https://tokensbygen.com";

        uint256 Total_buy =  _Fee__Buy_Gold         +
                             _Fee__Buy_Liquidity    +
                             _Fee__Buy_Marketing    +
                             _Fee__Buy_Rewards      ;

        uint256 Total_sell = _Fee__Sell_Gold        +   
                             _Fee__Sell_Liquidity   +
                             _Fee__Sell_Marketing   +
                             _Fee__Sell_Rewards     ;


        uint256 _max_Hold = max_Hold / 10 ** _decimals;
        uint256 _max_Tran = max_Tran / 10 ** _decimals;

        if (_max_Tran > _max_Hold) {

            _max_Tran = _max_Hold;
        }


        // Return Token Data
        return (_owner,
                _max_Tran,
                _max_Hold,
                Total_buy,
                Total_sell,
                _Website,
                _Telegram,
                _LP_Lock,
                Creator);

    }
    


    // Number of tokens in common wallet percentages - Used for setting max wallet and transaction limits
    function Token_Wallet_Percents() external pure returns(uint256 Total_Supply,
                                                           uint256 Half_of_a_Percent,
                                                           uint256 One_Percent,
                                                           uint256 One_and_a_Half_Percent,
                                                           uint256 Two_Percent,
                                                           uint256 Two_and_a_Half_Percent,
                                                           uint256 Three_Percent) {

   
        uint256 TokenSupply = _tTotal / 10 ** _decimals;
        uint256 halfPrecent = TokenSupply / 200;

        // Return Token Data
        return (TokenSupply,
                halfPrecent,
                TokenSupply / 100,
                TokenSupply / 100 + halfPrecent,
                TokenSupply / 50,
                TokenSupply / 50 + halfPrecent,
                TokenSupply / 100 * 3);

    }
    



    // Fee Processing Triggers
    uint256 private swapTrigger = 11;  
    uint256 private swapCounter = 1;    
    
    // SwapAndLiquify Switch                  
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled; 

    // Launch Settings
    bool private Trade_Open;
    bool private No_Fee_Transfers = true;

    // Fee Tracker
    bool private takeFee;




    /*
    
    -----------------
    BUY AND SELL FEES
    -----------------

    */


    // Buy Fees
    function Contract_SetUp_01__Fees_on_Buy(

        uint256 Marketing_on_BUY,
        uint256 Gold_on_BUY,
        uint256 Liquidity_on_BUY, 
        uint256 Rewards_on_BUY

        ) external onlyOwner {

        // Buyer Protection: Max Fee 12%
        require (Marketing_on_BUY    +
                 Gold_on_BUY         +
                 Liquidity_on_BUY    + 
                 Rewards_on_BUY      <= 12, "E01"); // Buy fees are limited to 12%

        // Update Fees
        _Fee__Buy_Marketing  = Marketing_on_BUY;
        _Fee__Buy_Gold       = Gold_on_BUY;
        _Fee__Buy_Liquidity  = Liquidity_on_BUY;
        _Fee__Buy_Rewards    = Rewards_on_BUY;

        // Fees For Processing
        _SwapFeeTotal_Buy    = _Fee__Buy_Marketing + _Fee__Buy_Liquidity + _Fee__Buy_Rewards + _Fee__Buy_Gold;
        emit updated_Buy_fees(_Fee__Buy_Marketing, _Fee__Buy_Liquidity, _Fee__Buy_Rewards, _Fee__Buy_Gold);
    }

    // Sell Fees
    function Contract_SetUp_02__Fees_on_Sell(

        uint256 Marketing_on_SELL,
        uint256 Gold_on_SELL,
        uint256 Liquidity_on_SELL, 
        uint256 Rewards_on_SELL

        ) external onlyOwner {

        // Seller Protection: Max Fee 12% 
        require (Marketing_on_SELL  +
                 Gold_on_SELL       +
                 Liquidity_on_SELL  + 
                 Rewards_on_SELL    <= 12, "E02");  // Sell fees are limited to 12%

        // Update Fees
        _Fee__Sell_Marketing  = Marketing_on_SELL;
        _Fee__Sell_Gold       = Gold_on_SELL;
        _Fee__Sell_Liquidity  = Liquidity_on_SELL;
        _Fee__Sell_Rewards    = Rewards_on_SELL;


        // Fees For Processing
        _SwapFeeTotal_Sell    = _Fee__Sell_Marketing + _Fee__Sell_Liquidity + _Fee__Sell_Rewards + _Fee__Sell_Gold;
        emit updated_Sell_fees(_Fee__Sell_Marketing, _Fee__Sell_Liquidity, _Fee__Sell_Rewards,  _Fee__Sell_Gold);
    }


    /*
    
    ------------------------------------------
    SET MAX TRANSACTION AND MAX HOLDING LIMITS
    ------------------------------------------

    To protect buyers, these values must be set to a minimum of 0.5% of the total supply

    Wallet limits are set as a number of tokens, not as a percent of supply!
    Check the BSCScan READ page and copy / paste token amounts to avoid errors

    */

    function Contract_SetUp_03__Wallet_Limits(

        uint256 Max_Tokens_Each_Transaction,
        uint256 Max_Total_Tokens_Per_Wallet 

        ) external onlyOwner {

            require(Max_Tokens_Each_Transaction >= 500000000, "E03"); // Max Transaction must be greater than 0.5% of supply
            require(Max_Total_Tokens_Per_Wallet >= 500000000, "E04"); // Max Wallet must be greater than 0.5% of supply

            max_Tran = Max_Tokens_Each_Transaction * 10**_decimals;
            max_Hold = Max_Total_Tokens_Per_Wallet * 10**_decimals;

            emit updated_Wallet_Limits(max_Tran, max_Hold);

    }


    // Open Trade
    function Contract_SetUp_04__Open_Trade() external onlyOwner {

        // Can Only Use Once!
        require(!Trade_Open);

        swapAndLiquifyEnabled = true;
        Trade_Open = true;

    }




    /*
    
    ---------------------------------
    No FEE WALLET TO WALLET TRANSFERS
    ---------------------------------

    Default = true

    Having no fee on wallet-to-wallet transfers means that people can move tokens between wallets, 
    or send them to friends etc without incurring a fee. 

    If false, the 'Buy' fee will apply to all wallet to wallet transfers.

    */

    function No_Fee_Wallet_Transfers(bool true_or_false) public onlyOwner {

        No_Fee_Transfers = true_or_false;

    }




    /*

    -------------
    REWARD TOKENS
    -------------

    */

    function Rewards__Exclude_From_Rewards(address Wallet_Address, bool true_or_false) external onlyOwner {

        require(Wallet_Address != address(this) && Wallet_Address != uniswapV2Pair);
        _isExcludedFromRewards[Wallet_Address] = true_or_false;

        if(true_or_false){

            distributor.setShare(Wallet_Address, 0);

            } else {

            distributor.setShare(Wallet_Address, _tOwned[Wallet_Address]);
        }
    }

    /*


        IMPORTANT: Remember the Decimals - BUSD has 18 decimals!
        100000000000000000 (17 zeroes) = $0.10

    */

    function Rewards__Distribution_Triggers(uint256 Minutes_Between_Payments, uint256 Required_Reward_Balance) external onlyOwner {

        // Max Wait is 2 Days
        require(Minutes_Between_Payments <= 2880,"E05"); // Can not set wait time to longer than 2 days!

        // Convert minutes to seconds
        uint256 _minPeriod = Minutes_Between_Payments * 60;

        distributor.setDistributionCriteria(_minPeriod, Required_Reward_Balance);

    }


    function Rewards__Set_Gas(uint256 Gas_Amount) external onlyOwner {

        require(Gas_Amount < 750000);
        distributorGas = Gas_Amount;

    }
    

    /*

    ----------------------
    UPDATE PROJECT WALLETS
    ----------------------

    */


    function Update_Wallet_Gold(

        address payable Gold_Wallet

        ) external onlyOwner {

        // Update Gold Fee Wallet
        require(Gold_Wallet != address(0), "E06"); // Enter a valid BSC Address
        Wallet_Gold = payable(Gold_Wallet);
        
    }

    function Update_Wallet_Liquidity(

        address Liquidity_Collection_Wallet

        ) external onlyOwner {

        // Update LP Collection Wallet
        require(Liquidity_Collection_Wallet != address(0), "E07"); // Enter a valid BSC Address
        Wallet_Liquidity = Liquidity_Collection_Wallet;

    }

    function Update_Wallet_Marketing(

        address payable Marketing_Wallet

        ) external onlyOwner {

        // Update Marketing Fee Wallet
        require(Marketing_Wallet != address(0), "E08"); // Enter a valid BSC Address
        Wallet_Marketing = payable(Marketing_Wallet);

    }

    /*

    --------------------
    UPDATE PROJECT LINKS
    --------------------

    */

    function Update_Links_Website(

        string memory Website_URL

        ) external onlyOwner{

        _Website = Website_URL;

    }


    function Update_Links_Telegram(

        string memory Telegram_URL

        ) external onlyOwner{

        _Telegram = Telegram_URL;

    }


    function Update_Links_Liquidity_Lock(

        string memory LP_Lock_URL

        ) external onlyOwner{

        _LP_Lock = LP_Lock_URL;

    }


 
    /*
    
    ----------------------
    ADD NEW LIQUIDITY PAIR
    ----------------------

    */

    // Add Liquidity Pair
    function Maintenance__Add_Liquidity_Pair(

        address Wallet_Address,
        bool true_or_false)

         external onlyOwner {
        _isPair[Wallet_Address] = true_or_false;
        _isLimitExempt[Wallet_Address] = true_or_false;
    } 



    /* 

    ----------------------------
    CONTRACT OWNERSHIP FUNCTIONS
    ----------------------------

    */


    // Transfer to New Owner
    function Ownership_TRANSFER(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "E09"); // Enter a valid BSC Address

        emit OwnershipTransferred(_owner, newOwner);

        // Remove old owner status 
        _isLimitExempt[owner()]     = false;
        _isExcludedFromFee[owner()] = false;
        _isWhitelisted[owner()]     = false;

        _owner = newOwner;

        // Add new owner status
        _isLimitExempt[owner()]     = true;
        _isExcludedFromFee[owner()] = true;
        _isWhitelisted[owner()]     = true;

    }

  
    // Renounce Ownership
    function Ownership_RENOUNCE() public virtual onlyOwner {

        emit OwnershipTransferred(_owner, address(0));

        // Remove old owner status 
        _isLimitExempt[owner()]     = false;
        _isExcludedFromFee[owner()] = false;
        _isWhitelisted[owner()]     = false;

        _owner = address(0);
    }




    /*

    --------------
    FEE PROCESSING
    --------------

    */


    // Auto Fee Processing Switch
    function Process__Auto(bool true_or_false) external onlyOwner {
        swapAndLiquifyEnabled = true_or_false;
        emit updated_SwapAndLiquify_Enabled(true_or_false);
    }

    // Manually Process Fees
    function Process__Manual(uint256 Percent_of_Tokens_to_Process) external onlyOwner {
        require(!inSwapAndLiquify, "E10"); // Already processing fees!
        if (Percent_of_Tokens_to_Process > 100){Percent_of_Tokens_to_Process == 100;}
        uint256 tokensOnContract = balanceOf(address(this));
        uint256 sendTokens = tokensOnContract * Percent_of_Tokens_to_Process / 100;
        swapAndLiquify(sendTokens);

    }

    // Remove Random Tokens - number_of_Tokens must include the decimals too!
    function Process__Rescue_Tokens(

        address random_Token_Address,
        uint256 number_of_Tokens

        ) external onlyOwner {

            // Can Not Remove Native Token
            require (random_Token_Address != address(this), "E11"); // Can not purge the native token - Must be processed as fees!
            IERC20(random_Token_Address).transfer(msg.sender, number_of_Tokens);
            
    }

    // Update Swap Count Trigger
    function Process__Trigger_Count(uint256 Transaction_Count) external onlyOwner {

        // To Save Gas, Start At 1 Not 0
        swapTrigger = Transaction_Count + 1;
    }




    /*

    ---------------
    WALLET SETTINGS
    ---------------

    */


    // Exclude From Fees
    function Wallet__Exclude_From_Fees(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {
        _isExcludedFromFee[Wallet_Address] = true_or_false;

    }

    // When the 'from' wallet is excluded from processing token transfers will not trigger reward contract processing
    function Wallet__Exclude_From_Processing(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {
        _isExcludedFromProcess[Wallet_Address] = true_or_false;

    }

    // Exclude From Transaction and Holding Limits
    function Wallet__Exempt_From_Limits(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {  
        _isLimitExempt[Wallet_Address] = true_or_false;
    }

    // Grant Pre-Launch Access (Whitelist)
    function Wallet__Pre_Launch_Access(

        address Wallet_Address,
        bool true_or_false

        ) external onlyOwner {    
        _isWhitelisted[Wallet_Address] = true_or_false;
    }


    

  




    /*

    -----------------------------
    BEP20 STANDARD AND COMPLIANCE
    -----------------------------

    */

    function owner() public view returns (address) {
        return _owner;
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "Decreased allowance below zero"));
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "Allowance exceeded"));
        return true;
    }

    function send_BNB(address _to, uint256 _amount) internal returns (bool SendSuccess) {
        (SendSuccess,) = payable(_to).call{value: _amount}("");
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - balanceOf(address(DEAD)));
    }






   


    /*

    ---------------
    TOKEN TRANSFERS
    ---------------

    */

    function _transfer(
        address from,
        address to,
        uint256 amount
      ) private {



        require(balanceOf(from) >= amount, "E12"); // Sender does not have enough tokens!

        if (!Trade_Open){
        require(_isWhitelisted[from] || _isWhitelisted[to], "E13"); // Trade is not open - Only whitelisted wallets can interact with tokens
        }

        // Wallet Limit
        if (!_isLimitExempt[to]) {

            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= max_Hold, "E14"); // Purchase would take balance of max permitted
            
        }

        // Transaction limit - To send over the transaction limit the sender AND the recipient must be limit exempt
        if (!_isLimitExempt[to] || !_isLimitExempt[from]) {

            require(amount <= max_Tran, "E15"); // Exceeds max permitted transaction amount
        
        }


        // Compliance and Safety Checks
        require(from != address(0), "E16"); // Enter a valid BSC Address
        require(to != address(0), "E17"); // Enter a valid BSC Address
        require(amount > 0, "E18"); // Amount of tokens can not be 0


        // Trigger Fee Processing
        if (_isPair[to] && !inSwapAndLiquify && swapAndLiquifyEnabled) {

            // Check Transaction Count
            if(swapCounter >= swapTrigger){

                // Check Contract Tokens
                uint256 contractTokens = balanceOf(address(this));

                if (contractTokens > 0) {

                    // Limit Swap to Max Transaction
                    if (contractTokens <= max_Tran) {

                        swapAndLiquify (contractTokens);

                        } else {

                        swapAndLiquify (max_Tran);

                    }
                }
            }  
        }


        // Check Fee Status
        if(!takeFee){
            
            takeFee = true;
        }

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to] || (No_Fee_Transfers && !_isPair[to] && !_isPair[from])){
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);


        

        // Distribute Rewards
        if(!_isExcludedFromRewards[from]) {
            try distributor.setShare(from, _tOwned[from]) {} catch {}
        }

        if(!_isExcludedFromRewards[to]) {
            try distributor.setShare(to, _tOwned[to]) {} catch {} 
        }

        if(!_isExcludedFromProcess[from]) {
            try distributor.process(distributorGas) {} catch {}
        }



    }


    /*
    
    ------------
    PROCESS FEES
    ------------

    */

    function swapAndLiquify(uint256 Tokens) private {

        // Lock Swap
        inSwapAndLiquify        = true;  

        // Calculate Tokens for Swap
        uint256 _FeesTotal      = _SwapFeeTotal_Buy + _SwapFeeTotal_Sell;
        uint256 LP_Tokens       = Tokens * (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity) / _FeesTotal / 2;
        uint256 Swap_Tokens     = Tokens - LP_Tokens;

        // Swap Tokens
        uint256 contract_BNB    = address(this).balance;
        swapTokensForBNB(Swap_Tokens);
        uint256 returned_BNB    = address(this).balance - contract_BNB;

        // Avoid Rounding Errors on LP Fee if Odd Number
        uint256 fee_Split       = _FeesTotal * 2 - (_Fee__Buy_Liquidity + _Fee__Sell_Liquidity);

        // Calculate BNB Values
        uint256 BNB_Liquidity   = returned_BNB * (_Fee__Buy_Liquidity   + _Fee__Sell_Liquidity)       / fee_Split;
        uint256 BNB_Rewards     = returned_BNB * (_Fee__Buy_Rewards     + _Fee__Sell_Rewards)     * 2 / fee_Split; 
        uint256 BNB_GOLD        = returned_BNB * (_Fee__Buy_Gold        + _Fee__Sell_Gold)        * 2 / fee_Split; 

        // Add Liquidity 
        if (BNB_Liquidity > 0){
            addLiquidity(LP_Tokens, BNB_Liquidity);
            emit SwapAndLiquify(LP_Tokens, BNB_Liquidity, LP_Tokens);
        }

        // Deposit Rewards
        if(BNB_Rewards > 0){

            try distributor.deposit{value: BNB_Rewards}() {} catch {}

        }

        // Deposit Gold 
        if (BNB_GOLD > 0){

            send_BNB(Wallet_Gold, BNB_GOLD);
        }

        
        // Deposit Marketing
        contract_BNB = address(this).balance;

        if (contract_BNB > 0){

            send_BNB(Wallet_Marketing, contract_BNB);
        }


        // Reset Counter
        swapCounter = 1;

        // Unlock Swap
        inSwapAndLiquify = false;


    }

    // Swap Tokens
    function swapTokensForBNB(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(this),
            block.timestamp
        );
    }



    // Add Liquidity
    function addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, 
            0,
            Wallet_Liquidity, 
            block.timestamp
        );
    } 



    /*
    
    ----------------------------------
    TRANSFER TOKENS AND CALCULATE FEES
    ----------------------------------

    */

    uint256 private tSwapFeeTotal;
    uint256 private tTransferAmount;

    

    // Transfer Tokens and Calculate Fees
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool Fee) private {

        
        if (Fee){

            if(_isPair[recipient]){

                // Sell Fees
                tSwapFeeTotal   = tAmount * _SwapFeeTotal_Sell / 100;

            } else {

                // Buy Fees
                tSwapFeeTotal   = tAmount * _SwapFeeTotal_Buy / 100;

            }

        } else {

                // No Fees
                tSwapFeeTotal   = 0;

        }

        tTransferAmount = tAmount - tSwapFeeTotal;

        // Remove Tokens from Sender
        _tOwned[sender] -= tAmount;

        // Send tokens to recipient
        _tOwned[recipient] += tTransferAmount;

        emit Transfer(sender, recipient, tTransferAmount);

        // Take Fees for BNB Processing
        if(tSwapFeeTotal > 0){

            _tOwned[address(this)] += tSwapFeeTotal;

            // Increase Transaction Counter
            if (swapCounter < swapTrigger){
                swapCounter++;
            }
                
        }

    }

    // This function is required so that the contract can receive BNB during fee processing
    receive() external payable {}

}

// Custom contract by GEN https://TokensByGEN.com TG: https://t.me/GenTokens_GEN
// Not open source - Can not be used or forked without permission.