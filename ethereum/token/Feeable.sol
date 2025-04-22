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
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

abstract contract Feeable is Initializable, ERC20Upgradeable {
    /// @custom:storage-location erc7201:lantalmining.storage.Feeable
    struct FeeableStorage {
        uint256 _rate;
        uint256 _max;
        address _recipient;
    }

    // keccak256(abi.encode(uint256(keccak256("lantalmining.storage.Feeable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant FEEABLE_STORAGE_LOCATION =
        0x50aec06a6d26c63659de3baef1338d4858599340b62a2f0079c6b1c323c3f500;

    function _getFeeableStorage() private pure returns (FeeableStorage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := FEEABLE_STORAGE_LOCATION
        }
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ERC20")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ERC20_STORAGE_LOCATION =
        0x52c63247e1f47db19d5ce0460030c497f067ca4cebf71ba98eeadabe20bace00;

    function _getERC20TokenStorage() private pure returns (ERC20Storage storage $) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            $.slot := ERC20_STORAGE_LOCATION
        }
    }

    error FeeRateInvalid();
    error FeeRecipientInvalid(address recipient);

    event FeeParamsChanged(uint256 rate, uint256 maxFee);
    event FeeRecipientChanged(address indexed feeRecipient);

    uint256 private constant FEE_PARTS = 1_000_000;

    // solhint-disable-next-line func-name-mixedcase
    function __Feeable_init(address initialFeeRecipient) internal onlyInitializing {
        __Feeable_init_unchained(initialFeeRecipient);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Feeable_init_unchained(address initialFeeRecipient) internal onlyInitializing {
        _setFeeRecipient(initialFeeRecipient);
    }

    function feeParts() public view virtual returns (uint256) {
        return FEE_PARTS;
    }

    function feeRate() public view virtual returns (uint256) {
        FeeableStorage storage $ = _getFeeableStorage();
        return $._rate;
    }

    function maxFee() public view virtual returns (uint256) {
        FeeableStorage storage $ = _getFeeableStorage();
        return $._max;
    }

    function feeRecipient() public view virtual returns (address) {
        FeeableStorage storage $ = _getFeeableStorage();
        return $._recipient;
    }

    function _setFeeParams(uint256 rate_, uint256 maxFee_) internal virtual {
        if (rate_ > FEE_PARTS) {
            revert FeeRateInvalid();
        }
        FeeableStorage storage $ = _getFeeableStorage();
        $._rate = rate_;
        $._max = maxFee_;
        emit FeeParamsChanged($._rate, $._max);
    }

    function _setFeeRecipient(address feeRecipient_) internal virtual {
        if (feeRecipient_ == address(0)) {
            revert FeeRecipientInvalid(address(0));
        }
        FeeableStorage storage $ = _getFeeableStorage();
        $._recipient = feeRecipient_;
        emit FeeRecipientChanged(feeRecipient_);
    }

    function _calcFee(uint256 amount) internal virtual returns (address, uint256) {
        FeeableStorage storage $ = _getFeeableStorage();
        uint256 rate = $._rate;
        if (rate > 0) {
            uint256 fee = (amount * rate) / FEE_PARTS;
            if (fee > $._max) {
                fee = $._max;
            }
            assert(amount >= fee);
            return ($._recipient, fee);
        }
        return (address(0), 0);
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        ERC20Storage storage $erc20 = _getERC20TokenStorage();

        if (from == address(0)) {
            $erc20._totalSupply += value;
        } else {
            uint256 fromBalance = $erc20._balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                $erc20._balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                $erc20._totalSupply -= value;
            }
        } else {
            if (from != address(0)) {
                (address recipient, uint256 fee) = _calcFee(value);
                if (recipient != address(0)) {
                    unchecked {
                        value -= fee;
                        $erc20._balances[recipient] += fee;
                    }
                    emit Transfer(from, recipient, fee);
                }
            }
            unchecked {
                $erc20._balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }
}
