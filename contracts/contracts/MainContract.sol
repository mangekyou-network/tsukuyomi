// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import { ByteHasher } from './libraries/ByteHasher.sol';
import { IWorldID } from './libraries/IWorldID.sol';
import { ByteHasher } from './libraries/ByteHasher.sol';
import {IInterchainSecurityModule, ISpecifiesInterchainSecurityModule} from "https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/main/solidity/contracts/interfaces/IInterchainSecurityModule.sol";


interface IMessageRecipient {
    function handle(
        uint32 _origin, //Domain id of the sender chain
        bytes32 _sender,
        bytes calldata _body
    ) external;
}

contract Tsukuyomi is ISpecifiesInterchainSecurityModule, IMessageRecipient {
    using ByteHasher for bytes;

    address public L2_VRF_BROADCAST_ADDRESS;
    L2VRFHyperlaneBroadcaster hyperlaneBroadcaster;

    address public L1_VRF_RECEIVER_ADDRESS; 

    string constant APP_ID = "app_staging_aa5628b6d38113bc3507c644c5bf5630";
    string constant ACTION = "verify_credibilities";

    IInterchainSecurityModule public interchainSecurityModule = IInterchainSecurityModule(0x90db209b829A11a26b4D5b5020619356f62b3105);

    // HYPERLANE 
    IInterchainGasPaymaster igp = IInterchainGasPaymaster(
        0xb32687e14558C96d5a4C907003327A932356B42b
    );
    uint256 hyperlaneGas = 600000;
    uint32 constant sepoliaDomain = 11155111;

    address constant astriaMailbox = 0x1c1bC3C040EB3C1B2215F64CfcE56Ad98300ce0e;


    mapping(uint256 => bool) public nullifierHashes;

    // Mapping of participant addresses to their soulbound NFTs
    mapping(address => uint256) public participantNFTs;


    // Soulbound NFT contract
    // SoulboundNameService public soulboundNFT = SoulboundNameService(0xb32687e14558C96d5a4C907003327A932356B42b);

    // Event emitted when a participant is awarded a soulbound NFT
    event SoulboundNFTClaimed(address indexed participant, uint256 indexed NFTId);

    mapping(address => bool) public verifiedUsers;

    event ParticipantSentProof(address indexed participant, uint256 indexed collectionId);
    event ParticipantAdded(address indexed participant, uint256 indexed collectionId);
    event WrongProof(address indexed participant, uint256 indexed collectionId);
    event GiveawayExecuted(uint256 indexed collectionId);

    constructor(address _L1_VRF_RECEIVER_ADDRESS, address _L2_VRF_BROADCAST_ADDRESS) {
        L2_VRF_BROADCAST_ADDRESS = _L2_VRF_BROADCAST_ADDRESS;
        L1_VRF_RECEIVER_ADDRESS = _L1_VRF_RECEIVER_ADDRESS;
        hyperlaneBroadcaster = L2VRFHyperlaneBroadcaster(L2_VRF_BROADCAST_ADDRESS);
    }

    function beParticipant(
        uint marketplaceId,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) external payable {
        require(!nullifierHashes[nullifierHash], "reused nullifier");

        address msgSender = msg.sender;
        require(msg.value >= 0, "not enough ethers");

        nullifierHashes[nullifierHash] = true;

        emit ParticipantSentProof(msgSender, marketplaceId);

        hyperlaneBroadcaster.getProof{value: msg.value}(marketplaceId, msgSender, root, nullifierHash, proof);
    }

    modifier onlyMailbox() {
        require(msg.sender == astriaMailbox);
        _;    
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external onlyMailbox {
        //require( bytes32ToAddress(_sender) == L1HyperlaneBroadcaster, "not L2 broadcaster");
    
        uint marketplaceId;
        address msgSender;
        bool proofResult;
        uint nullifierHash;
        (marketplaceId, msgSender, proofResult, nullifierHash) = abi.decode(_body, (uint, address, bool, uint));

        if (!nullifierHashes[nullifierHash] && proofResult) {
            nullifierHashes[nullifierHash] = true;
             verifiedUsers[msgSender] = true;
            emit ParticipantAdded(msgSender, marketplaceId);
        } else {
            emit WrongProof(msgSender, marketplaceId);
        }
    }

    function sendVRFRequest(uint marketplaceID) external payable {
        require(msg.value >= getRequiredGasForHyperlane(), "not enough gas for hyperlane");
        hyperlaneBroadcaster.getRandomSeed{value: msg.value}(marketplaceID);
    }

    function submitRandomSeed(bytes calldata parameters) external onlyMailbox {
        uint256 collectionId;
        uint256 seed;
        (collectionId, seed) = abi.decode(parameters, (uint256, uint256));
        emit GiveawayExecuted(collectionId);
    }

    function claimSoulboundNFT() external {
        require(verifiedUsers[msg.sender], "User is not verified");
        // soulboundNFT.safeMint(msg.sender);
        // participantNFTs[msg.sender] = NFTId;
        //emit SoulboundNFTClaimed(msg.sender, NFTId);
    }

    function getRequiredGasForHyperlane() public view returns (uint256) {
        return igp.quoteGasPayment(sepoliaDomain, hyperlaneGas);
    }

}

interface L2VRFHyperlaneBroadcaster {
    function getRandomSeed(uint collectionId) external payable;
    function getProof(
        uint256 collectionId,
        address userAddress,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] memory proof
    ) external payable;
}

interface IInterchainGasPaymaster {
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount) external view returns (uint256);
}
