// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IImageStorage.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "hardhat/console.sol";

contract ImageStorage is IImageStorage, Ownable{

    string[][] internal images;
    string public name;
    string public description;
    address public IMerge;
    string public func = "getImage(uint256)";

    event ReadImage(uint256 indexed index, string image);

    constructor(string memory name_, string memory description_){
        name = name_;
        description = description_;
    }

    function setMergeImages(address _new) public onlyOwner(){
        IMerge = _new;
    }

    function setFuncName (string memory _newName) public onlyOwner(){
        func = _newName;
    }

    function addImage(string memory newImage_) external override onlyOwner(){
        string[] memory newData = new string[](1);
        newData[0] = newImage_;
        images.push(newData);
    } 

    function addSubImage(uint256 id, string memory newSubImage_) external override onlyOwner(){
        images[id].push(newSubImage_);
    } 

    function updateImage(uint256 outer, uint256 inner, string memory newImage_) external override onlyOwner(){
        images[outer][inner] = newImage_;
    }

    /**
     * @dev Return binded image string
     *      String concat loop is double and outer loop count can be specified.
     * @param index      index of image, equals to outer index.
     * @param outerCount Outer loop count. if this value is greater than length of sub images, use length.
     */
    function getImageDoubleLoop(uint256 index, uint256 outerCount) public view override returns(string memory){
        uint256 len = images[index].length;
        //
        uint256 imax = (outerCount < len) ? outerCount : len;
        imax = (imax < 1) ? 1 : imax;
        // inner loop max iteration
        uint256 jmax = ceilDiv(len, imax, 10);
        // saving inner loop max iteration
        uint256 jlen = jmax;
        string memory ret;          // outer return string
        string memory imRet;        // intermediate return string
        // outer square loop
        for (uint256 i = 0 ; i < imax ; i++){
            // In final outer loop, correct max iteration of inner loop
            if (i == imax - 1){
                jmax = len - (imax * (jlen - 1));
                console.log("last outer max:",jmax);
            }
            // reset intermediate return string
            imRet = "";
            // inner square loop
            for (uint256 j = 0 ; j < jmax ; j++){
                // inner concat
                imRet = string.concat(imRet, images[index][i * jlen + j]);
                console.log("outer, inner:",i,j);
            }
            //outer concat
            ret = string.concat(ret, imRet);
        }
        console.log(bytes(ret).length);
        return ret;
    }

    function getImage(uint256 index) public view override returns(string memory){
        uint256 len = images[index].length;
        uint256 count = 4;
        uint256 imax = len / count;
        uint256 imod = len % count;
        string memory ret;
        string memory empty;
        for (uint256 i = 0 ; i < imax ; i++){
            ret = string.concat(ret
                , images[index][i * count]
                , images[index][i * count + 1]
                , images[index][i * count + 2]
                , images[index][i * count + 3]
            );
        }
        if(imod > 0){
            ret = string.concat(ret
                , (imod >= 1)?images[index][imax * count] : empty
                , (imod >= 2)?images[index][imax * count + 1] : empty
                , (imod >= 3)?images[index][imax * count + 2] : empty
            );

        }
        console.log(bytes(images[index][0]).length, bytes(images[index][len-1]).length, bytes(ret).length);
        return ret;
    }

    function getImageAssy(uint256 index) public view override returns(string memory){
        string memory ret;    
        require(index < images.length, "invalid index");

        assembly{
            //set slot number on memory
            let slot_no := mload(0x40)
            mstore(slot_no, images.slot)
            // hash for outer array from free memory pointer
            let hash_out := add(slot_no, 0x20)
            // hash for inner array
//            let hash_in := add(hash_out, 0x20)
            // hash for array element
//            let hash_elem := add(hash_in, 0x20)
            let hash_elem := add(hash_out, 0x20)

            // element of string storage
            let elem

            // initialize total length of concat string
//            let lenRet := 0

            // set length of return value
            ret := add(hash_elem, 0x20)       //address after hash_in
            // set pointer of content of ret
            let ptrRet := add(ret, 0x20)
            let ptrRetOrg := ptrRet

            let addr_out := add(keccak256(slot_no, 0x20), index)
            // initialize hash_out as key for outer array specified by index
            mstore(hash_out, addr_out)
            // storage address for element
            let addr_in := keccak256(hash_out, 0x20)
            // initialize hash_in as key for first element of inner array
//            mstore(hash_in, addr_in)

            // storage string bytes address in eleemnt
            let addr_elem

            // length of array of str
            let lenArray := sload(addr_out)

            // loop
            let i := 0
            for{
            } lt(i, lenArray){
                i := add(i, 1)
            }{
                // Get element of str
                elem := sload(addr_in)
                // Current pos
                let lenCurrent := 0
                // decode string by lowest bit
                switch and(elem, 0x01)
                //short case
                case 0x00{
                    // calculate actual length of string
                    lenCurrent := div(and(elem, 0xFF), 2)
                    // store actual string
                    mstore(ptrRet, and(elem, not(0xFF)))

                }
                //long case
                case 0x01{
                    // calculate actual length of string
                    lenCurrent := div(elem, 2)
                    // Get address of first element of long string
                    mstore(hash_elem, addr_in)
                    addr_elem := keccak256(hash_elem,0x20)
                    // store actural string per 32 bytes
                    let j := 0
                    for {
                    } lt(mul(j, 0x20), lenCurrent){
                        j := add(j, 1)
                    }{
                        // store 1 word string
                        mstore(add(ptrRet, mul(j, 0x20)), sload(add(addr_elem, j)))
                    }
                }
                // add string current length
//                lenRet := add(lenRet, lenCurrent)
                // increase return string pointer with length of element
                ptrRet := add(ptrRet, lenCurrent)
                // update storage address
                addr_in := add(addr_in, 1)
            }
            // store total length of return string
//            mstore(ret, lenRet)
            mstore(ret, sub(ptrRet, ptrRetOrg))
            // updte free memory allocation
            mstore(0x40, ptrRet)

        }
        return ret;
        
    }
    /**
     * 
     */
    function getEncodedImage(uint256 index) public view returns(string memory){
        return Base64.encode(bytes(Base64.encode(bytes(getImage(index)))));
//        return Base64.encode(getImage(index));
    }

/*    function getImage2(uint256 index) external view returns(string memory ret){
        uint256 len = images[index].length;
        for (uint256 i = 0 ; i < len ; i++){
            ret = string.concat(ret, images[index][i]);
        }
    }*/

    function getImageCount() external view override returns(uint256){
        return images.length;
    }

    function getSubImageCount(uint256 index) external view override returns(uint256){
        return images[index].length;
    }

    /**
     * @dev calc ceil(a/b) at inverse fpoint (floting point)
     * @param fpoint     roundup floting point (for example: ceil at 0.1, input 1/0.1 = 10)
     */
    function ceilDiv(uint256 a, uint256 b, uint256 fpoint) internal pure returns(uint256){
        return (((a * fpoint / b) + fpoint - 1) / fpoint);
    }

}



