// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.6;

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';
import './interfaces/IERC20.sol';
import './interfaces/IFlashLoanReceiver.sol';
import './interfaces/ILendingPoolAddressesProvider.sol';
import './interfaces/ILendingPool.sol';

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(address provider) public {
    ADDRESSES_PROVIDER = ILendingPoolAddressesProvider(provider);
    LENDING_POOL = ILendingPool(ILendingPoolAddressesProvider(provider).getLendingPool());
  }
}
