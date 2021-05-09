// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract LowOrbitPropulsor is AccessControl {
    using SafeMath for uint;
    using SafeMath for uint256;

    struct StakerData {
        address addr;
        uint256 balance;
    }

    bool public isPaused;

    uint256 private _stakersCount;
    StakerData[] private _stakersData;
    mapping (address => uint256) private _stakersIds;
    mapping (address => uint256) private _earningsHistory;

    uint256 private _activeLock;
    uint256 private _activeStaker;

    address private _lowOrbitERC20Addr;

    uint256 private _blockLastPropulsion;
    uint256 private _fuelToWin;

    uint256 private _blocksBetweenPropulsion;
    uint256 private _minStakingToBePropelled;

    event StakerPropelled(address astronaut, uint256 fuelEarned);

    constructor(address lowOrbitERC20Addr) {
        _lowOrbitERC20Addr = lowOrbitERC20Addr;
        
        _stakersCount = 0;
        _fuelToWin = 0;
        _blockLastPropulsion = block.number;

        _activeLock = 0;
        _activeStaker = 0; 

        _blocksBetweenPropulsion = (uint256) (30 * 60) / 13;
        _minStakingToBePropelled = 1 * (10 ** 18);
        isPaused = false;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function deposit(uint256 amount) external notPaused returns (bool) {
        require(amount >= _minStakingToBePropelled, "Insufficient amount");

        ERC20 lowOrbitERC20 = ERC20(_lowOrbitERC20Addr);
        require(lowOrbitERC20.balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(lowOrbitERC20.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 fees = amount.div(100).mul(10);
        uint256 amountSubFees = amount.sub(fees);

        uint256 stakerId;
        if(_stakersIds[msg.sender] == 0) {
            _stakersCount = _stakersCount.add(1);
            stakerId = _stakersCount;

            _stakersIds[msg.sender] = stakerId;
            _stakersData.push(StakerData({
                addr: msg.sender,
                balance: 0
            }));
        } else {
            stakerId = _stakersIds[msg.sender];
        }

        uint256 stakerIndex = stakerId - 1;
        StakerData storage stakerData = _stakersData[stakerIndex];

        if (stakerData.balance == 0) {
            _activeStaker = _activeStaker.add(1);
        }

        stakerData.balance = stakerData.balance.add(amountSubFees);

        _activeLock = _activeLock.add(amountSubFees);
        
        return true;
    }

    function withdraw() external notPaused returns (bool) {
        uint256 stakerId = _stakersIds[msg.sender];
        require(stakerId > 0, "Unauthorized");

        uint256 stakerIndex = stakerId - 1;
        StakerData storage stakerData = _stakersData[stakerIndex];

        require(stakerData.balance >= 0, "Insufficient balance");

        uint256 amountToWithdraw = stakerData.balance;
        stakerData.balance = 0;

        ERC20 lowOrbitERC20 = ERC20(_lowOrbitERC20Addr);
        require(lowOrbitERC20.transfer(msg.sender, amountToWithdraw), "Transfer failed");

        _activeStaker = _activeStaker.sub(1);
        _activeLock = _activeLock.sub(amountToWithdraw);

        return true;
    }

    function pulse(uint256 fees) external returns (bool) {
        require(msg.sender == _lowOrbitERC20Addr);
        _fuelToWin = _fuelToWin.add(fees);

        if (!isPaused && 
            _fuelToWin > 0 && _stakersCount > 0 &&
                block.number.sub(_blockLastPropulsion) >= _blocksBetweenPropulsion) {

            uint256 nextAstronautId = rnd(_stakersCount) + 1;
            uint256 nextAstronautIndex = nextAstronautId - 1;

            StakerData storage stakerData = _stakersData[nextAstronautIndex];

            if (stakerData.addr != address(0) &&
                stakerData.balance >= _minStakingToBePropelled) {

                uint256 propulsionFuel = _fuelToWin;
                _fuelToWin = 0;
                _blockLastPropulsion = block.number;

                _earningsHistory[stakerData.addr] = _earningsHistory[stakerData.addr].add(propulsionFuel);

                ERC20 lowOrbitERC20 = ERC20(_lowOrbitERC20Addr);
                lowOrbitERC20.transfer(stakerData.addr, propulsionFuel);

                emit StakerPropelled(stakerData.addr, propulsionFuel);
            }
        }

        return true;
    }

    function getBlockLastPropulsion() public view returns (uint256) {
        return _blockLastPropulsion;
    }

    function getFuelToWin() public view returns (uint256) {
        return _fuelToWin;
    }

    function getStakedAmountByAddr(address stakerAddr) public view returns (uint256) {
        uint256 stakerId = _stakersIds[stakerAddr];
        if (stakerId <= 0) {
            return 0;
        }

        uint256 stakerIndex = stakerId - 1;
        return _stakersData[stakerIndex].balance;
    }

    function getEarnedAmountByAddr(address stakerAddr) public view returns (uint256) {
        return _earningsHistory[stakerAddr];
    }

    function getBlocksBetweenPropulsion() public view returns (uint256) {
        return _blocksBetweenPropulsion;
    }

    function getMinStakingToBePropelled() public view returns (uint256) {
        return _minStakingToBePropelled;
    }

    function rnd(uint256 max) private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp +
                block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                        block.gaslimit + 
                            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                                block.number
        )));

        return (seed - ((seed / max) * max));
    }

    function setBlocksBetweenPropulsion(uint256 blocksBetweenPropulsion) external onlyAdmin {
        _blocksBetweenPropulsion = blocksBetweenPropulsion;
    }

    function setMinStakingToBePropelled(uint256 minStakingToBePropelled) external onlyAdmin {
        _minStakingToBePropelled = minStakingToBePropelled;
    }

    function pause() external onlyAdmin {
        isPaused = true;
    }

    function unpause() external onlyAdmin {
        isPaused = false;
    }

    modifier onlyAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized");
        _;
    }

    modifier notPaused {
        require(!isPaused, "Contract is paused");
        _;
    }
}
