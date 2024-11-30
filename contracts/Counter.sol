// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract DecentralizedLearningContracts {
    struct LearningGoal {
        uint256 stakeAmount;
        uint256 deadline;
        bool isCompleted;
        bool isValidated;
        address validator;
    }

    mapping(address => LearningGoal) public learningGoals;

    address public admin;
    mapping(address => uint256) public balances;

    event GoalCreated(address indexed learner, uint256 stakeAmount, uint256 deadline);
    event GoalValidated(address indexed learner, address indexed validator, bool success);
    event RewardClaimed(address indexed learner, uint256 rewardAmount);
    event StakeForfeited(address indexed learner, uint256 forfeitedAmount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyValidator(address _learner) {
        require(learningGoals[_learner].validator == msg.sender, "Not assigned as validator");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    // Learner creates a goal by staking tokens
    function createLearningGoal(uint256 _stakeAmount, uint256 _deadline, address _validator) external payable {
        require(msg.value == _stakeAmount, "Stake amount must match sent value");
        require(_validator != address(0), "Validator address cannot be zero");
        require(_deadline > block.timestamp, "Deadline must be in the future");
        require(learningGoals[msg.sender].stakeAmount == 0, "Existing goal in progress");

        learningGoals[msg.sender] = LearningGoal({
            stakeAmount: _stakeAmount,
            deadline: _deadline,
            isCompleted: false,
            isValidated: false,
            validator: _validator
        });

        balances[address(this)] += _stakeAmount;
        emit GoalCreated(msg.sender, _stakeAmount, _deadline);
    }

    // Validator validates a learner's goal
    function validateLearningGoal(address _learner, bool _isSuccessful) external onlyValidator(_learner) {
        LearningGoal storage goal = learningGoals[_learner];
        require(!goal.isValidated, "Goal already validated");
        require(block.timestamp <= goal.deadline, "Goal deadline has passed");

        goal.isValidated = true;
        goal.isCompleted = _isSuccessful;

        if (_isSuccessful) {
            uint256 reward = goal.stakeAmount;
            balances[address(this)] -= reward;
            balances[_learner] += reward;
            emit GoalValidated(_learner, msg.sender, true);
        } else {
            uint256 forfeited = goal.stakeAmount;
            balances[address(this)] -= forfeited;
            balances[admin] += forfeited;
            emit StakeForfeited(_learner, forfeited);
        }
    }

    // Learner claims their reward
    function claimReward() external {
        uint256 reward = balances[msg.sender];
        require(reward > 0, "No reward to claim");

        balances[msg.sender] = 0;
        (bool sent, ) = msg.sender.call{value: reward}("");
        require(sent, "Failed to send reward");

        emit RewardClaimed(msg.sender, reward);
    }

    // Admin withdraws accumulated forfeited stakes
    function adminWithdraw(uint256 _amount) external onlyAdmin {
        require(balances[admin] >= _amount, "Insufficient admin balance");

        balances[admin] -= _amount;
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to withdraw");

        // No event necessary for admin withdrawals for simplicity
    }

    // Fallback to accept Ether deposits
    receive() external payable {}
}

