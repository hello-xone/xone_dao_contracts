// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title XXOC Token
 * @dev ERC20 token that represents staked XOC with multiplier
 */
contract xXOC is ERC20, Ownable2Step {
    event WhitelistUpdated(address indexed dapp, bool status);

    mapping(address => bool) public whitelistedContracts;

    constructor() ERC20("xXOC Token", "xXOC") Ownable(msg.sender) {}
    /**
     * @dev Update whitelist status for a dapp contract
     * @param _dapp Address of the dapp contract
     * @param _status Whitelist status (true = whitelisted, false = not whitelisted)
     */
    function updateWhitelist(address _dapp, bool _status) external onlyOwner {
        whitelistedContracts[_dapp] = _status;
        emit WhitelistUpdated(_dapp, _status);
    }

    /**
     * @dev Mint XXOC tokens - only callable by staking contract
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        require(whitelistedContracts[msg.sender], "Caller is not whitelisted");

        _mint(to, amount);
    }

    /**
     * @dev Burn XXOC tokens - only callable by staking contract
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burn(address from, uint256 amount) external {
        require(whitelistedContracts[msg.sender], "Caller is not whitelisted");

        _burn(from, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        if (whitelistedContracts[msg.sender])  {
            _transfer(sender, recipient, amount);
            return true;
        } else {
            return super.transferFrom(sender,  recipient, amount);
        }
    }
}
