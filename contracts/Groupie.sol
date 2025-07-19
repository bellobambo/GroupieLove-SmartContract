// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FanMintCollectibles is ERC1155, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _artIdCounter;

    struct Art {
        string title;
        string artistName;
        address artistWallet;
        string mediaUrl; // Image/audio/video URL
        string previewImage; // Optional cover art
        uint256 price; // Price per copy in ETH (displayed as decimal)
        uint256 totalMinted; // Number of NFTs minted so far
        uint256 maxSupply; // Max supply of this NFT
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

    /// @notice Artist uploads a new art piece to the platform
    function uploadArt(
        string memory _title,
        string memory _artistName,
        string memory _mediaUrl,
        string memory _previewImage,
        uint256 _price, // Now in ETH (e.g., 0.001 ETH)
        uint256 _maxSupply
    ) external {
        require(_price > 0, "Price must be greater than 0");
        require(_maxSupply > 0, "Supply must be greater than 0");

        uint256 newArtId = _artIdCounter.current();
        arts[newArtId] = Art({
            title: _title,
            artistName: _artistName,
            artistWallet: msg.sender,
            mediaUrl: _mediaUrl,
            previewImage: _previewImage,
            price: _price,
            totalMinted: 0,
            maxSupply: _maxSupply
        });

        _artIdCounter.increment();
        emit ArtUploaded(newArtId, msg.sender, _title);
    }

    /// @notice Fans mint (buy) an art NFT
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

        // Revenue split
        uint256 artistShare = (msg.value * 85) / 100;
        uint256 ownerShare = msg.value - artistShare;

        payable(art.artistWallet).transfer(artistShare);
        payable(owner()).transfer(ownerShare);

        _mint(msg.sender, _artId, _amount, "");
        art.totalMinted += _amount;

        emit ArtMinted(_artId, msg.sender, _amount);
    }

    /// @notice Transfer owned art NFT to another user
    function transferArt(address to, uint256 _artId, uint256 _amount) external {
        require(balanceOf(msg.sender, _artId) >= _amount, "Not enough balance");
        _safeTransferFrom(msg.sender, to, _artId, _amount, "");
        emit ArtTransferred(_artId, msg.sender, to, _amount);
    }

    /// @notice Get full metadata for an art
    function getArt(uint256 _artId) external view returns (Art memory) {
        return arts[_artId];
    }

    /// @notice Get total number of artworks created
    function getArtCount() external view returns (uint256) {
        return _artIdCounter.current();
    }
}

// new contract : 0xa9265e612543985ed1691dEED9A1117FF518aC80
