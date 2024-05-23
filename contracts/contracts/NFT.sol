// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SoulboundNameService is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("MyToken", "MTK") {}

    function safeMint(address _recipient) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(_recipient, tokenId);
    }

    //Collection1 - 7 items: bafybeiedpguw6nwqxuhmo7av6nfkilfr2azgvagmavh5env77auwot4cx4
    //Collection2 - 5 items: bafybeiek6lo4j3jqnd7zilj62sg7fw4vjyipiep76fs6o7qjewjti526yy
    //Collection3 - 4 items: bafybeidv2anlomhe2hklnlji6fpk3iq4vmaymiq2xugqi5iuylt2ek4dbe

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeiequh7ru4fxtl52fhwsznhiq2xxqjsqqe23pbmmpxz7cqoenpcw6a/";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory baseURI = _baseURI();
        string memory metadataPointerId = Strings.toString(tokenId+1);
        string memory result = string(abi.encodePacked(baseURI, metadataPointerId, ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }
}
