//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20{
    function transferFrom(address _from,address _to,uint256 _amount) external returns(bool);
    function transfer(address _to,uint256 _amount) external returns(bool);
    function symbol() external returns(string memory);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint256);
}

interface IERC721{
    function balanceOf(address account) external view returns (uint256);
    function symbol() external returns(string memory);
}

contract GatedStaker {
    // keeping staked amount and time only in record
    // earned royalties are calculated at point of withdrawal/topup

    struct Record {
        address stakedBy;
        bool isActive;
        uint128 stakedAt;
        uint256 amount;
    }

    enum ACTION {
        STAKE,
        WITHDRAW
    }

    event Alert(Record record, ACTION action);

    IERC721 public immutable gateToken;
    IERC20 public immutable stakeToken;
    uint8 public constant MPY = 10;
    uint64 public immutable minStake;
    uint256 private totalStakes;
    string public gateTokenName;
    mapping(address => Record) private records;


    constructor(
        address _gateTokenAddr,
        address _stakeTokenAddr,
        string memory _gateTokenName
    ) {
        gateToken = IERC721(_gateTokenAddr);
        stakeToken = IERC20(_stakeTokenAddr);
        gateTokenName = _gateTokenName;
        minStake = 1e10;
    }

    modifier hasGateToken() {
        require(
            gateToken.balanceOf(msg.sender) > 0,
            "account has no gateToken"
        );
        _;
    }

    modifier validStake(uint256 _amt) {
        require(_amt >= minStake, "Invalid Stake");
        _;
    }

    /**
     * Conditions:
     *  stake must be greater then minimum stake required
     *  autostaking used for multiple stakes
     *  account must have the gateToken
     */

    function stake(uint256 _amt) public validStake(_amt) hasGateToken returns (bool) {
        require(stakeToken.transferFrom(msg.sender, address(this), _amt), "Staking failed");

        uint256 _totalAmt = _amt;
        Record storage _record = records[msg.sender];

        // check that record exist for account, and update accordingly
        if (_record.isActive) {_totalAmt += _calculateYield(_record);}
        else {
            _record.stakedBy = msg.sender;
            _record.isActive = true;
        }

        _record.amount = _totalAmt;
        _record.stakedAt = uint128(block.timestamp);
        updateAndEmit(_record, ACTION.STAKE);
        return true;
    }

    /**
     * conditions:
     *    withdraws all staked fund for account
     */
    function withdraw() public returns (bool) {
        Record storage _record = records[msg.sender];
        require(_record.isActive, "No active record found");
        uint256 _yield = _calculateYield(_record);
        uint256 _totalReturns = _yield + _record.amount;

        // effect and record
        _record.isActive = false;
        require(
            stakeToken.transfer(msg.sender, _totalReturns),
            "Error Transfering"
        );

        updateAndEmit(_record, ACTION.WITHDRAW);
        return true;
    }

    // calculates and returns yield
    function _calculateYield(Record memory _record) internal view returns (uint256){
        uint256 _yield = 0;
        // cycle is 1 second long
        uint256 cycle = 1 seconds;
        uint256 minCycle = 3 days;

        uint256 _maturity = block.timestamp - _record.stakedAt;

        if (_maturity < minCycle) {
            return _yield;
        }

        uint256 _cycles = _maturity / cycle;
        _yield = (_cycles * MPY * _record.amount) / (100 * 30 * 86400); // yield earned to a second
        return _yield;
    }

    function updateAndEmit(Record storage _record, ACTION _action) internal {
        if (_action == ACTION.STAKE) {
            totalStakes += _record.amount;
        } else {
            totalStakes -= _record.amount;
        }
        emit Alert(_record, _action);
    }
}
