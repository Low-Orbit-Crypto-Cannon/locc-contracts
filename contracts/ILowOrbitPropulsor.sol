// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

interface ILowOrbitPropulsor {
    function deposit(uint256 amount) external returns (bool);
    function withdraw(uint256 amount) external returns (bool);
    function pulse(uint256 fees) external returns (bool);
}