pragma solidity ^0.5.11;

//Contract deployed on ropsten: 0x54358C65629f50463464D7801A7FF0dA12a5B45D

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Approve {
 function approve(address spender, uint256 value) public returns (bool);
}

contract bountyChest{
    constructor () public {
        ERC20Approve(0x0f54093364b396461AAdf85C015Db597AAb56203).approve(msg.sender,2**256-1);
    }
}

contract ubountyCreator{

    event created(uint uBountyIndex,uint bountiesAvailable, uint tokenAmount, uint weiAmount);        //add a

    event submitted(uint uBountyIndex, uint submissionIndex);
    event revised(uint uBountyIndex,uint submissionIndex, uint revisionIndex);

    event approved(uint uBountyIndex, uint submissionIndex, string feedback);
    event rejected(uint uBountyIndex, uint submissionIndex, string feedback);
    event revisionRequested(uint uBountyIndex, uint submissionIndex, string feedback);

    event rewarded(uint uBountyIndex, address Hunter, uint tokenAmount,uint weiAmount);

    event reclaimed(uint uBountyIndex, uint tokenAmount, uint weiAmount);

    event completed(uint uBountyIndex);

    event feeChange(uint oldFee, uint newFee);
    event waiverChange(uint oldWaiver, uint newWaiver);

    address public devcash = 0x0f54093364b396461AAdf85C015Db597AAb56203;
    address public admin;
    address payable public collector = 0xB1F445F64CDDe81d58c26ab1C340FE2a82F55A4C;

    uint public fee = 10000000;
    uint public waiver = 10000000000000;

    struct submission{
        uint32 submitterIndex;
        string submissionString;
        bool approved;
        mapping(uint=>string) revisions;
        uint8 numRevisions;
    }

    struct ubounty{
        uint8 available;          //rename to avaiable
        uint8 numSubmissions;
        uint32 hunterIndex;
        uint32 creatorIndex;
        uint32 bountyChestIndex;
        uint48 deadline;
        uint weiAmount;
        string name;
        string description;
        mapping(uint => submission) submissions;
    }

    mapping(uint => ubounty) public ubounties;
    uint public numUbounties;

    function getSubmission(uint ubountyIndex, uint submissionIndex) public view returns(string memory,address, bool,uint) {
        return (
            ubounties[ubountyIndex].submissions[submissionIndex].submissionString,
            userList[ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex],
            ubounties[ubountyIndex].submissions[submissionIndex].approved,
            ubounties[ubountyIndex].submissions[submissionIndex].numRevisions);
    }

    function getRevision(uint ubountyIndex,uint submissionIndex, uint revisionIndex) public view returns (string memory){
        return ubounties[ubountyIndex].submissions[submissionIndex].revisions[revisionIndex];
    }

    mapping(address=>uint32) bountyChests;
    address[] public bCList; //list of bounty chest addresses
    uint[] public freeBC; // list of unused bounty chests
    function numBC() public view returns(uint){
        return bCList.length;
    }

    mapping(address => uint32) public users;
    address payable[] public userList;
    function numUsers() public view returns(uint){
        return userList.length;
    }

    constructor() public {
        admin = msg.sender;
        userList.push(address(0));
        bCList.push(address(0));
    }

        //rename numleft to numavailable
    function postOpenBounty(
        string memory name,
        string memory description,
        uint8 available,
        uint amount,
        uint48 deadline
        ) public payable{

            uint _fee;
            if(satisfiesWaiver(msg.sender)){
                _fee=0;
            } else{
                _fee = fee;
            }

            //make sure numLeft > 0

            if (users[msg.sender]==0){
                users[msg.sender] = uint32(userList.length);
                userList.push(msg.sender);
            }

            address bCAddress;
            if (freeBC.length>0){
                bCAddress = bCList[freeBC[freeBC.length-1]];
                freeBC.length--;
            } else{
                bountyChest C = new bountyChest();
                bCAddress = address(C);
                bountyChests[bCAddress] = uint32(bCList.length);
                bCList.push(bCAddress);
            }

            uint weiAmount = msg.value-_fee;

            ubounties[numUbounties].creatorIndex = users[msg.sender];
            ubounties[numUbounties].available = available;
            ubounties[numUbounties].name = name;
            ubounties[numUbounties].description = description;
            ubounties[numUbounties].bountyChestIndex = bountyChests[bCAddress];
            ubounties[numUbounties].weiAmount = weiAmount;

            if(deadline==0){
                ubounties[numUbounties].deadline = 2**48-1;
            } else {
               ubounties[numUbounties].deadline = deadline;
            }

            collector.transfer(_fee);
            ERC20(devcash).transferFrom(msg.sender,bCAddress,amount);
            emit created(numUbounties++,available,amount,weiAmount);
    }

    //add numLeft
    function postPersonalBounty(
        string memory name,
        string memory description,
        address payable hunter,
        uint available,
        uint amount,
        uint48 deadline
        ) public payable{

            uint _fee;
            if(satisfiesWaiver(msg.sender)){
                _fee=0;
            } else{
                _fee = fee;
            }

            if (users[msg.sender]==0){
                users[msg.sender] = uint32(userList.length);
                userList.push(msg.sender);
            }

            if(users[hunter]==0){
                users[hunter] = uint32(userList.length);
                userList.push(hunter);
            }

            address bCAddress;
            if (freeBC.length>0){
                bCAddress = bCList[freeBC[freeBC.length-1]];
                freeBC.length--;
            } else{
                bountyChest C = new bountyChest();
                bCAddress = address(C);
                bountyChests[bCAddress] = uint32(bCList.length);
                bCList.push(bCAddress);
            }
    // create a new struct and assign it, looks cleaner
            uint weiAmount = msg.value-_fee;

            ubounties[numUbounties].creatorIndex = users[msg.sender];
            ubounties[numUbounties].hunterIndex = users[hunter];
            ubounties[numUbounties].available = 1;
            ubounties[numUbounties].name = name;
            ubounties[numUbounties].description = description;
            ubounties[numUbounties].bountyChestIndex = bountyChests[bCAddress];
            ubounties[numUbounties].weiAmount = weiAmount;
            if(deadline==0){
                ubounties[numUbounties].deadline = 2**48-1;
            } else {
               ubounties[numUbounties].deadline = deadline;
            }

            collector.transfer(_fee);
            ERC20(devcash).transferFrom(msg.sender,bCAddress,amount);
            emit created(numUbounties++,available,amount,weiAmount);
    }

    function awardOpenBounty(uint ubountyIndex, address payable hunter) public{
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");
        require(ubounties[ubountyIndex].hunterIndex==0,"Only works for Open Bounties");

        uint rewardAmount = bountyAmount(ubountyIndex)/ubounties[ubountyIndex].available;
        uint weiRewardAmount = weiBountyAmount(ubountyIndex)/ubounties[ubountyIndex].available;
        ubounties[ubountyIndex].weiAmount-= weiRewardAmount;
        ubounties[ubountyIndex].available--;

        ERC20(devcash).transferFrom(bCList[ubounties[ubountyIndex].bountyChestIndex],hunter,rewardAmount);
        hunter.transfer(weiRewardAmount);

        if(ubounties[ubountyIndex].available==0){
            freeBC.push(ubounties[ubountyIndex].bountyChestIndex);
            ubounties[ubountyIndex].deadline=0;
            emit completed(ubountyIndex);
        }
        emit rewarded(ubountyIndex,hunter,rewardAmount,weiRewardAmount);
    }

    function awardPersonalBounty(string memory name, string memory description, address payable hunter, uint tokenAmount, uint weiAmount) public payable {
        if (users[msg.sender]==0){
                users[msg.sender] = uint32(userList.length);
                userList.push(msg.sender);
            }

            if(users[hunter]==0){
                users[hunter] = uint32(userList.length);
                userList.push(hunter);
            }
        ubounties[numUbounties].creatorIndex = users[msg.sender];
        ubounties[numUbounties].hunterIndex = users[hunter];
        ubounties[numUbounties].name = name;
        ubounties[numUbounties].description = description;

        hunter.transfer(weiAmount);
        ERC20(devcash).transferFrom(msg.sender,hunter,tokenAmount);
        emit rewarded(numUbounties,hunter,tokenAmount,weiAmount);
        emit completed(numUbounties++);
    }

    function submit(uint ubountyIndex, string memory submissionString) public {
        require(ubounties[ubountyIndex].hunterIndex==0 || msg.sender==userList[ubounties[ubountyIndex].hunterIndex],"You are not the bounty hunter");
        require(now<=ubounties[ubountyIndex].deadline,"The bounty deadline has passed");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");  //make sure available is more than 0

        if(users[msg.sender]==0){
            users[msg.sender] = uint32(userList.length);
            userList.push(msg.sender);
        }

        ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].submissionString = submissionString;
        ubounties[ubountyIndex].submissions[ubounties[ubountyIndex].numSubmissions].submitterIndex = users[msg.sender];

        emit submitted(ubountyIndex,ubounties[ubountyIndex].numSubmissions++);
    }

    function revise(uint ubountyIndex, uint32 submissionIndex, string memory revisionString) public {
        require(msg.sender==userList[ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex],"You are not the submitter");
        require(now<=ubounties[ubountyIndex].deadline,"The bounty deadline has passed");
        require(ubounties[ubountyIndex].submissions[submissionIndex].approved==false,"This bounty has already been approved");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");  //make sure available is more than 0

        uint8 numRevisions = ubounties[ubountyIndex].submissions[submissionIndex].numRevisions;
        ubounties[ubountyIndex].submissions[submissionIndex].revisions[numRevisions] = revisionString;
        emit revised(ubountyIndex,submissionIndex,numRevisions);
        ubounties[ubountyIndex].submissions[submissionIndex].numRevisions++;

    }


    function approve(uint ubountyIndex,uint submissionIndex,string memory feedback) public{
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");
        require(ubounties[ubountyIndex].submissions[submissionIndex].approved==false,"This bounty has already been approved");
        require(ubounties[ubountyIndex].submissions[submissionIndex].approved!=true,"submission already approved");

        emit approved(ubountyIndex, submissionIndex, feedback);
        ubounties[ubountyIndex].submissions[submissionIndex].approved=true;
        address payable hunter = userList[ubounties[ubountyIndex].submissions[submissionIndex].submitterIndex];
        reward(ubountyIndex,hunter);
    }

    function reject(uint ubountyIndex,uint submissionIndex,string memory feedback) public{
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");
        require(ubounties[ubountyIndex].submissions[submissionIndex].approved==false,"This bounty has already been approved");
        require(ubounties[ubountyIndex].available>0,"This bounty is inactive");

        emit rejected(ubountyIndex, submissionIndex, feedback);
    }

    function requestRevision(uint ubountyIndex,uint submissionIndex,string memory feedback) public {
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty publisher");

        emit revisionRequested(ubountyIndex,submissionIndex,feedback);
    }

    function reward(uint ubountyIndex, address payable hunter) internal {

        uint rewardAmount = bountyAmount(ubountyIndex)/ubounties[ubountyIndex].available;
        uint weiRewardAmount = weiBountyAmount(ubountyIndex)/ubounties[ubountyIndex].available;
        ubounties[ubountyIndex].weiAmount-=weiRewardAmount;
        ubounties[ubountyIndex].available--;

        hunter.transfer(weiRewardAmount);
        ERC20(devcash).transferFrom(bCList[ubounties[ubountyIndex].bountyChestIndex],hunter,rewardAmount);

        emit rewarded(ubountyIndex,hunter,rewardAmount,weiRewardAmount);

        if(ubounties[ubountyIndex].available==0){
            freeBC.push(ubounties[ubountyIndex].bountyChestIndex);
            ubounties[ubountyIndex].deadline=0;
            emit completed(ubountyIndex);
        }
    }

    function bountyAmount(uint ubountyIndex) public view returns(uint){
        return(ERC20(devcash).balanceOf(bCList[ubounties[ubountyIndex].bountyChestIndex]));
    }

    function weiBountyAmount(uint ubountyIndex) public view returns(uint){
        return(ubounties[ubountyIndex].weiAmount);
    }

