pragma solidity ^0.6.0;

interface Token {
	function transfer(address to, uint256 value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
}

contract CommandWelfareContract {
    string command;
    uint8 public totalNum;
    uint8 public remnantNum;
    uint256 public amount;

    address owner;
    // 0 已创建，1可领取，2已撤回
    uint8 public status;

    Token token = Token(0x0);

    // 领奖记录
    mapping(address => uint) public robWelfareMap;
    mapping(string => bool) commandMap;
    address[] public accountList;

    constructor(string memory _command, uint8 num) public {
        owner = msg.sender;
        command = _command;
        commandMap[_command] = true;
        totalNum = num;
        remnantNum = num;
    }

    function send() public {
        require(msg.sender == owner, "only owner");
        require(status == 0, "status is not 0");

        amount = token.balanceOf(address(this));
        require(amount == 0, "balance is 0");
        require(amount >= totalNum, "amount is fail");

        status = 1;
    }

    function withdraw() public {
        require(msg.sender == owner, "only owner");

        status = 2;
        token.transfer(owner, token.balanceOf(address(this)));
    }

    function robWelfare(string memory _command) public {
        require(commandMap[_command], "command is fail");
        require(status == 2, "status is not 2");
        require(remnantNum > 0, "the quota is full");
        require(robWelfareMap[msg.sender] == 0, "not more than once");

        uint tempAmount = amount / remnantNum;
        robWelfareMap[msg.sender] = tempAmount;
        token.transfer(msg.sender, tempAmount);
        accountList.push(msg.sender);

        remnantNum --;
    }

    function getInfo(address account) public view returns(
        string memory _command,
        uint8 _totalNum,
        uint8 _remnantNum,
        uint256 _amount,
        address _owner,
        address[] memory _accountList,
        uint8 _status) {

        string memory tempCommand;
        if (robWelfareMap[msg.sender] != 0 || account == owner) {
            tempCommand = command;
        }

        return (tempCommand, totalNum, remnantNum, amount, owner, accountList, status);
    }
}


contract Test {
    mapping(address => uint) accountMap;

	function transfer(address to, uint256 value) external returns (bool) {
	    require(accountMap[msg.sender] >= value);

        accountMap[to] += value;
	}

	function balanceOf(address who) external view returns (uint256) {
        return accountMap[who];
	}

	function set(address who) public {
	    accountMap[who] += 1000;
	}
}