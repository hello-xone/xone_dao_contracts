// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

interface IxXOC {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract DAOLock is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    enum LockType {
        CANDIDATE,
        VOTE
    }

    struct LockInfo{
        address user; // User who locked the xXOC
        address candidate; // Candidate address (if applicable)
        LockType lockType; // Type of lock (CANDIDATE or VOTE)
        uint256 amount; // Amount of xXOC staked
        uint256 candidateLockIndex; // Index of the candidate lock if this is a vote lock
        bool freeze; // Whether the lock is unlocked
        uint256 term; // Term of the lock
    }

    struct  UnlockInfo {
        uint256 sourceLockIndex; // Index of the lock from which xXOC is unlocked
        address user; // User who locked the xXOC
        uint256 unlockTime; // Time when the xXOC can be unlocked
        uint256 unlockedAmount; // Amount of xXOC already unlocked
    }

    uint256 public minVoteAmount; // Minimum amount to vote for a candidate
    uint256 public unlockDuration;
    uint256 public candidateMinLockAmount; // Minimum amount to become a candidate

    // Contract state
    IxXOC public xXOCToken;
    
    LockInfo[] public locks; // All locks in the contract
    mapping (address => uint256[]) public userLocks; // User-specific locks

    mapping (uint256 => uint256[]) public candidateLocks; // Candidate-specific locks

    UnlockInfo[] public unlocks; // All unlocks in the contract
    mapping (address => uint256[]) public userUnlocks; // User-specific unlocks

    uint256 public currentTerm; // Current term of the DAO
    mapping (address => mapping(uint256 => bool)) public locked; // User address => term => locked

    event CandidateRegistered(
        address indexed candidate,
        uint256 lockIndex,
        string name,
        string instructions,
        uint256 amount
    );
    event CandidateVoted(
        address indexed voter,
        uint256 indexed candidateLockIndex,
        uint256 lockIndex,
        uint256 amount
    );
    event Unlock(
        address indexed user,
        uint256 indexed lockIndex,
        uint256 indexed unlockIndex,
        uint256 unlockTime,
        uint256 amount
    );
    event Withdrawn(
        address indexed user,
        uint256 indexed unlockIndex,
        uint256 amount
    );

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner{}

