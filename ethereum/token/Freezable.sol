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

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Freezable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:lantalmining.storage.Freezable
    struct FreezableStorage {
        mapping(address => bool) _frozen;
    }

    // keccak256(abi.encode(uint256(keccak256("lantalmining.storage.Freezable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FREEZABLE_STORAGE_LOCATION =
        0x98f5cbd3380b8191db24ff05e05a319c5f63cab76da3ae1bc25d634271302700;

    error AccountFrozen(address account);
    error AccountUnfrozen(address account);

    event Freezing(address indexed freezer, address indexed account);
    event Unfreezing(address indexed unfreezer, address indexed account);

    // solhint-disable-next-line func-name-mixedcase
    function __Freezable_init() internal onlyInitializing {
        __Freezable_init_unchained();
    }

    // solhint-disable-next-line func-name-mixedcase, no-empty-blocks
    function __Freezable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Throws if argument account is frozen.
     * @param account The address to check.
     */
    modifier notFrozen(address account) {
        if (isFrozen(account)) {
            revert AccountFrozen(account);
        }
        _;
    }

    /**
     * @dev Throws if argument account is not frozen.
     * @param account The address to check.
     */
    modifier onlyFrozen(address account) {
        if (!isFrozen(account)) {
            revert AccountUnfrozen(account);
        }
        _;
    }

    /**
     * @notice Checks if account is frozen.
     * @param account The address to check.
     * @return True if the account is frozen, false if the account is not frozen.
     */
    function isFrozen(address account) public view virtual returns (bool) {
        FreezableStorage storage $ = _getFreezableStorage();
        return $._frozen[account];
    }

    /**
     * @dev Helper method that freezes an account.
     * @param account The address to freeze.
     */
    function _freeze(address account) internal virtual {
        FreezableStorage storage $ = _getFreezableStorage();
        $._frozen[account] = true;
        emit Freezing(_msgSender(), account);
    }

    /**
     * @dev Helper method that unfreezes an account.
     * @param account The address to unfreeze.
     */
    function _unfreeze(address account) internal virtual {
        FreezableStorage storage $ = _getFreezableStorage();
        $._frozen[account] = false;
        emit Unfreezing(_msgSender(), account);
    }

    function _getFreezableStorage() private pure returns (FreezableStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := FREEZABLE_STORAGE_LOCATION
        }
    }
}
