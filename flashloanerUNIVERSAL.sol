pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./FlashLoanReceiverBase.sol";
import "./interfaces/IERC20.sol";
import "./libraries/Library.sol";
import './libraries/SafeMath.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IUniswapV2Pair.sol';

contract flash20 is FlashLoanReceiverBase {
    using SafeMath for uint;
    address[] private _path;
    address[] private _pairs;
    uint private amount;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }



    constructor(address addressesProvider) FlashLoanReceiverBase(addressesProvider) public {

    }

    function poehali(address[] calldata path, address[] calldata pairs) external {
    
    //requires

    if (path.length == 3){
            {
            (uint reserveIn1, uint reserveOut1) = UniswapV2Library.getReservesByPair(pairs[0], path[0], path[1]);
            (uint reserveIn2, uint reserveOut2) = UniswapV2Library.getReservesByPair(pairs[1], path[1], path[2]);
  
            require(
            reserveOut1*reserveOut2*846 > reserveIn1*reserveIn2*854 || reserveOut1*reserveOut2*854 < reserveIn1*reserveIn2*846,
            "i love tomatoes"
            );
                // below we calculate an exact amount for the double swap case 

                amount = (SafeMath.sqrt(reserveIn1*reserveIn2)*SafeMath.sqrt(reserveOut1*reserveOut2)*997/1000-reserveIn1*reserveIn2)/(reserveIn2+reserveOut1*997/1000);
            }
        }
        else if (path.length == 4){
            {
            (uint reserveIn1, uint reserveOut1) = UniswapV2Library.getReservesByPair(pairs[0], path[0], path[1]);
            (uint reserveIn2, uint reserveOut2) = UniswapV2Library.getReservesByPair(pairs[1], path[1], path[2]);   
            (uint reserveIn3, uint reserveOut3) = UniswapV2Library.getReservesByPair(pairs[2], path[2], path[3]);
            
            require(
            reserveOut1*reserveOut2*reserveOut3*802 > reserveIn1*reserveIn2*reserveIn3*811,
            "i dont love tomatoes"
            );

                amount = (SafeMath.sqrt(reserveIn2*reserveOut1)*SafeMath.sqrt(reserveIn3*reserveOut2*997/1000)*997/1000*SafeMath.sqrt(reserveOut3)/
                10**10*SafeMath.sqrt(reserveIn1) - reserveIn2*reserveIn3*SafeMath.sqrt(reserveIn1)/10**10*SafeMath.sqrt(reserveIn1)) / ((reserveIn3*reserveIn2 + reserveOut1*997/1000*(reserveIn3 + reserveOut2*997/1000))*997/1000/10**10);
            }
        }   
    
    // Save the path to use it in executeOperation
    _path = path;
    _pairs = pairs;
    
    uint[] memory modes = new uint[](1);
    modes[0] = 0;
    address[] memory assets = new address[](1);
    assets[0] = path[0];
    uint[] memory amounts = new uint[](1);
    amounts[0] = amount;

    LENDING_POOL.flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            bytes(""), // Empty params
            0 // Referral code doesn't matter
        );

    // Send all profit to this sender
    IERC20(path[0]).transfer(msg.sender, IERC20(path[0]).balanceOf(address(this)));

    }


       function executeOperation(
        address[] calldata assets,
        uint[] calldata amounts,
        uint[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external override
        returns (bool)
    {
        require(amounts[0] <= IERC20(assets[0]).balanceOf(address(this)), "FlashLoaner: Invalid balance");


        swapExactTokensForTokens(amounts[0],amounts[0],_path,_pairs,address(this),now+10 seconds);  

        // Approve the LendingPool contract allowance to *pull* the owed amount
        uint amountOwing = amounts[0].add(premiums[0]);
        IERC20(assets[0]).approve(address(LENDING_POOL), amountOwing);

        return true;

    }

    function _swap(uint[] memory amounts, address[] memory path, address[] memory pairs, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pairs[i+1] : _to;
            IUniswapV2Pair(pairs[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] memory path,
        address[] memory pairs,
        address to,
        uint deadline
    ) internal virtual returns (uint[] memory amounts) {
        amounts = UniswapV2Library.getAmountsOut(pairs, amountIn, path);
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        require(IERC20(path[0]).balanceOf(address(this)) >= amounts[0], 'wtf');
        IERC20(path[0]).transfer(pairs[0], IERC20(path[0]).balanceOf(address(this)));
        _swap(amounts, path, pairs, to);
    }

/// @dev Reverses address array in place
    function reverse(address[] memory a) internal returns (bool) {
        address t;
        for (uint i = 0; i < a.length / 2; i++) {
            t = a[i];
            a[i] = a[a.length - i - 1];
            a[a.length - i - 1] = t;
        }
        return true;
    }

}