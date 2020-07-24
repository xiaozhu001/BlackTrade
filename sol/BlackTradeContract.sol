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
    
    modifier onlyAdmin() {
    	require(admin == msg.sender, "only admin");
    	_;
    }
    
    constructor(Token _fcToken, Token _usdtToken) public {
    	admin = msg.sender;
    	fcToken = _fcToken;
    	usdtToken = _usdtToken;
    }

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
	function transferAdmin() public {
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
	TradeNode[] tradeNodeList;

	mapping(address => uint256) accountTradeMap;

	mapping (uint256 => uint256) headerMap;
	

	// tradeType 1fc2usdt 2usdt2fc, amount 是待兑换金额，
	// rate 是兑换比例 1个fc兑换0.1000个usdt rate = 1000
	function trade(uint256 tradeType, uint256 number, uint256 rate) public {
	    require(tradeType == 1 || tradeType == 2, "tradeType is fail");
		TradeNode memory tradeNode = TradeNode(msg.sender, number, tradeType, 0, number, rate, 0, 0, tradeNodeList.length + 1, true);
		tradeNodeList.push(tradeNode);

		if (tradeType == 1) {
			TradeNode memory tempNode = tradeNodeList[headerMap[2]];
			if (!tempNode.isExist) {
        		_addNode(tradeNode, tradeType);
			} else {

			}
		} else if (tradeType == 2) {
			TradeNode memory tempNode = tradeNodeList[headerMap[1]];
			if (!tempNode.isExist) {
        		_addNode(tradeNode, tradeType);
			} else {

			}
		}
	}

	function _addNode(TradeNode memory node, uint256 tradeType) internal {
		
        if (tradeNodeList.length == 1) {
            headerMap[tradeType] = 1;
            return;
        }

        TradeNode storage temp = tradeNodeList[headerMap[tradeType] - 1];
        if (temp.rate < node.rate) {
            node.nextIndex = temp.currentIndex;
            temp.preIndex = node.currentIndex;
            headerMap[tradeType] = node.currentIndex;
            return;
        }
        while (true) {
            if (temp.rate < node.rate) {
                node.nextIndex = temp.currentIndex;
                node.preIndex = temp.preIndex;
                temp.preIndex = node.currentIndex;
                break;
            } else {
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
	}
	
	

    

}