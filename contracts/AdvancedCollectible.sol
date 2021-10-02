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

    //mappings...future implementations would have all this into a customized struct
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

    /// Function we wanna call when we create an nft... calls VRF<userProvidedSeed> to generate random number to make us an nft ///
    // userProvidedSeed- number that we input that chainlink vrf will use to prove whether rand we get is truly rand
    // URI- A distinct Uniform Resource Identifier (URI) for a given asset. 
    // URI can be an API call, IPFS Link... conceptually its a pointer that leads to a specific JSON file that conforms to the "ERC721 // Metadata JSO nSchema" 
    function createCollectible( uint256 userProvidedSeed, string memory tokenURI) public returns(bytes32){
        //when we call this function we emit a request to get rand node from offchain chainlink oracle... will respond w/ second transcation that we will define below
        
        //async randomness request to chainlink vrf...ARGS-keyhash to ensure randomness and fee is LINK... these are defined above as global vars and passed into constructor ln20
        bytes32 requestId = requestRandomness(keyHash, fee, userProvidedSeed);

        //this mapping ensures random number is mapped to correct user/caller....mapped up top in ln14
        //aka when I(msg.sender) make a request the returned value(requestID) is mapped correctly to me == requestIdToSender[requestId]
        requestIdToSender[requestId]= msg.sender;
        //same concept w tokenURI... map pointer to the JSON metadata(tokenURI) ln15
        requestIdToTokenURI[requestId]= tokenURI;

        emit requestedCollectible(requestId);  //etherum.consol.log for testing...defined in ln18
    }

    //when we call a randomness request the chainlink vrf will respond with this
    function fullfilRandomness(bytes32 requestId, uint256 randomNumber)internal override {
        //when createCollectible is fired it returns w bytes32 requestID from earlier and a verifiably random number from VRF

        //person who originally made request was mapped in ln 40 so we assign to glizzyOwner of type address
        address glizzyOwner = requestIdToSender[requestId];
        //tokenURI that we mapped out is assigned
        string memory tokenURI = requestIdToTokenURI[requestId];
        
        uint256 newItemId = tokenCounter; ///keep track of the tokens

        
        //CALL FUNCTIONS WE INHERIT FROM IMPORTED DEPENDENCIES
    //function _safeMint(
    //     address to,
    //     uint256 tokenId,
    //     bytes memory _data)
    //     internal virtual {
    //     _mint(to, tokenId);
    //     require(
    //         _checkOnERC721Received(address(0), to, tokenId, _data),
    //         "ERC721: transfer to non ERC721Receiver implementer"
    //     );
    // }
        _safeMint(glizzyOwner, newItemId);/// mint to address(glizzyOwner) the new nft(newItemId)
        _setTokenURI(newItemId, tokenURI); ///this needs to be implemented on our own atm... we just need to set the TokenURI by overriding tokenURI method with our required logic. 
        // possible solution https://ethereum.stackexchange.com/questions/93917/function-settokenuri-in-erc721-is-gone-in-openzeppelin-0-8-0-contracts

        //the randomnumber we generate will be used to pick a randombreed(for now)... this can be abstracted to generate all sorts of rndom qualities and traits but this is a basic implementation of the concept
        //use modulo operator to get number from random number that will be 0,1 or 2(len of sausage array)... modulo% divides random number by len.sausageArray generating an index 
        //that index will determine which glizzy its gonna be bc of the enum declaration on ln8
        //so sausage of type sausage is init by calling the % operator on the randomnumber from VRF generating an index... creating an object 
        //obj sausageAttr = Sausage[index] 
        //ex return Sausage[0] is a Coney
        Sausage sausageAttr = Sausage(randomNumber % 3);

        //map randomized sausage to tokenId(NFT)
        //future implementations would be a struct rather than individual mappings
        //sausage[NFT]
        tokenIdToSausage[newItemId] = sausageAttr;

        //testing and iter token counter
        requestIdToTokenId = newItemId;
        tokenCounter = tokenCounter + 1;
    }
}