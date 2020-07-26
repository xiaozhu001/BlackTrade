pragma solidity ^0.6.0;

interface Token {
	function transfer(address to, uint256 value) external returns (bool);
	function balanceOf(address who) external view returns (uint256);
}

contract BlackTradeContract {
	mapping(address => uint256) fcAccountBalanceMap;
	mapping(address => uint256) usdtAccountBalanceMap;

	mapping(address => uint256) fcAccountLockBalanceMap;
	mapping(address => uint256) usdtAccountLockBalanceMap;

	Token fcToken;
	Token usdtToken;

	// admin
	address admin;

	// 空投记录
	mapping (string => bool) airdropRecord;

	// 导出用户数据
	mapping (address => bool) _accountCheck;
	address[] _accountList;


	// 兑换节点
	struct TradeNode {
		address account;
		uint256 number;
		uint256 tradeType;
		uint256 status; // 0未成交，1部分成交，2全部成交，3已撤销
		uint256 surplusNumber;
		uint256 rate; // 1fc 兑换0.2000个usdt rate = 2000
		uint256 nextIndex; // INDEX + 1
		uint256 preIndex; // INDEX + 1
		uint256 currentIndex;
		bool isExist;
	}

	// 节点列表
	TradeNode[] tradeNodeList;

	// 个人交易记录
	mapping(address => uint256[]) accountChangeListMap;

	uint256 fc2usdtHeader;
	uint256 usdt2fcHeader;

	modifier onlyAdmin() {
		require(admin == msg.sender, "only admin");
		_;
	}

	constructor(Token _fcToken, Token _usdtToken) public {
		admin = msg.sender;
		fcToken = _fcToken;
		usdtToken = _usdtToken;
	}

	// ------------------- 资产相关 ------------------------

	// 获取资产信息
	function balanceOf(address account) public view returns (
		uint256 fcAccountBalance,
		uint256 usdtAccountBalance,
		uint256 fcAccountLockBalance,
		uint256 usdtAccountLockBalance) {

		fcAccountBalance = fcAccountBalanceMap[account];
		usdtAccountBalance = usdtAccountBalanceMap[account];
		fcAccountLockBalance = fcAccountLockBalanceMap[account];
		usdtAccountLockBalance = usdtAccountLockBalanceMap[account];
	}

	// 资产移出 tradeType：1fc， 2usdt
	function transfer(uint256 tradeType, uint256 amount) public {
		address account = msg.sender;
		if (tradeType == 1) {
			require (amount <= fcAccountBalanceMap[account], "your balance is not enough");
			fcAccountBalanceMap[account] = fcAccountBalanceMap[account] - amount;
			fcToken.transfer(account, amount);
		} else if (tradeType == 2) {
			require (amount <= usdtAccountBalanceMap[account], "your balance is not enough");
			usdtAccountBalanceMap[account] = usdtAccountBalanceMap[account] - amount;
			usdtToken.transfer(account, amount);
		} else {
			require(false, "tradeType is fail");
		}

		if (!_accountCheck[account]) {
			_accountCheck[account] = true;
			_accountList.push(account);
		}

	}

	// 空投资产
	function airdrop(uint256 tradeType, address toAccount, uint256 amount, string memory transactionHash) public onlyAdmin {
		require (!airdropRecord[transactionHash], "airdrop record is exist");
		airdropRecord[transactionHash] = true;

		if (tradeType == 1) {
			fcAccountBalanceMap[toAccount] = fcAccountBalanceMap[toAccount] + amount;
		} else if (tradeType == 2) {
			usdtAccountBalanceMap[toAccount] = usdtAccountBalanceMap[toAccount] + amount;
		} else {
			require(false, "tradeType is fail");
		}
	}

	// 获取空投记录
	function getAirdropRecord(string memory transactionHash) public view returns(bool)  {
		return airdropRecord[transactionHash];
	}

	// 全部移出到admin
	function transferAdmin() public onlyAdmin {
		uint fcAmount = fcToken.balanceOf(address(this));
		fcToken.transfer(admin, fcAmount);

		uint usdtAmount = usdtToken.balanceOf(address(this));
		usdtToken.transfer(admin, usdtAmount);
	}

	// 导出所有用户地址
	function accountList(uint256 begin, uint256 size) public view returns (address[] memory) {
		require(begin >= 0 && begin < _accountList.length, "accountList out of range");
		address[] memory res = new address[](size);
		uint256 range = _accountList.length < begin + size ? _accountList.length : begin + size;
		for (uint256 i = begin; i < range; i++) {
			res[i-begin] = _accountList[i];
		}
		return res;
	}

	// 获取用户总数
	function accountTotal() public view returns (uint256) {
		return _accountList.length;
	}


	// ---------------------------- 交易相关---------------
	function fc2usdt(uint256 number, uint256 rate) public {
		require(fcAccountBalanceMap[msg.sender] >= number, "number is fail");
		require(rate >= 1, "rate is fail");
		accountChangeListMap[msg.sender];

		TradeNode memory tradeNode = TradeNode(msg.sender, number, 1, 0, number, rate, 0, 0, tradeNodeList.length + 1, true);
		accountChangeListMap[msg.sender].push(tradeNodeList.length + 1);
		tradeNodeList.push(tradeNode);

		fcAccountBalanceMap[msg.sender] = fcAccountBalanceMap[msg.sender] - number;
		fcAccountLockBalanceMap[msg.sender] = fcAccountLockBalanceMap[msg.sender] + number;

		if (usdt2fcHeader == 0 || !tradeNodeList[usdt2fcHeader - 1].isExist || tradeNodeList[usdt2fcHeader - 1].rate < rate) {
			_addFc2usdtNode(tradeNode.currentIndex);
			return;
		}
		_fc2usdtChange(tradeNode.currentIndex);
	}

	function usdt2fc(uint256 number, uint256 rate) public {
		require(usdtAccountBalanceMap[msg.sender] >= number, "number is fail");
		require(rate >= 1, "rate is fail");

		TradeNode memory tradeNode = TradeNode(msg.sender, number, 2, 0, number, rate, 0, 0, tradeNodeList.length + 1, true);
		accountChangeListMap[msg.sender].push(tradeNodeList.length + 1);
		tradeNodeList.push(tradeNode);

		usdtAccountBalanceMap[msg.sender] = usdtAccountBalanceMap[msg.sender] - number;
		usdtAccountLockBalanceMap[msg.sender] = usdtAccountLockBalanceMap[msg.sender] + number;

		if (fc2usdtHeader == 0 || !tradeNodeList[fc2usdtHeader - 1].isExist || tradeNodeList[fc2usdtHeader - 1].rate > rate) {
			_addUsdt2fcNode(tradeNode.currentIndex);
			return;
		}
		_usdt2fcChange(tradeNode.currentIndex);
	}

	function _fc2usdtChange(uint256 currentIndex) internal {

		TradeNode storage temp = tradeNodeList[usdt2fcHeader - 1];
		TradeNode storage node = tradeNodeList[currentIndex - 1];

		for (;;) {
			uint usdtNum = temp.rate * node.number / 10000;
			if (temp.surplusNumber > usdtNum) {
				fcAccountLockBalanceMap[node.account] = fcAccountLockBalanceMap[node.account] - node.surplusNumber;
				usdtAccountBalanceMap[node.account] = usdtAccountBalanceMap[node.account] + usdtNum;

				fcAccountBalanceMap[temp.account] = fcAccountBalanceMap[temp.account] + node.surplusNumber;
				usdtAccountLockBalanceMap[temp.account] = usdtAccountLockBalanceMap[temp.account] - usdtNum;

				temp.surplusNumber = temp.surplusNumber - usdtNum;
				temp.status = 1;
				node.status = 2;
				node.surplusNumber = 0;
				break;
			} else if (temp.surplusNumber < usdtNum) {

				uint256 fcNum = temp.surplusNumber * 10000 / temp.rate;
				fcAccountLockBalanceMap[node.account] = fcAccountLockBalanceMap[node.account] - fcNum;
				usdtAccountBalanceMap[node.account] = usdtAccountBalanceMap[node.account] + temp.surplusNumber;

				fcAccountBalanceMap[temp.account] = fcAccountBalanceMap[temp.account] + fcNum;
				usdtAccountLockBalanceMap[temp.account] = usdtAccountLockBalanceMap[temp.account] - temp.surplusNumber;

				temp.surplusNumber = 0;
				temp.status = 2;
				usdt2fcHeader = temp.nextIndex;
				temp.nextIndex = 0;

				node.status = 1;
				node.surplusNumber = node.surplusNumber - fcNum;
				_addFc2usdtNode(currentIndex);
				// 没有usdt2fc的单子直接返回
				if (usdt2fcHeader == 0) {
					break;
				}
				temp = tradeNodeList[usdt2fcHeader - 1];
			} else {
				fcAccountLockBalanceMap[node.account] = fcAccountLockBalanceMap[node.account] - node.surplusNumber;
				usdtAccountBalanceMap[node.account] = usdtAccountBalanceMap[node.account] + usdtNum;

				fcAccountBalanceMap[temp.account] = fcAccountBalanceMap[temp.account] + node.surplusNumber;
				usdtAccountLockBalanceMap[temp.account] = usdtAccountLockBalanceMap[temp.account] - usdtNum;

				temp.surplusNumber = 0;
				temp.status = 2;
				usdt2fcHeader = temp.nextIndex;
				temp.nextIndex = 0;

				node.status = 2;
				node.surplusNumber = 0;
				break;
			}
		}
	}

	function _usdt2fcChange(uint256 currentIndex) internal {

		TradeNode storage temp = tradeNodeList[fc2usdtHeader - 1];
		TradeNode storage node = tradeNodeList[currentIndex - 1];

		for (;;) {
			uint fcNum = node.number * 10000 / temp.rate;
			if (temp.surplusNumber > fcNum) {
				usdtAccountLockBalanceMap[node.account] = usdtAccountLockBalanceMap[node.account] - node.surplusNumber;
				fcAccountBalanceMap[node.account] = fcAccountBalanceMap[node.account] + fcNum;

				usdtAccountBalanceMap[temp.account] = usdtAccountBalanceMap[temp.account] + node.surplusNumber;
				fcAccountLockBalanceMap[temp.account] = fcAccountLockBalanceMap[temp.account] - fcNum;


				temp.surplusNumber = temp.surplusNumber - fcNum;
				temp.status = 1;

				node.status = 2;
				node.surplusNumber = 0;
				break;
			} else if (temp.surplusNumber < fcNum) {
				uint256 usdtNum = temp.surplusNumber * temp.rate / 10000;

				usdtAccountLockBalanceMap[node.account] = usdtAccountLockBalanceMap[node.account] - usdtNum;
				fcAccountBalanceMap[node.account] = fcAccountBalanceMap[node.account] + temp.surplusNumber;

				usdtAccountBalanceMap[temp.account] = usdtAccountBalanceMap[temp.account] + usdtNum;
				fcAccountLockBalanceMap[temp.account] = fcAccountLockBalanceMap[temp.account] - temp.surplusNumber;


				temp.surplusNumber = 0;
				temp.status = 2;
				fc2usdtHeader = temp.nextIndex;
				temp.nextIndex = 0;

				node.status = 1;
				node.surplusNumber = node.surplusNumber - usdtNum;
				_addUsdt2fcNode(currentIndex);
				// 没有usdt2fc的单子直接返回
				if (fc2usdtHeader == 0) {
					break;
				}
				temp = tradeNodeList[fc2usdtHeader - 1];
			} else {
				usdtAccountLockBalanceMap[node.account] = usdtAccountLockBalanceMap[node.account] - node.surplusNumber;
				fcAccountBalanceMap[node.account] = fcAccountBalanceMap[node.account] + fcNum;

				usdtAccountBalanceMap[temp.account] = usdtAccountBalanceMap[temp.account] + node.surplusNumber;
				fcAccountLockBalanceMap[temp.account] = fcAccountLockBalanceMap[temp.account] - fcNum;

				temp.surplusNumber = 0;
				temp.status = 2;
				fc2usdtHeader = temp.nextIndex;
				temp.nextIndex = 0;

				node.status = 2;
				node.surplusNumber = 0;
				break;
			}
		}
	}

	function _addFc2usdtNode(uint256 currentIndex) internal {
		if (fc2usdtHeader == 0) {
			fc2usdtHeader = currentIndex;
			return;
		}

		TradeNode storage temp = tradeNodeList[fc2usdtHeader - 1];
		TradeNode storage node = tradeNodeList[currentIndex - 1];
		if (temp.rate < node.rate) {
			node.nextIndex = temp.currentIndex;
			temp.preIndex = node.currentIndex;
			fc2usdtHeader = node.currentIndex;
			return;
		}
		while (true) {
			if (temp.rate < node.rate) {
				node.nextIndex = temp.currentIndex;
				TradeNode storage node1 = tradeNodeList[temp.preIndex - 1];
				node1.nextIndex = node.currentIndex;
				node.preIndex = temp.preIndex;
				temp.preIndex = node.currentIndex;
				break;
			}

			if (temp.nextIndex == 0) {
				node.nextIndex = temp.nextIndex;
				node.preIndex = temp.currentIndex;
				temp.nextIndex = node.currentIndex;
				break;
			} else {
				temp = tradeNodeList[temp.nextIndex - 1];
			}
		}
	}

	function _addUsdt2fcNode(uint256 currentIndex) internal {
		if (usdt2fcHeader == 0) {
			usdt2fcHeader = currentIndex;
			return;
		}

		TradeNode storage temp = tradeNodeList[usdt2fcHeader - 1];
		TradeNode storage node = tradeNodeList[currentIndex - 1];
		if (temp.rate > node.rate) {
			node.nextIndex = temp.currentIndex;
			temp.preIndex = node.currentIndex;
			usdt2fcHeader = node.currentIndex;
			return;
		}
		while (true) {
			if (temp.rate > node.rate) {
				node.nextIndex = temp.currentIndex;
				TradeNode storage node1 = tradeNodeList[temp.preIndex - 1];
				node1.nextIndex = node.currentIndex;
				node.preIndex = temp.preIndex;
				temp.preIndex = node.currentIndex;
				break;
			}

			if (temp.nextIndex == 0) {
				node.nextIndex = temp.nextIndex;
				node.preIndex = temp.currentIndex;
				temp.nextIndex = node.currentIndex;
				break;
			} else {
				temp = tradeNodeList[temp.nextIndex - 1];
			}
		}
	}

	function getFc2usdt() public view returns(uint[10] memory, uint[10] memory){
		uint[10] memory tempRate;
		uint[10] memory tempNum;
		if (fc2usdtHeader == 0) {
			return (tempRate, tempNum);
		}
		TradeNode memory tempNode = tradeNodeList[fc2usdtHeader - 1];
		tempRate[0] = tempNode.rate;
		tempNum[0] = tempNode.surplusNumber;
		for (uint i = 1;tempNode.nextIndex != 0 && i <= 9; i ++) {
			tempNode = tradeNodeList[tempNode.nextIndex - 1];
			tempRate[i] = tempNode.rate;
			tempNum[i] = tempNode.surplusNumber;
		}

		return (tempRate, tempNum);
	}

	function getUsdt2fc() public view returns(uint[10] memory, uint[10] memory){
		uint[10] memory tempRate;
		uint[10] memory tempNum;
		if (usdt2fcHeader == 0) {
			return (tempRate, tempNum);
		}
		TradeNode memory tempNode = tradeNodeList[usdt2fcHeader - 1];
		tempRate[0] = tempNode.rate;
		tempNum[0] = tempNode.surplusNumber;
		for (uint i = 1;tempNode.nextIndex != 0 && i <= 9; i ++) {
			tempNode = tradeNodeList[tempNode.nextIndex - 1];
			tempRate[i] = tempNode.rate;
			tempNum[i] = tempNode.surplusNumber;
		}

		return (tempRate, tempNum);
	}

	function cancelChange(uint256 index) public {
		require(index >= 1, "index is fail");
		TradeNode storage tempNode = tradeNodeList[index - 1];
		require(msg.sender == tempNode.account, "index is fail");
		require(tempNode.status == 0 || tempNode.status == 1, "index is fail");

		if (tempNode.tradeType == 1) {
			fcAccountLockBalanceMap[msg.sender] = fcAccountLockBalanceMap[msg.sender] - tempNode.surplusNumber;
			fcAccountBalanceMap[msg.sender] = fcAccountBalanceMap[msg.sender] + tempNode.surplusNumber;
		} else {
			usdtAccountLockBalanceMap[msg.sender] = usdtAccountLockBalanceMap[msg.sender] - tempNode.surplusNumber;
			usdtAccountBalanceMap[msg.sender] = usdtAccountBalanceMap[msg.sender] + tempNode.surplusNumber;
		}
		tempNode.status = 3;
	}


	function getAccountChangeCounts(address account) public view returns(uint256) {
		return accountChangeListMap[account].length;
	}

	function getAccountChangeCounts(address account, uint256 begin, uint256 size) public view returns(uint256[] memory) {
		require(begin >= 0 && begin < accountChangeListMap[account].length, "accountList out of range");
		uint256[] memory res = new uint256[](size);
		uint256 range = accountChangeListMap[account].length < begin + size ? accountChangeListMap[account].length : begin + size;
		for (uint256 i = begin; i < range; i++) {
			res[i-begin] = accountChangeListMap[account][i];
		}
		return res;
	}

	function getTradeNode(uint256 index) public view returns(uint256 number,
		uint256 tradeType,
		uint256 status,
		uint256 surplusNumber,
		uint256 rate) {

		TradeNode memory tempNode = tradeNodeList[index - 1];
		number = tempNode.number;
		tradeType = tempNode.tradeType;
		status = tempNode.status;
		surplusNumber = tempNode.surplusNumber;
		rate = tempNode.rate;
	}


}