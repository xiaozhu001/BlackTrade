pragma solidity ^0.6.0;

interface Token {
	function transfer(address to, uint256 value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
}

contract CommandWelfareContract {
    mapping(string => bool) commandMap;
    string command;
    uint8 totalNum;
    uint8 remnantNum;
    address owner;
    uint8 status;
    Token token;
    mapping(address => uint) robWelfareMap;
    address[] accountList;

     // _command 口令
     // num 数量
     // _token 20代币地址 0x87010faf5964d67ed070bc4b8dcafa1e1adc0997
    constructor(string memory _command, uint8 num, Token _token) public {
        owner = msg.sender;
        command = _command;
        commandMap[_command] = true;
        totalNum = num;
        remnantNum = num;
        token = _token;
    }

    // 发送红包
    function send() public {
        require(msg.sender == owner, "only owner");
        require(status == 0, "status is not 0");

        uint amount = token.balanceOf(address(this));
        require(amount != 0, "balance is 0");
        require(amount >= totalNum, "amount is fail");

        status = 1;
    }

    // 撤销红包
    function withdraw() public {
        require(msg.sender == owner, "only owner");

        status = 2;
        token.transfer(owner, token.balanceOf(address(this)));
    }

    // 领取红包
    function robWelfare(string memory _command) public {
        require(commandMap[_command], "command is fail");
        require(status == 1, "status is not 1");
        require(remnantNum > 0, "the quota is full");
        require(robWelfareMap[msg.sender] == 0, "not more than once");

        uint amount = token.balanceOf(address(this));

        uint tempAmount = amount / remnantNum;

        robWelfareMap[msg.sender] = tempAmount;
        token.transfer(msg.sender, tempAmount);
        accountList.push(msg.sender);
        remnantNum --;
    }

    // 红包信息
    // _status 0 已创建，1可领取，2已撤回
    function getWelfareInfo(address account) public view returns(
        string memory _command, // 口令
        uint8 _totalNum, // 总数
        uint8 _remnantNum, // 剩余数量
        uint256 _amount, // 剩余金额
        uint8 _status) {

        string memory tempCommand;
        if (robWelfareMap[msg.sender] != 0
            || account == owner
            || robWelfareMap[account] != 0 ) {
            tempCommand = command;
        }

        uint amount = token.balanceOf(address(this));
        return (tempCommand, totalNum, remnantNum, amount, status);
    }

    // 获取已领取名单
    function getAccountList() public view returns(address[] memory) {
        return accountList;
    }
}


contract Test {
    mapping(address => uint) accountMap;

	function transfer(address to, uint256 value) external returns (bool) {
	    require(accountMap[msg.sender] >= value);

        accountMap[to] += value;
        accountMap[msg.sender] -= value;
	}

	function balanceOf(address who) external view returns (uint256) {
        return accountMap[who];
	}

	function set(address who) public {
	    accountMap[who] += 1000;
	}
}