// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;


contract L2VRFHyperlaneBroadcaster {

    address public mainContractAddress;
    address public hyperlaneReceiver;

    event RandomnessRequestSentToL1(uint256 indexed collectionId);

    uint number;
    uint256 gasAmount = 300000;

    uint32 constant sepoliaDomain = 11155111;
    address constant astriaMailbox = 0x1c1bC3C040EB3C1B2215F64CfcE56Ad98300ce0e;
    IInterchainGasPaymaster igp = IInterchainGasPaymaster(
        0x0000000000000000000000000000000000000000
    );

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    address owner;
   

    constructor(address _hyperlaneReceiver) {
        owner = msg.sender;
        hyperlaneReceiver = _hyperlaneReceiver;
    }

    modifier onlyMainContract() {
        require(msg.sender == mainContractAddress);
        _;    
    }

    function getRandomSeed(uint collectionId) external payable {

        bytes32 messageId = IMailbox(astriaMailbox).dispatch(
            sepoliaDomain,
            addressToBytes32(hyperlaneReceiver),
            abi.encode(false, collectionId)
        );


        // Pay from the contract's balance
        igp.payForGas{ value: msg.value }(
            messageId, // The ID of the message that was just dispatched
            sepoliaDomain, // The destination domain of the message
            1200000,
            address(tx.origin) // refunds are returned to transaction executer
        );

        emit RandomnessRequestSentToL1(collectionId);
    }

        function getProof(            
            uint256 collectionId,
            address userAddress,
            uint256 root,
            uint256 nullifierHash,
            uint256[8] memory proof
            ) external payable {

        bytes32 messageId = IMailbox(astriaMailbox).dispatch(
            sepoliaDomain,
            addressToBytes32(hyperlaneReceiver),
            abi.encode(true, collectionId, userAddress, root, nullifierHash, proof)
        );


        // Pay from the contract's balance
        igp.payForGas{ value: msg.value }(
            messageId, // The ID of the message that was just dispatched
            sepoliaDomain, // The destination domain of the message
            gasAmount,
            address(tx.origin) // refunds are returned to transaction executer
        );

        emit RandomnessRequestSentToL1(collectionId);
    }

    function setMainContractAddressOnce(address newMainAddress) external { //set to once
        require(msg.sender == owner, "not owner");
        owner = address(0);
        mainContractAddress = newMainAddress;
    }

    receive() external payable {}

    function deposit() external payable {}

    function withdraw() external {
        payable(owner).transfer(address(this).balance);
    }


}

interface IMailbox {
        function dispatch(
        uint32 _destination,
        bytes32 _recipient,
        bytes calldata _body
    ) external returns (bytes32);
}

interface IInterchainGasPaymaster {


    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
     * Callers should be aware that this may present reentrancy issues.
     * @param _messageId The ID of the message to pay for.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @param _refundAddress The address to refund any overpayment to.
     */
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasAmount The amount of destination gas to pay for.
     * @return The amount of native tokens required to pay for interchain gas.
     */
    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}