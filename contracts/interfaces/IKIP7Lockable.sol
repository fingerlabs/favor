// SPDX-License-Identifier: NONE
pragma solidity ^0.5.0;

/**
 * @title IKIP7Lockable
 * @dev KIP7 토큰의 락업 기능 추가를 위한 Lockable 인터페이스
 */
interface IKIP7Lockable {
  /**
   * @dev locked token structure
   */
  struct LockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

  /**
   * @dev Records data of all the tokens Locked
   */
  event Locked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount,
    uint256 _validity
  );

  /**
   * @dev Records data of all the tokens unlocked
   */
  event Unlocked(address indexed _of, bytes32 indexed _reason, uint256 _amount);

  /**
   * @dev Locks a specified amount of tokens against an address,
   *      for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be locked
   * @param _time Lock time in seconds
   */
  function lock(
    bytes32 _reason,
    uint256 _amount,
    uint256 _time
  ) external returns (bool);

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
  ) external returns (bool);

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
  ) external returns (bool[] memory resultArr);

  /**
   * @dev Returns tokens locked for a specified address for a
   *      specified reason
   *
   * @param _of The address whose tokens are locked
   * @param _reason The reason to query the lock tokens for
   */
  function tokensLocked(address _of, bytes32 _reason)
    external
    view
    returns (uint256 amount);

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
  ) external view returns (uint256 amount);

  /**
   * @dev Returns total tokens held by an address (locked + transferable)
   * @param _of The address to query the total balance of
   */
  function totalBalanceOf(address _of) external view returns (uint256 amount);

  /**
   * @dev Extends lock for a specified reason and time
   * @param _reason The reason to lock tokens
   * @param _time Lock extension time in seconds
   */
  function extendLock(bytes32 _reason, uint256 _time) external returns (bool);

  /**
   * @dev Increase number of tokens locked for a specified reason
   * @param _reason The reason to lock tokens
   * @param _amount Number of tokens to be increased
   */
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    external
    returns (bool);

  /**
   * @dev Returns unlockable tokens for a specified address for a specified reason
   * @param _of The address to query the the unlockable token count of
   * @param _reason The reason to query the unlockable tokens for
   */
  function tokensUnlockable(address _of, bytes32 _reason)
    external
    view
    returns (uint256 amount);

  /**
   * @dev Unlocks the unlockable tokens of a specified address
   * @param _of Address of user, claiming back unlockable tokens
   */
  function unlock(address _of) external returns (uint256 unlockableTokens);

  /**
   * @dev Gets the unlockable tokens of a specified address
   * @param _of The address to query the unlockable token count of
   */
  function getUnlockableTokens(address _of)
    external
    view
    returns (uint256 unlockableTokens);

  /**
   * @dev Gets the length of lock reason of a specified address
   * @param _of The address to query the length of lock reason
   */
  function getLockReasonLength(address _of)
    external
    view
    returns (uint256 length);
}
