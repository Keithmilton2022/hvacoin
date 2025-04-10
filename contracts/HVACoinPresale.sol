// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract HVACoinPresale is Ownable {
    using SafeMath for uint256;

    IERC20 public hvacToken;
    uint256 public tokenPrice = 20000000000000000; // 0.02 BNB per HVAC (BNB has 18 decimals)
    uint256 public softCap = 500000 * 10**18;  // 500,000 USD (soft cap)
    uint256 public hardCap = 1000000 * 10**18; // 1,000,000 USD (hard cap)
    uint256 public raisedAmount;
    uint256 public totalTokensForSale = 50000000 * 10**18; // 50 million tokens for presale
    uint256 public totalTokensSold;
    uint256 public presaleEndTime;
    address public wallet;
    uint256 public presaleDuration; // Duration in seconds

    mapping(address => uint256) public contributions;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value);
    event PresaleFinalized();
    event PresaleExtended(uint256 newEndTime);

    constructor(address _hvacToken, address _wallet, uint256 _presaleDuration) {
        hvacToken = IERC20(_hvacToken);
        wallet = _wallet;
        presaleDuration = _presaleDuration; // Presale duration in seconds (e.g., 1 year)
        presaleEndTime = block.timestamp + _presaleDuration;
    }

    modifier onlyWhilePresaleOpen() {
        require(block.timestamp < presaleEndTime, "Presale has ended");
        _;
    }

    modifier onlyWhenPresaleClosed() {
        require(block.timestamp >= presaleEndTime, "Presale is still ongoing");
        _;
    }

    modifier checkCap(uint256 amount) {
        uint256 totalRaised = raisedAmount.add(amount);
        require(totalRaised <= hardCap, "Hard cap exceeded");
        _;
    }

    modifier checkTokens(uint256 tokenAmount) {
        require(totalTokensSold.add(tokenAmount) <= totalTokensForSale, "Not enough tokens for sale");
        _;
    }

    // Allow the presale to be extended if the soft cap isn't met
    function extendPresale(uint256 additionalTime) external onlyOwner {
        require(raisedAmount < softCap, "Soft cap already met");
        presaleEndTime = presaleEndTime.add(additionalTime);
        emit PresaleExtended(presaleEndTime);
    }

    function buyTokens(uint256 tokenAmount) external payable onlyWhilePresaleOpen checkCap(msg.value) checkTokens(tokenAmount) {
        uint256 value = tokenAmount.mul(tokenPrice);
        require(msg.value >= value, "Not enough BNB sent");

        raisedAmount = raisedAmount.add(value);
        totalTokensSold = totalTokensSold.add(tokenAmount);
        contributions[msg.sender] = contributions[msg.sender].add(value);

        hvacToken.transfer(msg.sender, tokenAmount);

        // Forward funds to the presale wallet
        payable(wallet).transfer(msg.value);

        emit TokensPurchased(msg.sender, tokenAmount, value);
    }

    function finalizePresale() external onlyWhenPresaleClosed onlyOwner {
        require(raisedAmount >= softCap, "Soft cap not reached");

        // Transfer remaining tokens back to the owner or destroy them
        uint256 remainingTokens = totalTokensForSale.sub(totalTokensSold);
        hvacToken.transfer(owner(), remainingTokens);

        emit PresaleFinalized();
    }

    function refund() external onlyWhenPresaleClosed {
        require(raisedAmount < softCap, "Soft cap reached, no refund");
        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contribution to refund");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }

    function presaleStatus() external view returns (uint256 totalRaised, uint256 tokensSold, uint256 timeRemaining) {
        return (raisedAmount, totalTokensSold, presaleEndTime > block.timestamp ? presaleEndTime - block.timestamp : 0);
    }
}
