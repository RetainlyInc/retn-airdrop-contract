pragma solidity ^0.4.16;
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract AirDrop is Ownable {

  Token token;
      
  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    require(isActive());

    _;
  }

  function AirDrop () {
      address _tokenAddr = 0x2ADd07C4d319a1211Ed6362D8D0fBE5EF56b65F6; 
      // test token 0x815CfC2701C1d072F2fb7E8bDBe692dEEefFfe41;
      token = Token(_tokenAddr);
  }
  
  function isActive() constant returns (bool) {
    return (
        tokensAvailable() > 0 // Tokens must be available to send
    );
  }


  /*
  * @dev function that transers the tokens to multiple destinations with multiple values
  */
  function sendTokens(address[] dests, uint256[] values) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    while (i < dests.length) {
        uint256 toSend = values[i] * 10**18;
        sendInternally(dests[i] , toSend, values[i]);
        i++;
    }
  }

  /*
  * @dev function that transers same amount of tokens to multiple destinations
  */
  function sendTokensSingleValue(address[] dests, uint256 value) whenDropIsActive onlyOwner external {
    uint256 i = 0;
    uint256 toSend = value * 10**18;
    while (i < dests.length) {
        sendInternally(dests[i] , toSend, value);
        i++;
    }
  }  

  function sendInternally(address recipient, uint256 tokensToSend, uint256 valueToPresent) internal {
    if(recipient == address(0)) return;

    if(tokensAvailable() >= tokensToSend) {
      token.transfer(recipient, tokensToSend);
      TransferredToken(recipient, valueToPresent);
    } else {
      FailedTransfer(recipient, valueToPresent); 
    }
  }   

  /**
   * @dev returns the number of tokens allocated to this contract
   */
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

  function drain() onlyOwner {
    require(isActive());
    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    owner.transfer(this.balance);
    token.transfer(owner, balance);
  }
}
