//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staker {
    // keeping staked amount and time only in record
    // earned royalties are calculated at point of withdrawal
    // ???and record is destroyed???
    struct Record {
        address stakedBy;
        uint256 stakedAt;
        uint256 amount;
    }

    // BOREDAPES NFT: 0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d
    string public gateTokenName;
    IERC721 public gateToken;
    IERC20 public stakeToken;
    mapping(address => Record) private records;
    uint256 private totalStakes;
    uint256 public minStake = 1000;
    // monthly-percentage-yield
    uint256 MPY = 10;

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
            "caller have no gateToken"
        );
        _;
    }

    modifier hasNoStake() {
        require(records[msg.sender].amount == 0, "Has an active stake");
        _;
    }

    modifier hasStake() {
        require(records[msg.sender].amount >= 1, "Has no active stake");
        _;
    }

    modifier validStake(uint256 _amount) {
        require(_amount >= minStake, "Invalid Stake");
        _;
    }

    /**
     * Conditions:
     *  stake must be greater then minimum stake required
     *  Allowing one active stake per account
     *  account must have the gateToken
     */
    function stake(uint256 _amount)
        public
        validStake(_amount)
        hasNoStake
        hasGateToken
        returns (bool)
    {
        require(
            stakeToken.transferFrom(msg.sender, address(this), _amount),
            "Staking failed"
        );
        Record storage _record = records[msg.sender];
        _record.stakedBy = msg.sender;
        _record.amount = _amount;
        _record.stakedAt = block.timestamp;
        return true;
    }

    /**
     * conditions:
     *    withdraws all staked fund for calling address
     */
    function withdraw() public hasStake returns (bool) {
        Record storage _record = records[msg.sender];
        uint256 _maturity = block.timestamp - _record.stakedAt;
        uint256 _amount = _record.amount;
        
        uint256 _yield  = calculateYield(_maturity, _amount);
        uint _totalReturns = _yield + _amount;

        // effect balances and records
        totalStakes -= _record.amount;
        delete records[msg.sender];

        stakeToken.transfer(msg.sender, _totalReturns);
        
    }

    // calculates and returns yield
    function calculateYield(uint256 _maturity, uint256 _amount) internal view returns(uint256) {
        uint256 _yield = 0;
        
        if (_maturity < 3 days){
            return _yield;
        }

        // cycles is 30days long
        uint256 _months = _maturity / 30 days;
        
        // for withdraws before a cycle completes, count month as 1
        if (_months==0) {
            _months = 1;
        }

        _yield = (_months * MPY * _amount) / 100;

        return _yield;

    }

}
