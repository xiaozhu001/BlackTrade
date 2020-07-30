pragma solidity ^0.6.0;

interface IERC777 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function granularity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function send(address recipient, uint256 amount, bytes calldata data) external;

    function burn(uint256 amount, bytes calldata data) external;

    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    function authorizeOperator(address operator) external;

    function revokeOperator(address operator) external;

    function defaultOperators() external view returns (address[] memory);

    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}
interface IERC777Recipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

interface IERC1820Registry {
    function setManager(address account, address newManager) external;

    function getManager(address account) external view returns (address);

    function setInterfaceImplementer(address account, bytes32 interfaceHash, address implementer) external;

    function getInterfaceImplementer(address account, bytes32 interfaceHash) external view returns (address);

    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    function updateERC165Cache(address account, bytes4 interfaceId) external;

    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed account, address indexed newManager);
}
contract GuessContract is IERC777Recipient {
    mapping(address => uint) public givers;
    address _owner;
    IERC777 _token;

    // IERC1820Registry private _erc1820 = IERC1820Registry(0x866aca87ff33a0ae05d2164b3d999a804f583222);
    // address _erc777Adress = 0x8d0ff27dbdb98f40530cc213d78d0665d5e5893a;

    IERC1820Registry private _erc1820 = IERC1820Registry(0xfEEA72d4D28fdE9bC2B16e077A39EA242E6ed0bd);
    address _erc777Address = 0xBB2Ae7947c0dD606Db2371cD21B2093975387451;.

	// 导出用户数据
    mapping (address => bool) _accountCheck;
    address[] _accountList;

    constructor() public {
        _erc1820.setInterfaceImplementer(address(this), keccak256(abi.encodePacked("IERC777Recipient")), address(this));
        _owner = msg.sender;
        _token = IERC777(_erc777Address);
    }

    // 收款时被回调
    function tokensReceived (
        address operator,
        address from,
        address to,
        uint amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        require(msg.sender == _erc777Address, "only 0xBB2Ae7947c0dD606Db2371cD21B2093975387451");
        givers[from] += amount;

        if (!_accountCheck[from]) {
            _accountCheck[from] = true;
            _accountList.push(from);
        }
    }

    // 转移所有资金
    function withdraw () external {
        require(msg.sender == _owner, "only owner");

        for (uint i = 0; i < _accountList.length; i ++) {
            address account = _accountList[i];
            _token.send(_owner, givers[account], "");
            givers[account] = 0;
        }

        uint balance = _token.balanceOf(address(this));
        _token.send(_owner, balance, "");
    }

    // 划出资产
    function drawOut (uint amount) external {
        require(givers[msg.sender] >= amount, "amount fail");
        givers[msg.sender] -= amount;
        _token.send(msg.sender, amount, "");
    }

}