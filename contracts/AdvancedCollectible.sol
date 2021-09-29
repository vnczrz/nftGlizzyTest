pragma solidity ^0.8.0; 
// inherit contract from openzepplin
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import chainlink vrf to get proven random #
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract AdvancedCollectible is ERC721, VRFConsumerBase {
    enum Sausage{Coney, Brat, Chicago}

    bytes32 internal keyHash;
    uint256 public fee;
    uint256 tokenCounter = 0;

    mapping(bytes32 => address) public requestIdToSender;
    mapping(bytes32 => string) public requestIdToTokenURI;
    mapping(bytes32 => uint256) public requestIdToTokenId;
    mapping (uint256 => Sausage) public tokenIdToSausage;
    event requestedCollectible(bytes32 indexed requestId);
    
    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash) public
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("Glizzy", "GLIZ")
    {
        keyHash = _keyhash;
        fee = 0.1 * 10 ** 18; //0.1 LINK
    }

    // Function we wanna call when we create an nft... calls VRF<userProvidedSeed> to generate random number to make us an nft
    // A distinct Uniform Resource Identifier (URI) for a given asset. The URI may point to a JSON file that conforms to the "ERC721 // Metadata JSO nSchema"
    function createCollectible(uint256 userProvidedSeed, string memory tokenURI)
    public returns(bytes32){
        //async randomness request from chainlink vrf...keyhash to ensure randomness and fee is LINK
        bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);

        //this mapping ensures random number is mapped to correct user/caller
        requestIdToSender[requestId]= msg.sender;

        //tokenURI is API call to JSon response
        requestIdToTokenURI[requestId]= tokenURI;
        emit requestedCollectible(requestId);  //etherum console log for testing
    }

    //when we call a randomness request the chainlink vrf will respond with this
    function fullfilRandomness(bytes32 requestId, uint256 randomNumber)internal override 
    {
        address glizzyOwner = requestIdToSender[requestId];
        string memory tokenURI = requestIdToTokenURI[requestId];
        uint256 newItemId = tokenCounter;

        //call functions we inherited from openzeppelin erc721
        _safeMint(glizzyOwner, newItemId);
        _setTokenURI(newItemId, tokenURI);

        //use modulo operator to get number from random number that will be 0,1 or 2
        Sausage sausage = Sausage(randomNumber % 3);

        //newmapping sausage to tokenId
        tokenIdToSausage[newItemId] = sausage;

        //testing and iter token counter
        requestIdToTokenId = newItemId;
        tokenCounter = tokenCounter + 1;
    }
}