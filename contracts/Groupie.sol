// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FanMintCollectibles is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _artIdCounter;

    uint256 public constant MAX_URI_LENGTH = 256;

    struct Art {
        string title;
        string artistName;
        address artistWallet;
        string mediaUrl;
        string previewUrl;
        uint256 price;
        uint256 totalMinted;
        uint256 maxSupply;
    }

    mapping(uint256 => Art) public arts;

    event ArtUploaded(
        uint256 indexed artId,
        address indexed artist,
        string title
    );
    event ArtMinted(
        uint256 indexed artId,
        address indexed buyer,
        uint256 amount
    );
    event ArtTransferred(
        uint256 indexed artId,
        address from,
        address to,
        uint256 amount
    );

    constructor() ERC1155("") {}

    function uploadArt(
        string memory _title,
        string memory _artistName,
        string memory _mediaUrl,
        string memory _previewUrl,
        uint256 _price,
        uint256 _maxSupply
    ) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_artistName).length > 0, "Artist name cannot be empty");
        require(bytes(_mediaUrl).length > 0, "Media URL cannot be empty");
        require(_price > 0, "Price must be greater than 0");
        require(_maxSupply > 0, "Supply must be greater than 0");
        require(
            bytes(_mediaUrl).length <= MAX_URI_LENGTH,
            "Media URL too long"
        );

        if (bytes(_previewUrl).length > 0) {
            require(
                bytes(_previewUrl).length <= MAX_URI_LENGTH,
                "Preview URL too long"
            );
        }

        uint256 newArtId = _artIdCounter.current();
        arts[newArtId] = Art({
            title: _title,
            artistName: _artistName,
            artistWallet: msg.sender,
            mediaUrl: _mediaUrl,
            previewUrl: _previewUrl,
            price: _price,
            totalMinted: 0,
            maxSupply: _maxSupply
        });

        _artIdCounter.increment();
        emit ArtUploaded(newArtId, msg.sender, _title);
    }

    function mintArt(uint256 _artId, uint256 _amount) external payable {
        Art storage art = arts[_artId];
        require(bytes(art.title).length > 0, "Art does not exist");
        require(_amount > 0, "Must mint at least 1");
        require(
            art.totalMinted + _amount <= art.maxSupply,
            "Exceeds max supply"
        );

        uint256 totalPrice = art.price * _amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        uint256 artistShare = (msg.value * 90) / 100;
        uint256 ownerShare = msg.value - artistShare;

        payable(art.artistWallet).transfer(artistShare);
        payable(owner()).transfer(ownerShare);

        _mint(msg.sender, _artId, _amount, "");
        art.totalMinted += _amount;

        emit ArtMinted(_artId, msg.sender, _amount);
    }

    function uri(uint256 _artId) public view override returns (string memory) {
        require(bytes(arts[_artId].title).length > 0, "Art does not exist");
        return arts[_artId].mediaUrl;
    }

    function previewUrl(uint256 _artId) external view returns (string memory) {
        require(bytes(arts[_artId].title).length > 0, "Art does not exist");
        return arts[_artId].previewUrl;
    }

    function transferArt(address to, uint256 _artId, uint256 _amount) external {
        require(balanceOf(msg.sender, _artId) >= _amount, "Not enough balance");
        _safeTransferFrom(msg.sender, to, _artId, _amount, "");
        emit ArtTransferred(_artId, msg.sender, to, _amount);
    }

    function getArt(uint256 _artId) external view returns (Art memory) {
        return arts[_artId];
    }

    function getArtCount() external view returns (uint256) {
        return _artIdCounter.current();
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

// FanMintCollectibles contract deployed to: 0xA8e2D0949d6A3457CE4bf128aC754Fc9fcc0970E
