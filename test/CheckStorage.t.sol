// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "contracts/CheckStorage.sol";

// forge test --match-contract CheckStorageTest --match-test testConcatLoop -vvvvv --gas-report

contract CheckStorageTest is Test {
    CheckStorage public testContract;

    string[] data1 = ["A", "B", "C"];
    string[] data2 = ["AAA", "BBB", "CCC"];
    string[] data3 =
        ["AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA", "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBB", "CCCCCCCCCCCCCCCCCCCCCCCCCCCCCC"];

    function setUp() public {
        testContract = new CheckStorage();
    }

    function testShortLength() public {
        string[] memory data = data1;

        testContract.setData(data);
        string memory concatResult = testContract.concatLoop();
        assertEq(concatResult, testContract.concatLoopMload());
        assertEq(concatResult, testContract.concatLoopMloadArgMemory(data));
        assertEq(concatResult, testContract.concatLoopSload(3, 1));
        assertEq(concatResult, testContract.concatLoopSloadLength());
    }

    function testMiddleLength() public {
        string[] memory data = data2;

        testContract.setData(data);
        string memory concatResult = testContract.concatLoop();
        assertEq(concatResult, testContract.concatLoopMload());
        assertEq(concatResult, testContract.concatLoopMloadArgMemory(data));
        assertEq(concatResult, testContract.concatLoopSload(3, 3));
        assertEq(concatResult, testContract.concatLoopSloadLength());
    }

    function testLongLength() public {
        string[] memory data = data3;

        testContract.setData(data);
        string memory concatResult = testContract.concatLoop();
        assertEq(concatResult, testContract.concatLoopMload());
        assertEq(concatResult, testContract.concatLoopMloadArgMemory(data));
        assertEq(concatResult, testContract.concatLoopSload(3, 30));
        assertEq(concatResult, testContract.concatLoopSloadLength());
    }

    function testLengthGasBranchPoint() public {
        uint256 len = 10;

        string[] memory data = new string[](3);
        data[0] = generateRandomString(len);
        data[1] = generateRandomString(len);
        data[2] = generateRandomString(len);

        testContract.setData(data);
        string memory concatResult = testContract.concatLoop();
        assertEq(concatResult, testContract.concatLoopMload());
        assertEq(concatResult, testContract.concatLoopMloadArgMemory(data));
        assertEq(concatResult, testContract.concatLoopSload(3, len));
        assertEq(concatResult, testContract.concatLoopSloadLength());
    }

    function testLengthGasTest() public {
        uint256 len = 10;
        uint256 index = 5;

        string[] memory data = new string[](index);
        for (uint256 i = 0; i < index;) {
            unchecked {
                data[i] = generateRandomString(len);
                i++;
            }
        }

        testContract.setData(data);
        string memory concatResult = testContract.concatLoop();
        assertEq(concatResult, testContract.concatLoopMload());
        assertEq(concatResult, testContract.concatLoopMloadArgMemory(data));
        assertEq(concatResult, testContract.concatLoopSload(index, len));
        assertEq(concatResult, testContract.concatLoopSloadLength());
    }

    // helper fanction
    function generateRandomString(uint256 len) public view returns (string memory) {
        bytes memory alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
        string memory result = "";

        for (uint256 i = 0; i < len;) {
            unchecked {
                uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, i))) % alphabet.length;
                result = string(abi.encodePacked(result, alphabet[rand]));
                i++;
            }
        }

        return result;
    }
}
