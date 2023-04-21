// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/* //////////////////////////////////////////////////////////////////////
Can't use it as it is!!
attention 31bytes and over32baytes
////////////////////////////////////////////////////////////////////// */

contract CheckStorage {
    string[] data;

    function setData(string[] memory data_) public {
        data = data_;
    }

    // frequently used concat function
    function concatLoop() public view returns (string memory result) {
        for (uint256 i = 0; i < data.length;) {
            unchecked {
                result = string(abi.encodePacked(result, data[i]));
                i++;
            }
        }
    }

    // mload function
    function concatLoopMload() public view returns (string memory result) {
        string[] memory data_ = data;

        assembly {
            // memory space
            // | 0x00  - 0x3F  | scratch space
            // | 0x40  - 0x5F  | free memory pointer (init = 0x1C0)
            // | 0x60  - 0x7F  | zero slot
            // | 0x80  - 0x9F  | data_.length    = 3
            // | 0xA0  - 0xBF  | data[0].pointer = 100
            // | 0xC0  - 0xDF  | data[1].pointer = 140
            // | 0xE0  - 0xFF  | data[2].pointer = 180
            // | 0x100 - 0x11F | data[0].length  = 3
            // | 0x120 - 0x13F | data[0].value   = AAA
            // | 0x140 - 0x15F | data[1].length  = 3
            // | 0x160 - 0x17F | data[1].value   = BBB
            // | 0x180 - 0x19F | data[2].length  = 3
            // | 0x1A0 - 0x1BF | data[2].value   = 100
            // | 0x1C0 - 0x1DF | dynamic memory arrays

            // free memory pointer
            result := mload(0x40)

            // memory counter
            let mc := add(result, 0x20)

            for {
                // loop counter
                let cc := 0
                let last := mload(data_)

                // target pointer
                let ptr := data_
                let temp
            } lt(cc, last) { cc := add(cc, 0x01) } {
                temp := mload(add(ptr, 0x20))

                // write value
                mstore(mc, mload(add(temp, 0x20)))

                // move memory counter
                mc := add(mc, mload(temp))

                // move target pointer
                ptr := add(ptr, 0x20)
            }

            // write result length
            mstore(result, sub(sub(mc, 0x20), result))

            // to 32bytes
            mstore(0x40, and(add(mc, 31), not(31)))
        }
        return result;
    }

    // mload function argument
    function concatLoopMloadArgMemory(string[] memory data_) public pure returns (string memory result) {
        assembly {
            // memory space
            // | 0x00  - 0x3F  | scratch space
            // | 0x40  - 0x5F  | free memory pointer (init = 0x1C0)
            // | 0x60  - 0x7F  | zero slot
            // | 0x80  - 0x9F  | data_.length    = 3
            // | 0xA0  - 0xBF  | data[0].pointer = 100
            // | 0xC0  - 0xDF  | data[1].pointer = 140
            // | 0xE0  - 0xFF  | data[2].pointer = 180
            // | 0x100 - 0x11F | data[0].length  = 3
            // | 0x120 - 0x13F | data[0].value   = AAA
            // | 0x140 - 0x15F | data[1].length  = 3
            // | 0x160 - 0x17F | data[1].value   = BBB
            // | 0x180 - 0x19F | data[2].length  = 3
            // | 0x1A0 - 0x1BF | data[2].value   = 100
            // | 0x1C0 - 0x1DF | dynamic memory arrays

            // free memory pointer
            result := mload(0x40)

            // memory counter
            let mc := add(result, 0x20)

            for {
                // loop counter
                let cc := 0
                let last := mload(data_)

                // target pointer
                let ptr := data_
                let temp
            } lt(cc, last) { cc := add(cc, 0x01) } {
                temp := mload(add(ptr, 0x20))

                // write value
                mstore(mc, mload(add(temp, 0x20)))

                // move memory counter
                mc := add(mc, mload(temp))

                // move target pointer
                ptr := add(ptr, 0x20)
            }
            // write result length
            mstore(result, sub(sub(mc, 0x20), result))

            // to 32bytes
            mstore(0x40, and(add(mc, 31), not(31)))
        }
        return result;
    }

    // sload function in case fixed length
    function concatLoopSload(uint256 len1, uint256 len2) public view returns (string memory result) {
        assembly {
            // free memory pointer
            result := mload(0x40)

            // memory counter
            let mc := add(result, 0x20)

            for {
                // loop counter
                let cc := 0

                // @attention length
                let last := len1

                // target slot (use scracth space)
                mstore(0x00, data.slot)
                let dataSlot := keccak256(0x00, 0x20)
            } lt(cc, last) { cc := add(cc, 0x01) } {
                // write value
                mstore(mc, sload(add(dataSlot, cc)))

                // move memory counter @attention length
                mc := add(mc, len2)
            }
            // write result length
            mstore(result, sub(sub(mc, 0x20), result))

            // to 32bytes
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        return result;
    }

    // sload function in case variable length
    // @attention impractical
    function concatLoopSloadLength() public view returns (string memory result) {
        uint256 length = data.length;
        assembly {
            // free memory pointer
            result := mload(0x40)

            // memory counter
            let mc := add(result, 0x20)

            for {
                let cc
                let last := length
                let temp

                // target slot (use scracth space)
                mstore(0x00, data.slot)
                let dataSlot := keccak256(0x00, 0x20)
            } lt(cc, last) { cc := add(cc, 0x01) } {
                temp := sload(add(dataSlot, cc))

                // variable length <----- I want to solve
                // @attention impractical
                let sc
                for {} lt(sc, 0x20) { sc := add(sc, 0x01) } {
                    let char := byte(sc, temp)
                    if eq(char, 0) { break }
                }

                // write value
                mstore(mc, temp)

                // move memory counter
                mc := add(mc, sc)
            }
            // write result length
            mstore(result, sub(sub(mc, 0x20), result))

            // to 32bytes
            mstore(0x40, and(add(mc, 31), not(31)))
        }

        return result;
    }
}
