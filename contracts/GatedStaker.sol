//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GatedStaker {
    // keeping staked amount and time only in record
    // earned royalties are calculated at point of withdrawal/topup

    struct Record {
        address stakedBy;
        uint256 stakedAt;
        uint256 amount;
        bool isActive;
    }

    enum ACTION {STAKE, WITHDRAW}

    event Alert(Record record, ACTION action);

    string public gateTokenName;
    IERC721 public gateToken;
    IERC20 public stakeToken;

    mapping(address => Record) private records;
    uint256 private totalStakes;

    uint256 public minStake = 1000;
    // monthly-percentage-yield: a month is 30days
    uint256 public MPY = 10;

    constructor(
        string memory _gateTokenName,
        address _gateTokenAddr,
        address _stakeTokenAddr
    ) {
        gateTokenName = _gateTokenName;
        gateToken = IERC721(_gateTokenAddr);
        stakeToken = IERC20(_stakeTokenAddr);
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

    function stake(uint256 _amt) public validStake(_amt) hasGateToken returns (bool)
    {
        require(
            stakeToken.transferFrom(msg.sender, address(this), _amt),
            "Staking failed"
        );
        // Avoiding assigning to function parameter
        uint _totalAmt = _amt;
        Record storage _record = records[msg.sender];

        // check that record exist for account, and update accordingly
        if (_record.isActive){
            _totalAmt += calculateYield(_record);
        }
        else {
            _record.stakedBy = msg.sender;
            _record.isActive = true;
        }
        _record.amount = _totalAmt;
        _record.stakedAt = block.timestamp;
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
        uint256 _yield = calculateYield(_record);
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
    function calculateYield(Record memory _record) internal view returns (uint256)
    {
        uint256 _yield = 0;
        // cycle is 30days long
        uint256 cycle = 30 days;
        // uint256 minCycle = 3 days;

        uint256 _maturity = block.timestamp - _record.stakedAt;

        if (_maturity < 3 days || _maturity < cycle) {
            return _yield;
        }

        uint256 _months = _maturity / cycle;

        _yield = (_months * MPY * _record.amount) / 100;
        return _yield;
    }

    function updateAndEmit(Record _record, ACTION _action) internal view {
        if (_action==ACTION.STAKE){
            totalStakes += _record.amount;
        }
        else {
            totalStakes -= _record.amount;
        }
        emit Alert(_record, _action);
    }
}
