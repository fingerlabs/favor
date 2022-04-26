// SPDX-License-Identifier: NONE
pragma solidity ^0.5.0;

import '../../klaytn/token/KIP7/KIP7.sol';
import '../../klaytn/introspection/KIP13.sol';
import '../../interfaces/IKIP7Lockable.sol';
import '../../access/roles/LockerRole.sol';

/**
 * @dev 핑거랩스 코인 분배 시 락업 기간 설정을 위한 락업 기능을 제공하는 토큰 컨트랙트
 */
contract KIP7Lockable is KIP13, KIP7, LockerRole, IKIP7Lockable {
  /*
   *     bytes4(keccak256('lock(bytes32,uint256,uint256)')) == 0x2e82aaf2
   *     bytes4(keccak256('transferWithLock(address,bytes32,uint256,uint256)')) == 0x4cb5465f
   *     bytes4(keccak256('tokensLocked(address,bytes32)')) == 0x5ca48d8c
   *     bytes4(keccak256('tokensLockedAtTime(address,bytes32,uint256)')) == 0x179e91f1
   *     bytes4(keccak256('totalBalanceOf(address)')) == 0x4b0ee02a
   *     bytes4(keccak256('extendLock(bytes23,uint256)')) == 0x6b045400
   *     bytes4(keccak256('increaseLockAmount(bytes23,uint256)')) == 0xe38b4c1a
   *     bytes4(keccak256('tokensUnlockable(address,bytes32)')) == 0x5294d0e8
   *     bytes4(keccak256('unlock(address)')) == 0x2f6c493c
   *     bytes4(keccak256('getUnlockableTokens(address)')) == 0xab4a2eb3
   *
   *     => 0x2e82aaf2 ^ 0x4cb5465f ^ 0x5ca48d8c ^ 0x179e91f1 ^ 0x4b0ee02a ^ 0x6b045400 ^ 0xe38b4c1a ^ 0x5294d0e8 ^ 0x2f6c493c ^ 0xab4a2eb3 == 0x3c3ebf87
   */
  bytes4 private constant _INTERFACE_ID_KIP7LOCKABLE = 0x3c3ebf87;

  /**
   * @dev Error messages for require statements
   */
  string internal constant ALREADY_LOCKED = 'Tokens already locked';
  string internal constant NOT_LOCKED = 'No tokens locked';
  string internal constant AMOUNT_ZERO = 'Amount can not be 0';

  /**
   * @dev Reasons why a user's tokens have been locked
   */
  mapping(address => bytes32[]) public lockReason;

  /**
   * @dev Holds number & validity of tokens locked for a given reason for
   *      a specified address
   */
  mapping(address => mapping(bytes32 => LockToken)) public locked;

  constructor() public {
    // register the supported interfaces to conform to KIP17 via KIP13
    _registerInterface(_INTERFACE_ID_KIP7LOCKABLE);
  }

  /**
   * @dev Gets the length of lock reason of a specified address
   * @param _of The address to query the length of lock reason
   */
  function getLockReasonLength(address _of)
    external
    view
    returns (uint256 length)
  {
    length = lockReason[_of].length;
  }

  /**
   * @dev Locks a specified amount of tokens against an address,
   *      for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be locked
   * @param _time Specific lock time in seconds
   */
  function lock(
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) public onlyLocker returns (bool) {
    require(block.timestamp < _time, 'Lock time must be in the future'); //solhint-disable-line

    // If tokens are already locked, then functions extendLock or
    // increaseLockAmount should be used to make any changes
    require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[msg.sender][_reason].amount == 0)
      lockReason[msg.sender].push(_reason);

    transfer(address(this), _amount);

    locked[msg.sender][_reason] = LockToken(_amount, _time, false);

    emit Locked(msg.sender, _reason, _amount, _time);
    return true;
  }

  /**
   * @dev Transfers and Locks a specified amount of tokens,
   *      for a specified reason and time
   * @param _to adress to which tokens are to be transfered
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be transfered and locked
   * @param _time Specific time in seconds
   */
  function transferWithLock(
    address _to,
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) public onlyLocker returns (bool) {
    require(block.timestamp < _time, 'Lock time must be in the future'); //solhint-disable-line

    require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[_to][_reason].amount == 0) lockReason[_to].push(_reason);

    transfer(address(this), _amount);

    locked[_to][_reason] = LockToken(_amount, _time, false);

    emit Locked(_to, _reason, _amount, _time);
    return true;
  }

  /**
   * @dev batch transfer with lock
   * @param _toAddrArr[]
   * @param _reasonArr[]
   * @param _amountArr[]
   * @param _timeArr[]
   */
  function batchTransferWithLock(
    address[] calldata _toAddrArr,
    bytes32[] calldata _reasonArr,
    uint256[] calldata _amountArr,
    uint256[] calldata _timeArr
  ) external onlyLocker returns (bool[] memory) {
    require(_toAddrArr.length > 0, '_toAddrArr must not be empty');
    bool[] memory resultArr = new bool[](_toAddrArr.length);

    uint256 totalLength = resultArr.length;
    require(_reasonArr.length == totalLength, 'reason length does not match');
    require(_amountArr.length == totalLength, 'amount length does not match');
    require(_timeArr.length == totalLength, 'time length does not match');

    for (uint256 i = 0; i < _toAddrArr.length; i++) {
      bool result = transferWithLock(
        _toAddrArr[i],
        _reasonArr[i],
        _amountArr[i],
        _timeArr[i]
      );

      resultArr[i] = result;
    }

    return resultArr;
  }

  /**
   * @dev Extends lock for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _time Lock extension time in seconds
   */
  function extendLock(bytes32 _reason, uint256 _time)
    public
    onlyLocker
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

    locked[msg.sender][_reason].validity =
      locked[msg.sender][_reason].validity +
      _time;

    emit Locked(
      msg.sender,
      _reason,
      locked[msg.sender][_reason].amount,
      locked[msg.sender][_reason].validity
    );
    return true;
  }

  /**
   * @dev Increase number of tokens locked for a specified reason
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be increased
   */
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    public
    onlyLocker
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
    transfer(address(this), _amount);

    locked[msg.sender][_reason].amount =
      locked[msg.sender][_reason].amount +
      _amount;

    emit Locked(
      msg.sender,
      _reason,
      locked[msg.sender][_reason].amount,
      locked[msg.sender][_reason].validity
    );
    return true;
  }

  /**
   * @dev Unlocks the unlockable tokens of a specified address
   * @param _of Address of user, claiming back unlockable tokens
   */
  function unlock(address _of)
    public
    onlyLocker
    returns (uint256 unlockableTokens)
  {
    uint256 lockedTokens;

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens + lockedTokens;
        locked[_of][lockReason[_of][i]].claimed = true;
        emit Unlocked(_of, lockReason[_of][i], lockedTokens);
      }
    }

    if (unlockableTokens > 0) this.transfer(_of, unlockableTokens);
  }

  /**
   * @dev Returns tokens locked for a specified address for a
   *      specified reason
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   */
  function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed) amount = locked[_of][_reason].amount;
  }

  /**
   * @dev Returns tokens locked for a specified address for a
   *      specified reason at a specific time
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   * @param _time The timestamp to query the lock tokens for
   */
  function tokensLockedAtTime(
    address _of,
    bytes32 _reason,
    uint256 _time
  ) public view returns (uint256 amount) {
    if (locked[_of][_reason].validity > _time)
      amount = locked[_of][_reason].amount;
  }

  /**
   * @dev Returns total tokens held by an address (locked + transferable)
   * @param _of The address to query the total balance of
   */
  function totalBalanceOf(address _of) public view returns (uint256 amount) {
    amount = balanceOf(_of);

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount + tokensLocked(_of, lockReason[_of][i]);
    }
  }

  /**
   * @dev Returns unlockable tokens for a specified address for a specified reason
   * @param _of The address to query the the unlockable token count of
   * @param _reason The reason to query the unlockable tokens for
   */
  function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (
      locked[_of][_reason].validity <= block.timestamp && // solhint-disable-line
      !locked[_of][_reason].claimed
    )
      //solhint-disable-line
      amount = locked[_of][_reason].amount;
  }

  /**
   * @dev Gets the unlockable tokens of a specified address
   * @param _of The address to query the the unlockable token count of
   */
  function getUnlockableTokens(address _of)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens =
        unlockableTokens +
        tokensUnlockable(_of, lockReason[_of][i]);
    }
  }
}
