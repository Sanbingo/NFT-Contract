// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// ERC721Enumerable 与 ERC721A 合约的应用场景：https://www.frank.hk/blog/azuki-erc721a?hmsr=joyk.com&utm_source=joyk.com&utm_medium=referral
contract SanMeta is ERC721Enumerable, Ownable {
    using Strings for uint256;
    // 售卖开关、盲盒开关
    bool public _isSaleActive = false;
    bool public _revealed = false;

    // contracts
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public mintPrice = 0.001 ether;
    uint256 maxBalance = 1;
    uint256 maxMint = 1;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";

    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory initBaseURI, string memory initNotRevealedUri) ERC721("San Meta", "SM") {
        setBaseURI(initBaseURI);
        setNotRevealedURI(initNotRevealedUri);
    }

    function mintSanMeta(uint256 tokenQuantity) public payable {
        require(totalSupply() + tokenQuantity <= MAX_SUPPLY, "Sale would exceed max supply"); 
        require(_isSaleActive, "Sale must be active to mint SanMeta");
        require(balanceOf(msg.sender)+tokenQuantity <= maxBalance, "Sale would exceed max balance");
        require(tokenQuantity*mintPrice <= msg.value, "Not enough ether sent");
        require(tokenQuantity <= maxMint, "Can only mint 1 tokens at a time");
        _mintSanMeta(tokenQuantity);
    }

    function _mintSanMeta(uint256 tokenQuantity) internal {
        for(uint256 i = 0; i < tokenQuantity; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < MAX_SUPPLY) {
                // 调用合约铸造NFT，第二个参数确保之前不存在
                _safeMint(msg.sender, mintIndex);
            }
        }
    }
    // virtual override 重载修饰符（覆盖原来的方法）
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_revealed == false) {
            return notRevealedUri;
        }

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        // abi.encodePacked对给定参数执行 紧打包编码，返回bytes

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked)
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        // If there is a baseURI but not tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString(), baseExtension));
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // only owner
    function flipSaleActive() public onlyOwner {
        _isSaleActive = !_isSaleActive;
    }

    function flipReveal() public onlyOwner {
        _revealed = !_revealed;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setMaxBalance(uint256 _maxBalance) public onlyOwner {
        maxBalance = _maxBalance;
    }

    function setMaxMint(uint256 _maxMint) public onlyOwner {
        maxMint = _maxMint;
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }
}

