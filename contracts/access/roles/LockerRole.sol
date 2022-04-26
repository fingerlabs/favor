// SPDX-License-Identifier: NONE
pragma solidity ^0.5.0;

import '../../klaytn/access/Roles.sol';

contract LockerRole {
  using Roles for Roles.Role;

  Roles.Role private _lockers;

  event LockerAdded(address indexed account);
  event LockerRemoved(address indexed account);

  modifier onlyLocker() {
    require(
      isLocker(msg.sender),
      'LockerRole: caller does not have the Locker role'
    );
    _;
  }

  constructor() public {
    _addLocker(msg.sender);
  }

  function addLocker(address account) public onlyLocker {
    _addLocker(account);
  }

  function renounceLocker() public {
    _removeLocker(msg.sender);
  }

  function isLocker(address account) public view returns (bool) {
    return _lockers.has(account);
  }

  function _addLocker(address account) internal {
    _lockers.add(account);
    emit LockerAdded(account);
  }

  function _removeLocker(address account) internal {
    _lockers.remove(account);
    emit LockerRemoved(account);
  }
}
