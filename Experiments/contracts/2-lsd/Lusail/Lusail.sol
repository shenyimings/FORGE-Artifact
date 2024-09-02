// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable to, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = to.call{value: amount}("");
        require(success, "Address: unable to send value, to may have reverted");
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDEXFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IMainPair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed from, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed from,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed from,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IDEXRouter02 is IRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract Lusail is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private Free;          //Exclude from fee
    mapping(address => bool) public blackList;      //Blacklist address
    mapping(address => bool) private _isExcluded;   //Exclude from Reflection

    bool public isLaunch;
    uint256 public launchBlock;
    uint256 private killNum;

    address[] private _excluded;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000 * 10**5 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Lusail Stadium Coin";
    string private _symbol = "Lusail";
    uint8 private _decimals = 9;

    uint256 public ReflectionFee = 1;
    uint256 private preReflectionFee = ReflectionFee;

    uint256 public LiquidityFee = 1;
    uint256 private preLiquidityFee = LiquidityFee;

    uint256 public DevFee = 1;
    uint256 private prDevFee = DevFee;

    uint256 public MarketingFee = 1;
    uint256 private preMarketingFee = MarketingFee;

    uint256 public BurnFee = 1;
    uint256 private preBurnFee = BurnFee;

    uint256 public TotalTax = 5;

    IDEXRouter02 public immutable Router;
    address public immutable mainPair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    address public DevFeeWallet =
        address(0x791048222B2FdE68F7bE930E794E6fA2b9283285);
    address public MarketingFeeWallet =
        address(0x697C51A1DF3357546bEDD9C29B9c5bE73AB142Bd);
    address public BurnFeeWallet =
        address(0x000000000000000000000000000000000000dEaD);
    address public LiquidityWallet;
    

    uint256 public _maxTxAmount = 10000 * 10**5 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 2 * 10**5 * 10**9;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(address _addPoolWallet) public {
        _rOwned[_addPoolWallet] = _rTotal;
        IDEXRouter02 _Router = IDEXRouter02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );

        LiquidityWallet = _addPoolWallet;
        
        // Create a uniswap pair for this new token
        mainPair = IDEXFactory(_Router.factory()).createPair(
            address(this),
            _Router.WETH()
        );

        // set the rest of the contract variables
        Router = _Router;

        //exclude owner and this contract from fee
        Free[owner()] = true;
        Free[address(this)] = true;
        Free[DevFeeWallet] = true;
        Free[MarketingFeeWallet] = true;
        Free[BurnFeeWallet] = true;
        Free[_addPoolWallet] = true;

        emit Transfer(address(0), _addPoolWallet, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _transfer(from, to, amount);
        _approve(
            from,
            _msgSender(),
            _allowances[from][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }


    //This function makes the address can get reward from reflection again
    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address from,
        address to,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLP,
            uint256 tDev,
            uint256 tMarketing,
            uint256 tBurnFee
        ) = _getValues(tAmount);
        _tOwned[from] = _tOwned[from].sub(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _tOwned[to] = _tOwned[to].add(tTransferAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeLiquidity(from, tLP);
        _takeDev(from, tDev);
        _takeMarketing(from, tMarketing);
        _takeBurnFee(from, tBurnFee);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        Free[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        Free[account] = false;
    }

    function setFees(
        uint256 _ReflectionFee,
        uint256 _LiquidityFee,
        uint256 _DevFee,
        uint256 _MarketingFee,
        uint256 _BurnFee
    ) external onlyOwner {
        require(
            _ReflectionFee
                .add(_LiquidityFee)
                .add(_DevFee)
                .add(_MarketingFee)
                .add(_BurnFee) <= 15,
            "The summation of fees cannot be set higher than 15!!"
        );
        ReflectionFee = _ReflectionFee;
        LiquidityFee = _LiquidityFee;
        DevFee = _DevFee;
        MarketingFee = _MarketingFee;
        BurnFee = _BurnFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent >=1, "You cannot set lower!!");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to recieve ETH from Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256[6] memory data) = _getTValues(
            tAmount
        );
        data[0] = tAmount;
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            data,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            data[1],
            data[2],
            data[3],
            data[4],
            data[5]
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256[6] memory)
    {
        uint256 tFee = calculateReflectionFeeFee(tAmount);
        uint256 tLP = calculateLiquidityFeeeFee(tAmount);
        uint256 tDev = calculateDevFeeFee(tAmount);
        uint256 tMarketing = calculateMarketingFeeFee(tAmount);
        uint256 tBurnFee = calculateBurnFeeeFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLP).sub(tBurnFee);
        tTransferAmount = tTransferAmount.sub(tDev);
        tTransferAmount = tTransferAmount.sub(tMarketing);
        uint256[6] memory d = [0, tFee, tLP, tDev, tMarketing, tBurnFee];
        return (tTransferAmount, d);
    }

    function _getRValues(uint256[6] memory _data, uint256 currentRate)
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = _data[0].mul(currentRate);
        uint256 rFee = _data[1].mul(currentRate);
        uint256 rLP = _data[2].mul(currentRate);
        uint256 rDev = _data[3].mul(currentRate);
        uint256 rMarketing = _data[4].mul(currentRate);
        uint256 rBurnFee = _data[5].mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLP).sub(rBurnFee);
        rTransferAmount = rTransferAmount.sub(rDev);
        rTransferAmount = rTransferAmount.sub(rMarketing);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {

            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);

            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }

        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(address from, uint256 tLP) private {
        uint256 currentRate = _getRate();
        uint256 rLP = tLP.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLP);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLP);
            
        if (tLP > 0) {
            emit Transfer(from, address(this), tLP);
        }
    }

    function _takeDev(address from, uint256 tDev) private {
        uint256 currentRate = _getRate();
        uint256 rDev = tDev.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rDev);
        
        if (tDev > 0) {
            emit Transfer(from, address(this), tDev);
        }
    }

    function _takeBurnFee(address from, uint256 tBurnFee) private {
        uint256 currentRate = _getRate();
        uint256 rBurnFee = tBurnFee.mul(currentRate);
        _rOwned[BurnFeeWallet] = _rOwned[BurnFeeWallet].add(rBurnFee);

        if (tBurnFee > 0) {
            emit Transfer(from, BurnFeeWallet, tBurnFee);
        }
    }

    function _takeMarketing(address from, uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketing);
        
        if (tMarketing > 0) {
            emit Transfer(from, address(this), tMarketing);
        }
    }

    function calculateDevFeeFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(DevFee).div(10**2);
    }

    function calculateBurnFeeeFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(BurnFee).div(10**2);
    }

    function calculateMarketingFeeFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(MarketingFee).div(10**2);
    }

    function calculateReflectionFeeFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(ReflectionFee).div(10**2);
    }

    function calculateLiquidityFeeeFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(LiquidityFee).div(10**2);
    }

    function removeAllFee() private {
        if (
            ReflectionFee == 0 &&
            LiquidityFee == 0 &&
            DevFee == 0 &&
            MarketingFee == 0 &&
            BurnFee ==0
        ) return;

        preReflectionFee = ReflectionFee;
        preLiquidityFee = LiquidityFee;
        prDevFee = DevFee;
        preLiquidityFee = LiquidityFee;
        preBurnFee = BurnFee;

        ReflectionFee = 0;
        LiquidityFee = 0;
        DevFee = 0;
        MarketingFee = 0;
        BurnFee = 0;
    }

    function restoreAllFee() private {
        ReflectionFee = preReflectionFee;
        LiquidityFee = preLiquidityFee;
        DevFee = prDevFee;
        MarketingFee = preMarketingFee;
        BurnFee = preBurnFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return Free[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (!Free[from] && !Free[to]) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
            require(isLaunch, "You cannot tranfer before launch");
            require(!blackList[from], "You are blacklisted");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if from is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;

        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != mainPair &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to Free account then remove the fee
        if (Free[from] || Free[to]) {
            takeFee = false;
        } else {
            //Keep the address
            uint256 maxSell = balanceOf(from).mul(9999).div(10000);
            if (amount > maxSell) amount = maxSell;

            if (from == mainPair) {
                if (launchBlock + killNum > block.number) addBot(to);
            }
        }

        //transfer amount, it will take ReflectionFee, BurnFee, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function Launch() external onlyOwner {
        require(!isLaunch, "Already launched");
        isLaunch = true;
        launchBlock = block.number;
    }

    function setKillNum(uint256 killNumber) external onlyOwner {
        require(killNumber < 60);
        killNum = killNumber;
    }

    function addBot(address isBot) internal {
        blackList[isBot] = true;
    }

    function writeBlackList(address BotAddress, bool isBot) external onlyOwner {
        if (isBot == true)
            require(
                BotAddress != mainPair && BotAddress != address(this),
                "You cannot blacklist this address!!"
            );
        blackList[BotAddress] = isBot;
    }

    function transferToAddressETH(address payable recipient, uint256 amount)
        private
    {
        recipient.transfer(amount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // If LiquidityFee = 1, it's hard to calculate. Use the denominator to handle the situation
        uint256 denominator = (TotalTax.sub(BurnFee).sub(ReflectionFee)).mul(2);

        uint256 tokensForLP = contractTokenBalance.mul(LiquidityFee).div(
            denominator
        );

        uint256 tokensForSwap = contractTokenBalance.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);

        uint256 amountReceived = address(this).balance;

        uint256 totalBNBFee = denominator.sub(LiquidityFee);

        uint256 amountBNBLiquidity = amountReceived.mul(LiquidityFee).div(
            totalBNBFee
        );

        uint256 amountBNBMarketing = amountReceived
            .mul(MarketingFee.mul(2))
            .div(totalBNBFee);

        uint256 amountBNBDev = amountReceived.sub(amountBNBLiquidity).sub(
            amountBNBMarketing
        );

        if (amountBNBDev > 0)
            transferToAddressETH(payable(DevFeeWallet), amountBNBDev);

        if (amountBNBMarketing > 0)
            transferToAddressETH(
                payable(MarketingFeeWallet),
                amountBNBMarketing
            );

        if (amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = Router.WETH();

        _approve(address(this), address(Router), tokenAmount);

        // make the swap
        Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(Router), tokenAmount);

        // add the liquidity
        Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LiquidityWallet,
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address from,
        address to,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address from,
        address to,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLP,
            uint256 tDev,
            uint256 tMarketing,
            uint256 tBurnFee
        ) = _getValues(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeLiquidity(from, tLP);
        _takeDev(from, tDev);
        _takeMarketing(from, tMarketing);
        _takeBurnFee(from, tBurnFee);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
    }

    function _transferToExcluded(
        address from,
        address to,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLP,
            uint256 tDev,
            uint256 tMarketing,
            uint256 tBurnFee
        ) = _getValues(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _tOwned[to] = _tOwned[to].add(tTransferAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeLiquidity(from, tLP);
        _takeDev(from, tDev);
        _takeMarketing(from, tMarketing);
        _takeBurnFee(from, tBurnFee);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
    }

    function _transferFromExcluded(
        address from,
        address to,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLP,
            uint256 tDev,
            uint256 tMarketing,
            uint256 tBurnFee
        ) = _getValues(tAmount);
        _tOwned[from] = _tOwned[from].sub(tAmount);
        _rOwned[from] = _rOwned[from].sub(rAmount);
        _rOwned[to] = _rOwned[to].add(rTransferAmount);
        _takeLiquidity(from, tLP);
        _takeDev(from, tDev);
        _takeMarketing(from, tMarketing);
        _takeBurnFee(from, tBurnFee);
        _reflectFee(rFee, tFee);
        emit Transfer(from, to, tTransferAmount);
    }
}