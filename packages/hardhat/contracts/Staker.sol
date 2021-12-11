pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 * 10 ** 18;
  uint256 public deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw = false;
  event Stake(address indexed _from, uint256 _value);
  event Withdraw(address indexed _from, uint256 _value);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier deadlineReached {
    require(timeLeft() <= 0, "Time hasn't arrived yet");
    _;
  }

  //Stake x amount of eth
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  //Withdraw if threshold is not met
  function withdraw(address payable _withdrawAddress) public payable deadlineReached {
    require(openForWithdraw);
    require(balances[_withdrawAddress] > 0, "You have no balance left in here!");

    (bool success, ) = _withdrawAddress.call{value: balances[_withdrawAddress]}("");
    require(success, "Failed to withdraw user balance.");
    emit Withdraw(_withdrawAddress, balances[_withdrawAddress]);
    balances[_withdrawAddress] = 0;
  }

  //If threshold is met then .complete()
  function execute() public deadlineReached {
    if (address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  //Time left before executing 
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }

  receive() external payable { 
    stake();
  }


}
