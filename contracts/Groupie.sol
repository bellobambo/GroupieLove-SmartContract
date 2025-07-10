// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Groupie is ERC721, Ownable {
    enum ArtCategory {
        Image,
        Music,
        Video
    }

    struct Art {
        address payable artist;
        string title;
        string artworkURI;
        string musicURI;
        uint256 price;
        uint256 availableMints;
        uint256 mintedCount;
        ArtCategory category;
    }

    uint256 public nextArtId;
    uint256 public nextTokenId;

    mapping(uint256 => Art) public arts;
    mapping(uint256 => uint256) public tokenToArt;
    mapping(address => uint256[]) public fanTokens;

    event ArtUploaded(
        uint256 indexed artId,
        address indexed artist,
        string title,
        string artworkURI,
        string musicURI,
        uint256 price,
        uint256 availableMints,
        ArtCategory category
    );

    event ArtMinted(
        uint256 indexed artId,
        uint256 indexed tokenId,
        address indexed fan,
        address artist,
        uint256 price
    );

    event TokenTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );

    constructor() ERC721("GroupieLove", "GRP") Ownable() {}

    function uploadArt(
        string calldata title,
        string calldata artworkURI,
        string calldata musicURI,
        uint256 price,
        uint256 availableMints,
        ArtCategory category
    ) external {
        require(bytes(title).length > 0, "Title required");
        require(bytes(artworkURI).length > 0, "Artwork URI required");
        require(price > 0, "Price must be > 0");
        require(availableMints > 0, "Must have available mints");

        arts[nextArtId] = Art({
            artist: payable(msg.sender),
            title: title,
            artworkURI: artworkURI,
            musicURI: musicURI,
            price: price,
            availableMints: availableMints,
            mintedCount: 0,
            category: category
        });

        emit ArtUploaded(
            nextArtId,
            msg.sender,
            title,
            artworkURI,
            musicURI,
            price,
            availableMints,
            category
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

    function transferToken(address to, uint256 tokenId) external {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "Not owner nor approved"
        );
        require(to != address(0), "Cannot transfer to zero address");

        // Remove token from sender's list
        _removeTokenFromSender(msg.sender, tokenId);

        // Transfer token
        _transfer(msg.sender, to, tokenId);

        // Add token to recipient's list
        fanTokens[to].push(tokenId);

        emit TokenTransferred(tokenId, msg.sender, to);
    }

    function _removeTokenFromSender(address sender, uint256 tokenId) internal {
        uint256[] storage tokens = fanTokens[sender];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenId) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
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
            string memory title,
            string memory artworkURI,
            string memory musicURI,
            uint256 price,
            ArtCategory category
        )
    {
        require(_tokenExists(tokenId), "Token does not exist");
        uint256 artId = tokenToArt[tokenId];
        Art storage art = arts[artId];
        return (
            art.artist,
            art.title,
            art.artworkURI,
            art.musicURI,
            art.price,
            art.category
        );
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(_tokenExists(tokenId), "Token does not exist");
        uint256 artId = tokenToArt[tokenId];
        return arts[artId].artworkURI;
    }
}

// smart contract : 0x390c8f560b2D3955364425C7E958c998aDBB6587
