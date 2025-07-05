// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Groupie is ERC721, Ownable {
    struct Art {
        address payable artist;
        string artworkURI;
        string musicURI;
        uint256 price;
        uint256 availableMints;
        uint256 mintedCount;
    }

    uint256 public nextArtId;
    uint256 public nextTokenId;

    mapping(uint256 => Art) public arts;
    mapping(uint256 => uint256) public tokenToArt;
    mapping(address => uint256[]) public fanTokens;

    event ArtUploaded(
        uint256 indexed artId,
        address indexed artist,
        string artworkURI,
        string musicURI,
        uint256 price,
        uint256 availableMints
    );

    event ArtMinted(
        uint256 indexed artId,
        uint256 indexed tokenId,
        address indexed fan,
        address artist,
        uint256 price
    );

    constructor() ERC721("GroupieLove", "GRP") Ownable() {}

    function uploadArt(
        string calldata artworkURI,
        string calldata musicURI,
        uint256 price,
        uint256 availableMints
    ) external {
        require(bytes(artworkURI).length > 0, "Artwork URI required");
        require(price > 0, "Price must be > 0");
        require(availableMints > 0, "Must have available mints");

        arts[nextArtId] = Art({
            artist: payable(msg.sender),
            artworkURI: artworkURI,
            musicURI: musicURI,
            price: price,
            availableMints: availableMints,
            mintedCount: 0
        });

        emit ArtUploaded(
            nextArtId,
            msg.sender,
            artworkURI,
            musicURI,
            price,
            availableMints
        );
        nextArtId++;
    }

    function mintArt(uint256 artId) external payable {
        require(artId < nextArtId, "Invalid artId");
        Art storage art = arts[artId];

        require(art.mintedCount < art.availableMints, "No mints left");
        require(msg.value >= art.price, "Insufficient payment");

        uint256 tokenId = nextTokenId;
        nextTokenId++;

        _safeMint(msg.sender, tokenId);

        tokenToArt[tokenId] = artId;
        fanTokens[msg.sender].push(tokenId);

        art.mintedCount++;

        (bool success, ) = art.artist.call{value: art.price}("");
        require(success, "Transfer to artist failed");

        if (msg.value > art.price) {
            payable(msg.sender).transfer(msg.value - art.price);
        }

        emit ArtMinted(artId, tokenId, msg.sender, art.artist, art.price);
    }

    function getFanTokens(
        address fan
    ) external view returns (uint256[] memory) {
        return fanTokens[fan];
    }

    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return _exists(tokenId);
    }

    function tokenArt(
        uint256 tokenId
    )
        public
        view
        returns (
            address artist,
            string memory artworkURI,
            string memory musicURI,
            uint256 price
        )
    {
        require(_tokenExists(tokenId), "Token does not exist");
        uint256 artId = tokenToArt[tokenId];
        Art storage art = arts[artId];
        return (art.artist, art.artworkURI, art.musicURI, art.price);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        uint256 artId = tokenToArt[tokenId];
        return arts[artId].artworkURI;
    }
}

// Groupie contract deployed to: 0x97E1B3b1d173BBD3CB59D27E103DCE0803406362
