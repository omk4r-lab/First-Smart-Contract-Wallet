// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Consumer {
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
    function deposit() public payable {}
    
}

contract MySmartContractWallet {

    address payable public owner;

    mapping(address => uint) public allowance;
    mapping(address => bool) public isAllowedToSend;
    mapping(address => bool) public guardians;
    address payable nextOwner;
    mapping(address =>mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardianResetCount;
    uint public constant confirmationsFromGuardiansForReset = 3;


        constructor() {
            // Owner Created //
            owner = payable(msg.sender);
        }
        // Guardians Set Only By The Owner //
        function SetGuardian(address _guardian, bool _isGuardian) public {
            require(msg.sender == owner, " You are not the Owner, Aborting !");
            guardians[_guardian] = _isGuardian;
        }
        // Propose A New Owner //
        function proposeNewOwner(address payable  _newOwner) public {
            require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, " You already Voted, Aborting !");
            require(guardians[msg.sender], "You are not a Guardian, Aborting !");
            if(_newOwner!= nextOwner){
                nextOwner = _newOwner;
                guardianResetCount = 0;
                
            }
            guardianResetCount++;

            if(guardianResetCount >= confirmationsFromGuardiansForReset) {
                owner = nextOwner;
                nextOwner = payable (address(0));
            }

        }
        // Only Owner Can Set Allowances //
         function setAllowance(address _for, uint _amount) public {
            require(msg.sender == owner, " You are not the Owner, Aborting !");
            allowance[_for] = _amount;

            if(_amount > 0) {
                isAllowedToSend[_for] = true;
            }
            else{
                isAllowedToSend[_for] = false;
            }
         }
         // Transfer Funds Out Of The Contract by other than Owner but at a set limit //
        function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){
            if(msg.sender!= owner) {
                require(allowance[msg.sender]>= _amount, " You are trying to send more than allowed, Aborting !");
                require(isAllowedToSend[msg.sender],"You are  not allowed to send anything from the contract, Aborting !");

                allowance[msg.sender] -= _amount;
            }
            (bool success,bytes memory returnData) = _to.call{value: _amount}(_payload);
            require(success, "Aborting!, call was not successful");
            return returnData;

        }
        // Wallet can Receive funds from external addresses //
        receive() external payable {}
    }
       