// Ropsten - 0x9BF0dFC2C453c2bC44Eb1C4aDF4E702a635ff8d0

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
 
contract CommunityGamingStaking is Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    address[] public stakedAddresses;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
 
   /* ========== CONSTRUCTOR ========== */
 
   constructor(
       address _stakingToken,
       uint256 _rewardsDuration
   ) {
       stakingToken = IERC20(_stakingToken);
       rewardsDuration = _rewardsDuration;
   }
 
   /* ========== VIEWS ========== */
 
   function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
           rewardPerTokenStored +
               (((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return
           ((_balances[account] *
               (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
                   rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

 
   /* ========== MUTATIVE FUNCTIONS ========== */
 
   function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        stakedAddresses.push(msg.sender);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            stakingToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }
 
   /* ========== RESTRICTED FUNCTIONS ========== */
 
   /// @notice Calculates and sets the reward rate
   /// @param reward The amount of the reward which will be distributed during the entire period
   function notifyRewardAmount(uint256 reward) external onlyOwner updateReward(address(0)) {
       if (block.timestamp >= periodFinish) {
           rewardRate = reward / rewardsDuration;
       } else {
           uint256 remaining = periodFinish - block.timestamp;
           uint256 leftover = remaining * rewardRate;
           rewardRate = (reward + leftover) / rewardsDuration;
       }
 
       // Ensure the provided reward amount is not more than the balance in the contract.
       // This keeps the reward rate in the right range, preventing overflows due to
       // very high values of rewardRate in the earned and rewardsPerToken functions;
       // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
       uint balance = stakingToken.balanceOf(address(this));
       require(rewardRate <= balance / rewardsDuration, "Staking: Provided reward too high");
 
       lastUpdateTime = block.timestamp;
       periodFinish = block.timestamp + rewardsDuration;
       emit RewardAdded(reward);
   }
 
   function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
       require(
           block.timestamp > periodFinish,
           "Staking: Previous rewards period must be complete before changing the duration for the new period"
       );
       rewardsDuration = _rewardsDuration;
       emit RewardsDurationUpdated(rewardsDuration);
   }
 
   /* ========== MODIFIERS ========== */
 
   modifier updateReward(address account) {
       rewardPerTokenStored = rewardPerToken();
       lastUpdateTime = lastTimeRewardApplicable();
       if (account != address(0)) {
           rewards[account] = earned(account);
           userRewardPerTokenPaid[account] = rewardPerTokenStored;
       }
       _;
   }
 
   /* ========== EVENTS ========== */
 
   event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
 