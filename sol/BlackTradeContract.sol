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

	// 资产移出 type：1fc， 2usdt
	function transfer(uint256 type, uint256 amount) public {
		address account = msg.sender;
		if (type == 1) {
			require (amount <= fcAccountBalanceMap[account], "your balance is not enough");
			fcAccountBalanceMap[account] = fcAccountBalanceMap[account] - amount;
			fcToken.transfer(account, amount);
		} else if (type == 2) {
			require (amount <= usdtAccountBalanceMap[account], "your balance is not enough");
			usdtAccountBalanceMap[account] = usdtAccountBalanceMap[account] - amount;
			usdtToken.transfer(account, amount);
		} else {
			require ("type is fail");
		}

        if (!_accountCheck[account]) {
            _accountCheck[account] = true;
            _accountList.push(account);
        }

	}

	// 空投资产
    function airdrop(uint256 type, address toAccount, uint256 amount, string memory transactionHash) public onlyAdmin {
		require (!airdropRecord[transactionHash], "airdrop record is exist");
		
		if (type == 1) {
			fcAccountBalanceMap[toAccount] = fcAccountBalanceMap[toAccount] + amount;
		} else if (type == 2) {
			usdtAccountBalanceMap[toAccount] = usdtAccountBalanceMap[toAccount] + amount;
		} else {
			require ("type is fail");
		}
	}

	// 获取空投记录
	function getAirdropRecord(string memory transactionHash) returns(bool) public {
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

	struct TradeInfo {
		uint256 number;
		uint256 surplusNumber;
		uint256 rate; // 1fc 兑换0.2000个usdt rate = 2000
		uint256 nextIndex;
		uint256 preIndex;
		bool isExist;
	}
	TradeInfo[] tradeInfoList;

	TradeInfo usdt2fcHeader;

	TradeInfo fc2usdtHeader;

	// type 1fc2usdt 2usdt2fc, amount 是待兑换金额，
	// rate 是兑换比例 1个fc兑换0.1000个usdt rate = 1000
	// 1fc 兑换0.2000个usdt rate = 2000
	// 1usdt 兑换 10fc rate = 1000
	// 1usdt 兑换 5fc rate = 2000  1/5 * 10000
	function trade(uint256 type, uint256 number, uint256 rate) public {
		if (type == 1) {
			if (fc2usdtHeader.isExist) {
				rate < fc2usdtHeader.rate
			}
		} else if (type == 2) {

		} else {
			require ("type is fail");
		}
	}

    

}