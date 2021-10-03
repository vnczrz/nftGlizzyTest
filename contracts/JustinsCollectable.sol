// SPDX-License-Identifier: MIT

// !!! Followed this vid, starts at 10hrs for the adv contract !!!
// https://www.youtube.com/watch?v=M576WGiDBdQ&t=36143s&ab_channel=freeCodeCamp.org

pragma solidity ^0.8.0;
// inherit contract from openzepplin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import chainlink vrf to get proven random #
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract JustinsCollectable is ERC721, VRFConsumerBase {
    uint256 public tokenCounter;
    bytes32 public keyhash;
    uint256 public fee;

    enum Adjective {
        GAY_BEAR,
        AUTIST,
        ACTUALLY_RETARDED
    }

    // allow the setting of a uint256 to the type Adjective
    mapping(uint256 => Adjective) public tokenIdToAdjective;
    // allow the setting of a byte32 to an address;
    mapping(bytes32 => address) public requestIdToSender;
    // GOOD PRACTICE
    // create an event everytime a mapping update happens
    // this event gets emitted when we assign requestId to msg.sender
    event collectableRequested(bytes32 indexed requestId, address requester);
    // this event get emitted when we assign an adjective (metadata) to a newTokenId (nft)
    event adjectiveAssigned(uint256 indexed tokenId, Adjective adjective);

    constructor(
        address _vrfCoordinator, // for VRFConsumerBase
        address _linkToken, // for VRFConsumerBase
        bytes32 _keyhash,
        uint256 _fee
    )
        public
        VRFConsumerBase(_vrfCoordinator, _linkToken)
        ERC721("Justin", "GAY")
    {
        tokenCounter = 0;
        keyhash = _keyhash;
        fee = _fee;
    }

    // we want the user to calls createCollectable to be the one who gets the tokenId
    function createCollectable() public returns (bytes32) {
        // create request to get random number
        bytes32 requestId = requestRandomness(keyhash, fee);
        // create mapping for the requestId and send it to whoever requested it (msg.sender)
        requestIdToSender[requestId] = msg.sender;
        emit collectableRequested(requestId, msg.sender);
    }

    // after we get the random number back, we then choose an adjective ln14
    // internal is called so that only VRFCoordinator can call this func()
    // once this func() is ran, the value of the adjective used to describe Justin will be set
    function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
        internal
        override
    {
        // var adjective = type Adjective
        Adjective adjective = Adjective(randomNumber % 3);
        // get tokenId
        uint256 newTokenId = tokenCounter;
        // assign an the adjective picked from ln56 to the tokenId (the nft)
        // this is achieved from the mapping on ln21~
        tokenIdToAdjective[newTokenId] = adjective;
        emit adjectiveAssigned(newTokenId, adjective);
        // take the requestId (random number) and map it to the sender (owner)
        address owner = requestIdToSender[requestId];
        _safeMint(owner, newTokenId);
        //   _setTokenURI(newTokenId, tokenURI);
        // increase tokenCounter by 1
        tokenCounter = tokenCounter + 1;
    }

    // https://www.youtube.com/watch?v=M576WGiDBdQ&t=36143s&ab_channel=freeCodeCamp.org
    // 10:35:32 goes over this
    // TODO map setTokenURI up top in mapping section once youre not a fucking retard and become an autist
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        // gay bear, autist, actually retarded
        // make it so the ownder of the tokenId (nft) can update the _tokenURI (metadata)
        require(
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/token/ERC721/ERC721.sol
            // search for _isApprovedOrOwner func() ln 234~
            // checks the owner of the ERC721 tokenId
            // only the owner or someone approved to work with tokenId can change the tokenURI
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not owner nor approved"
        );
        setTokenURI(tokenId, _tokenURI);
    }
}
