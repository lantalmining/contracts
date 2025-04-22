/**
 * Copyright 2024 LanTal Mining. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Freezable} from "./Freezable.sol";
import {Feeable} from "./Feeable.sol";

contract LanTalMiningAuToken is
    Initializable,
    Ownable2StepUpgradeable,
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    Freezable,
    Feeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    event Mint(address indexed minter, address indexed to, uint256 amount);
    event Redeem(uint256 amount);
    event FrozenFundsBurned(address indexed account, uint256 balance);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(_msgSender());
        __ERC20_init("LanTalMining Au", "LMAU");
        __ERC20Permit_init("LanTalMining Au");
        __Pausable_init();
        __Freezable_init();
        __Feeable_init(_msgSender());
        __UUPSUpgradeable_init();
    }

    function transfer(address to, uint256 value) public override notFrozen(_msgSender()) notFrozen(to) returns (bool) {
        return super.transfer(to, value);
    }

    function approve(
        address spender,
        uint256 value
    ) public override notFrozen(_msgSender()) whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override notFrozen(_msgSender()) notFrozen(from) notFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function freeze(address account) external onlyOwner {
        _freeze(account);
    }

    function unfreeze(address account) external onlyOwner {
        _unfreeze(account);
    }

    function burnFrozenFunds(address account) external onlyOwner onlyFrozen(account) {
        uint256 balance = balanceOf(account);
        _burn(account, balance);
        emit FrozenFundsBurned(account, balance);
    }

    function mint(address to, uint256 value) external onlyOwner notFrozen(to) {
        _mint(to, value);
        emit Mint(_msgSender(), to, value);
    }

    function redeem(uint256 value) external onlyOwner {
        _burn(owner(), value);
        emit Redeem(value);
    }

    function setFeeParams(uint256 rate, uint256 maxFee) external virtual onlyOwner {
        super._setFeeParams(rate, maxFee);
    }

    function setFeeRecipient(address feeRecipient) external virtual onlyOwner {
        super._setFeeRecipient(feeRecipient);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {}

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20Upgradeable, Feeable) whenNotPaused {
        super._update(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual override notFrozen(owner) notFrozen(spender) whenNotPaused {
        super._approve(owner, spender, value, emitEvent);
    }
}
