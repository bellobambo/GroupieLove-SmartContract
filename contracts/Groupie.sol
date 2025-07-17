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
        string mediaUrl; // image/audio/video
        string previewImage; // optional cover art
        uint256 priceInWei; // price per copy
        uint256 totalMinted;
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

    /// @notice Artist uploads new art piece
    function uploadArt(
        string memory _title,
        string memory _artistName,
        string memory _mediaUrl,
        string memory _previewImage,
        uint256 _priceInEther
    ) external {
        require(_priceInEther > 0, "Price must be greater than 0");

        uint256 newArtId = _artIdCounter.current();
        arts[newArtId] = Art({
            title: _title,
            artistName: _artistName,
            artistWallet: msg.sender,
            mediaUrl: _mediaUrl,
            previewImage: _previewImage,
            priceInWei: _priceInEther * 1 ether,
            totalMinted: 0
        });

        _artIdCounter.increment();

        emit ArtUploaded(newArtId, msg.sender, _title);
    }

    /// @notice Fans mint art piece
    function mintArt(uint256 _artId, uint256 _amount) external payable {
        Art storage art = arts[_artId];
        require(bytes(art.title).length > 0, "Art does not exist");
        require(_amount > 0, "Must mint at least 1");
        uint256 totalPrice = art.priceInWei * _amount;
        require(msg.value >= totalPrice, "Insufficient payment");

        // Revenue split
        uint256 artistShare = (totalPrice * 85) / 100;
        uint256 ownerShare = totalPrice - artistShare;

        payable(art.artistWallet).transfer(artistShare);
        payable(owner()).transfer(ownerShare);

        _mint(msg.sender, _artId, _amount, "");
        art.totalMinted += _amount;

        emit ArtMinted(_artId, msg.sender, _amount);
    }

    /// @notice Users transfer owned art to others
    function transferArt(address to, uint256 _artId, uint256 _amount) external {
        require(balanceOf(msg.sender, _artId) >= _amount, "Not enough balance");
        _safeTransferFrom(msg.sender, to, _artId, _amount, "");
        emit ArtTransferred(_artId, msg.sender, to, _amount);
    }

    /// @notice Get details of an art piece
    function getArt(uint256 _artId) external view returns (Art memory) {
        return arts[_artId];
    }
}

// new contract : 0x9aD0Be3213eD3484d786d2B78Ef5C6B8500478D1