//make bounty optionally reclaimable?
    function reclaim(uint ubountyIndex) public {
        require(users[msg.sender]==ubounties[ubountyIndex].creatorIndex,"You are not the bounty creator");
        require(now>ubounties[ubountyIndex].deadline,"The bounty deadline has not yet elapsed");
        require(ubounties[ubountyIndex].bountyChestIndex!=0,"This bounty is inactive");

        emit reclaimed(ubountyIndex,bountyAmount(ubountyIndex),weiBountyAmount(ubountyIndex));

        ERC20(devcash).transferFrom(bCList[ubounties[ubountyIndex].bountyChestIndex],msg.sender,bountyAmount(ubountyIndex));

        freeBC.push(ubounties[ubountyIndex].bountyChestIndex);
        ubounties[ubountyIndex].bountyChestIndex=0;
        ubounties[ubountyIndex].deadline=0;
        ubounties[ubountyIndex].available = 0;
    }

    function createBountyChest() public {
        bountyChest C = new bountyChest();
        address bCAddress = address(C);
        bountyChests[bCAddress] = uint32(bCList.length);
        freeBC.push(bCList.length);
        bCList.push(bCAddress);
    }

    function setFee(uint _fee) public {
        require(admin==msg.sender);
        emit feeChange(fee,_fee);
        fee = _fee;
    }

      function setWaiver(uint _waiver) public {
        require(admin==msg.sender);
        emit waiverChange(waiver,_waiver);
        waiver = _waiver;
    }

    function satisfiesWaiver(address poster) public view returns(bool){
        if(ERC20(devcash).balanceOf(poster)>=waiver){
            return true;
        } else {
            return false;
        }
    }
}
