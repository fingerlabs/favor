// SPDX-License-Identifier: NONE
pragma solidity ^0.5.0;

import './klaytn/token/KIP7/KIP7Burnable.sol';
import './klaytn/token/KIP7/KIP7Pausable.sol';
import './klaytn/token/KIP7/KIP7Metadata.sol';
import './token/KIP7/KIP7Lockable.sol';
import './klaytn/ownership/Ownable.sol';

contract Favor is KIP7Burnable, KIP7Pausable, KIP7Metadata, KIP7Lockable, Ownable {
  uint256 public constant FAVOR_SUPPLY_LIMIT = 3e8 ether; // 300,000,000

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimal
  ) public KIP7Metadata(name, symbol, decimal) KIP7Lockable() Ownable() {
    _mint(msg.sender, FAVOR_SUPPLY_LIMIT);
  }
}
