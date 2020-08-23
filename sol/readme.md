
### CommandWelfareContract.sol（口令红包合约）

#### 1、 部署合约
需要参数有口令、红包数量(最大100个)、20代币钱包合约地址。这里直接使用 fc地址：
> 0x87010faf5964d67ed070bc4b8dcafa1e1adc0997
~~~
constructor(string memory _command, uint8 num, Token _token) public
~~~

#### 2、发送红包
这个功能有些类似确认发送的意思，因此没有参数一旦确定了，直接发出去了。
~~~
function send() public
~~~

#### 3、撤销红包
可以在任意时间调用该接口，该接口可以将红包直接变为撤销状态，并可以将里面的所有未发出去的金额退回来。
~~~
function haiyoushui() public
~~~

#### 4、领取红包
该接口需要传入口令，来进行领取红包。一旦领取红包后会将金额打入到对应的钱包中。
~~~
function robWelfare(string memory _command) public
~~~

#### 5、获取红包信息
该接口可以获取到红包信息，只有account为发红者或已经领取红包的人才能获取到。
~~~
function getWelfareInfo(address account) public view returns(
        string memory _command, // 口令
        uint8 _totalNum, // 总数
        uint8 _remnantNum, // 剩余数量
        uint256 _amount, // 剩余金额
        uint8 _status)
~~~
注： _status 0 已创建，1可领取，2已撤回 刚刚创建的合约状态是0，调用send方法后状态是1，此时可以领取红包，当状态等于3时是已撤销。

#### 6、获取已经领取列表
该接口没有分页因此需要上面限制红包数。
~~~
function getAccountList() public view returns(address[] memory)
~~~

#### 7、FC钱包 转账接口
该接口是FC合约方法，在设置钱包金额时调用该接口，调用成功后刷新页面。传入上面的合约地址，就将金额设置成功了。
~~~
function transfer(address to, uint256 value) external returns (bool)
~~~

#### 8、FC钱包 获取余额接口
该接口是FC合约接口，显示用户余额的
~~~
function balanceOf(address who) external view returns (uint256)
~~~

#### 注意
FC钱包地址
> 0x87010faf5964d67ed070bc4b8dcafa1e1adc0997

引入FCToken.abi.json文件，即可调用。
原型： https://www.processon.com/view/link/5f20d85be401fd181ae06e6d