    function setMinVoteAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Minimum vote amount must be positive");
        minVoteAmount = newAmount;
    }

    // Only owner can update unlock duration
    function setUnlockDuration(uint256 newDuration) external onlyOwner {
        require(newDuration > 0, "Duration must be positive");
        unlockDuration = newDuration;
    }

    // Only owner can update candidate minimum lock amount
    function setCandidateMinLockAmount(uint256 newAmount) external onlyOwner {
        require(newAmount > 0, "Minimum lock amount must be positive");
        candidateMinLockAmount = newAmount;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _xXOCToken) public initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();

        xXOCToken = IxXOC(_xXOCToken);

        minVoteAmount = 1 * 10 ** 18; // 1 xXOC
        unlockDuration = 3 days;
        candidateMinLockAmount = 200_0000 * 10 ** 18; 
    }

    function becomeCandidate(
        string calldata name,
        string calldata instructions,
        uint256 xXOCAmount
    ) external{
        require(xXOCAmount >= candidateMinLockAmount, "xXOCAmount must be greater than or equal to CANDIDATE_MIN_LOCK_AMOUNT");

        require(xXOCToken.transferFrom(_msgSender(), address(this), xXOCAmount),
            "Transfer of xXOC failed"
        );

        require(locked[_msgSender()][currentTerm] == false, "is candidate");
        locked[_msgSender()][currentTerm] = true;

        LockInfo memory lockInfo = LockInfo(
            _msgSender(),
            _msgSender(),
            LockType.CANDIDATE, // Lock type is CANDIDATE
            xXOCAmount,
            0,
            false,
            currentTerm
        );

        uint256 lockIndex = locks.length;

        locks.push(lockInfo);
        userLocks[_msgSender()].push(lockIndex);


        emit CandidateRegistered( _msgSender(), lockIndex, name, instructions,  xXOCAmount);
    }

    function voteForCandidate(
        uint256 xXOCAmount,
        uint256 candidateLockIndex
    ) external{
        require(xXOCAmount > 0, "Cannot lock 0 xXOC");

        require(xXOCToken.transferFrom(_msgSender(), address(this), xXOCAmount),
            "Transfer of xXOC failed"
        );

        LockInfo storage candidateLockInfo = locks[candidateLockIndex];
        require(candidateLockInfo.candidate != address(0), "Invalid candidate address");
        require(candidateLockInfo.lockType == LockType.CANDIDATE, "Not a candidate lock");
        require(candidateLockInfo.amount >= candidateMinLockAmount, "Invalid candidate");

        LockInfo memory lockInfo = LockInfo(
            _msgSender(),
            candidateLockInfo.candidate,
            LockType.VOTE, // Lock type is VOTE
            xXOCAmount,
            candidateLockIndex,
            false,
            currentTerm
        );

        uint256 lockIndex = locks.length;

        locks.push(lockInfo);
        userLocks[_msgSender()].push(lockIndex);

        candidateLocks[candidateLockIndex].push(lockIndex);

        emit CandidateVoted(_msgSender(), candidateLockIndex, lockIndex, xXOCAmount);
    }
    
    function unlockMultiple(
        uint256[] calldata lockIndexes,
        uint256 amount
    ) external{
        uint256 lockIndexLength = lockIndexes.length;
        for (uint256 i = 0; i < lockIndexLength; i++) {
            uint256 lockIndex = lockIndexes[i];
            LockInfo storage lockInfo = locks[lockIndex];

            uint256 unlockAmount = amount == 0 ? lockInfo.amount : amount;  
            unlockAmount = unlockAmount > lockInfo.amount ? lockInfo.amount : unlockAmount;

            unlock(lockIndex, unlockAmount);
        }
    }

    function unlock(
        uint256 lockIndex,
        uint256 amount
    ) public {
        LockInfo storage lockInfo = locks[lockIndex];

        require(lockInfo.freeze == false, "Lock is frozen");
        require(lockInfo.amount > 0, "Lock is not active");
        require(amount > 0 && amount <= lockInfo.amount, "Invalid unlock amount");
        require(lockInfo.user == _msgSender(), "Not lock owner");
    
        lockInfo.amount -= amount;
        
        // if lockType is VOTE and amount is 0
        if (lockInfo.lockType == LockType.VOTE && lockInfo.amount == 0) {
            _removeLockFromCandidate(lockInfo.candidateLockIndex, lockIndex);
        }
        
        uint256 unlockTime = block.timestamp + unlockDuration;
        UnlockInfo memory unlockInfo = UnlockInfo(
            lockIndex,
            _msgSender(),
            unlockTime,
            amount
        );
    
        uint256 unlockIndex = unlocks.length;
        unlocks.push(unlockInfo);
        userUnlocks[_msgSender()].push(unlockIndex);
    
        if (lockInfo.lockType == LockType.CANDIDATE) {
            require(lockInfo.amount == 0," Must unlock full amount for candidate lock");
            _unlockCandidateVotes(lockIndex);
            locked[_msgSender()][lockInfo.term] = false;
        }
    
        emit Unlock(_msgSender(), lockIndex, unlockIndex, unlockTime, amount);
    }
    
    function _removeLockFromCandidate(uint256 candidateLockIndex, uint256 lockIndex) internal {
        uint256[] storage _candidateLocks = candidateLocks[candidateLockIndex];
        uint256 candidateLockLength = _candidateLocks.length;
        for (uint256 i = 0; i < candidateLockLength; i++) {
            if (_candidateLocks[i] == lockIndex) {
                _candidateLocks[i] = _candidateLocks[_candidateLocks.length - 1];
                _candidateLocks.pop();
                break;
            }
        }
    }
    
    function _unlockCandidateVotes(uint256 candidateLockIndex) internal {
        uint256[] memory voteLocks = candidateLocks[candidateLockIndex];
        
        delete candidateLocks[candidateLockIndex];
        
        uint256 unlockTime = block.timestamp;
        uint256 voteLockLength = voteLocks.length;
        for (uint256 i = 0; i < voteLockLength; i++) {
            uint256 voteLockIndex = voteLocks[i];
            LockInfo storage voteLockInfo = locks[voteLockIndex];
            
            if (voteLockInfo.amount > 0) {
                uint256 voteAmount = voteLockInfo.amount;
                voteLockInfo.amount = 0;

                UnlockInfo memory unlockInfo = UnlockInfo(
                    voteLockIndex,
                    voteLockInfo.user,
                    unlockTime,
                    voteAmount
                );
                
                uint256 unlockIndex = unlocks.length;
                unlocks.push(unlockInfo);
                userUnlocks[voteLockInfo.user].push(unlockIndex);
                
                emit Unlock(voteLockInfo.user, voteLockIndex, unlockIndex, unlockTime, voteAmount);
            }
        }
    }

    function withdrawMultiple(
        uint256[] calldata unlockIndexes,
        uint256 amount
    ) external {
        uint256 unlockIndexLength = unlockIndexes.length;
        require(
            unlockIndexLength > 0,
            "Must specify at least one unlock index"
        );

        uint256 totalUnlocked = 0;
        for (uint256 i = 0; i < unlockIndexLength; i++) {
            uint256 unlockIndex = unlockIndexes[i];
            require(unlockIndex < unlocks.length, "Invalid unlock index");

            UnlockInfo storage unlockInfo = unlocks[unlockIndex];
            require(unlockInfo.user == _msgSender(), "Not unlock owner");

            uint256 unlockAmount = amount == 0 ? unlockInfo.unlockedAmount : amount - totalUnlocked;
            unlockAmount = unlockAmount > unlockInfo.unlockedAmount ? unlockInfo.unlockedAmount : unlockAmount;

            if (unlockAmount > 0){
                _withdraw(unlockIndex, unlockAmount);
                totalUnlocked += unlockAmount;
            }

            if (totalUnlocked >= amount && amount > 0){
                break;
            }
        }

        require(totalUnlocked > 0, "No xXOC to withdraw");
    }

    function _withdraw(
        uint256 unlockIndex,
        uint256 amount
    ) internal {
        UnlockInfo storage unlockInfo = unlocks[unlockIndex];

        require(block.timestamp >= unlockInfo.unlockTime, "Lock period not over");
        require(amount > 0 && amount <= unlockInfo.unlockedAmount, "Invalid withdraw amount");

        unlockInfo.unlockedAmount -= amount;

        xXOCToken.transferFrom(address(this), _msgSender(), amount);

        emit Withdrawn(_msgSender(), unlockIndex, amount);
    }

    function getUserLocksAmount(address user) external view returns (uint256) {
        uint256 totalAmount = 0;
        uint256 userLockLength = userLocks[user].length;
        for (uint256 i = 0; i < userLockLength; i++) {
            uint256 lockIndex = userLocks[user][i];
            totalAmount += locks[lockIndex].amount;
        }
        return totalAmount;
    }

    function transitionToNextTerm(
        uint256[] calldata freezeLockIndexes,
        uint256[] calldata unfreezeLockIndexes
    ) external onlyOwner{
        currentTerm = currentTerm + 1;

        uint256 freezeLockLength = freezeLockIndexes.length;
        if (freezeLockLength > 0 ) {
            for (uint256 i = 0; i < freezeLockLength; i++) {
                uint256 lockIndex = freezeLockIndexes[i];
                LockInfo storage lockInfo = locks[lockIndex];

                lockInfo.freeze = true;
            }
        }

        uint256 unfreezeLockLength = unfreezeLockIndexes.length;
        if (unfreezeLockLength > 0){
            for (uint256 i = 0; i < unfreezeLockLength; i++) {
                uint256 lockIndex = unfreezeLockIndexes[i];
                LockInfo storage lockInfo = locks[lockIndex];

                lockInfo.freeze = false;
            }
        }
    }
}