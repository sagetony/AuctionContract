// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract auctionCreator{
    Auction[] public auctions;

    function auctionCreate() public{
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    enum State {Started, Running, Ended, Canceled}
    State public auctionState;

    mapping(address => uint) public bids;
    uint public highestBindingBid;
    address payable public highestBidder;
    uint bidIncrement;
    

    constructor (address eoa){
            owner = payable(eoa);
            auctionState = State.Running;
            startBlock = block.number;
            endBlock = block.number + 3;
            ipfsHash = "";
            bidIncrement = 100;
            
           
    }

    modifier onlyOwner(){
        require(msg.sender != owner, "Owner can't participate");
        _;
    }
    modifier startAuction(){
        require(block.number >= startBlock, "Wrong time");
        _;
    }
    modifier endAuction(){
        require(block.number <= endBlock, "wrong time");
        _;
    }
    modifier onlyAdmin(){
        require(msg.sender == owner);
        _;
    }
    function min(uint a, uint b) pure internal returns (uint){
            if(a <= b){
                return a;
            }else{
                return b;
            }
    }

    function placeBid() public payable onlyOwner startAuction endAuction{

            require(auctionState == State.Running, "Status");
            require(msg.value >= 100, "Add Wei");

            uint currentBid = bids[msg.sender] + msg.value;
            require(currentBid > highestBindingBid, "Error");

            bids[msg.sender] = currentBid;
            if(currentBid <= bids[highestBidder]){
                highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
            }else{
                highestBindingBid = min(currentBid, bidIncrement + bids[highestBidder]);
                highestBidder = payable(msg.sender);
            }
    }

    function cancelBid() public onlyAdmin{
        auctionState = State.Canceled;
    }

    function finalizeAuction() public{
        require (auctionState == State.Canceled || block.number > endBlock, "I no knw");
               require(msg.sender == owner || bids[msg.sender] > 0, "Err2");
                address payable receipent;
                uint value;
                    if(auctionState == State.Canceled){
                        receipent = payable(msg.sender);
                            value = bids[msg.sender];
                    }else{
                        if(msg.sender == owner){
                                receipent = payable(msg.sender);
                                value = highestBindingBid;
                            }else{
                              if(msg.sender == highestBidder){
                                    receipent = highestBidder;
                                   value = bids[highestBidder] - highestBindingBid;
                                    }else{
                                        receipent = payable(msg.sender);
                                        value = bids[msg.sender];
                                    }
                                }
                
                        }                     
            receipent.transfer(value);
            //  reset bids
            bids[receipent] = 0;
    }
}