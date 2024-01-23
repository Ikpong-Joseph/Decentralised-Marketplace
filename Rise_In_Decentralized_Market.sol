// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Decentralized_Market {

    address public marketAuthority;
    address[] public marketAuthorities;
    // Address[] public sellers;
    uint256 public sellerCounter = 0;

    struct Item {
        string itemName;
        uint itemPrice;
        string itemDescription;
        uint itemQuantity;
        uint sellerID;
        address payable sellerAddress;
    }  

    Item[] items;

    // Events
    event SellerAddressSubmitted(address indexed sellerAddress);
    event SellerVerified(address indexed sellerAddress, uint sellerID);
    event ItemAdded(address indexed Seller, uint sellerID, Item);
    event ItemDeleted(uint sellerID, string itemName);
    event NewMarketAuthorityAdded(address indexed addedBy, address indexed _newMarketAuthorityAddress);
    event MarketAuthorityTransferred(address indexed transferredFrom, address indexed transferredTo);
    event FormerMarketAuthorityDeleted(address indexed formerMarketAuthority);
    event ItemPurchased(address indexed Buyer, string itemName, uint sellerID, uint itemPrice);

    // Mappings
    mapping(address => bool) sellers; // mapping to check if an address is a seller. Initialize: sellers(address/msg.sender)=true;
    mapping(address seller => Item) itemOwner;
    mapping(string itemName => Item) public findItem; // Callable by users
    mapping(uint sellerId => mapping (string itemName => Item)) public sellersItem; // Used by buyers to confirm Items by seller. Calla ble by Users. Can be used to find item price or qty left.
    mapping (address => uint sellerID) hasSellerID;


    constructor(){
        marketAuthority = msg.sender;
    }


    // Modifiers
    modifier onlyMarketAuthority{
        for (uint i = 0; i < marketAuthorities.length; i++) {
            if (marketAuthorities[i] == msg.sender) {
                // Authority found, proceed with function logic
                _;
                return; // Exit the modifier after successful check
            }
        }
        require(false, "You must be a market authority to call this."); // Revert if not found

    }

    modifier onlySeller {
        require(hasSellerID[msg.sender] != 0, "Only verified sellers allowed to call this"); // OR Iterate through sellers[]
        _;
    }


    // Functions
    function transferMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        marketAuthority = _newMarketAuthorityAddress;
        marketAuthorities.push(_newMarketAuthorityAddress);
        emit MarketAuthorityTransferred(msg.sender, _newMarketAuthorityAddress);

        uint256 authorityIndex = marketAuthorities.length; // Start from the end
        for (uint256 i = 0; i < authorityIndex; i++) {
            if (marketAuthorities[i] == msg.sender) {
                authorityIndex = i;
                break; // Found the index, exit the loop
            }
        }

        // Delete the authority at the found index
        delete marketAuthorities[authorityIndex];
        emit FormerMarketAuthorityDeleted(msg.sender);
    }

    function addNewMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        marketAuthorities.push(_newMarketAuthorityAddress);
        emit NewMarketAuthorityAdded(msg.sender, _newMarketAuthorityAddress);
    }

    function addItem(string memory itemName, uint itemPrice, string memory itemDescription, uint itemQuantity, uint sellerID, address payable sellerAddress) public onlySeller{
        Item memory item = Item(itemName, itemPrice, itemDescription, itemQuantity, sellerID, sellerAddress);
        items.push(item);

        itemOwner[sellerAddress] = item;
        findItem[itemName] = item;
        sellersItem[sellerID][itemName] = item;

        emit ItemAdded(msg.sender, sellerID, item);
        
    }

    function deleteItem(uint sellerID, string memory itemName) public onlySeller {
        require(sellersItem[sellerID][itemName].sellerAddress != address(0), "Item not found."); // Check for valid owner

        /* sellersItem[sellerID][itemName].sellerAddress != address(0) verifies that the Item struct exists 
        and has a valid owner (not the zero address), indicating that the item is present and eligible for deletion.
        */

        // Additional checks (optional)
        // - Check for pending purchases or other restrictions

        // Delete the item
        delete sellersItem[sellerID][itemName];

        // Emit an event for tracking
        emit ItemDeleted(sellerID, itemName);
    }

    // Function for wannabe sellers to submit their addresses
    function submitSellerAddress() public {
        require(!sellers[msg.sender], "Address already submitted");
        sellers[msg.sender] = true;
        emit SellerAddressSubmitted(msg.sender);
    }

    function generateSellerID() private returns (uint) {
        // Choose your preferred method:

        // 1. Incrementing Counter:
        uint sellerId = sellerCounter++;

        // 2. Using Timestamp and Counter:
        // uint sellerId = uint(block.timestamp) + sellerCounter++;

        // 3. Hashing Address and Timestamp:
        // uint sellerId = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));

        // 4. External Oracle (e.g., Chainlink VRF):
        // // ... code to request a random value from Chainlink VRF ...
        // uint sellerId = ...;

        return sellerId;
    }

    // Function for marketAuthorities to verify addresses and assign sellerIDs
    function verifySellerAddress(address payable sellerAddress) public onlyMarketAuthority {
        require(sellers[sellerAddress], "Address not submitted");
        require(hasSellerID[sellerAddress] == 0, "Seller already has an ID");
        uint sellerID = generateSellerID(); // Implement your ID generation logic here
        hasSellerID[sellerAddress] = sellerID;
        emit SellerVerified(sellerAddress, sellerID);
    }

    function getSellerID(address payable sellerAddress) public view onlySeller returns(uint){
        return hasSellerID[sellerAddress];
    }

    function buyItem(string memory itemName, uint sellerID) public payable {
        // 1. Validate item existence and seller:
        require(sellersItem[sellerID][itemName].sellerAddress != address(0), "Item not found or invalid seller.");

        // 2. Ensure sufficient funds from buyer:
        require(msg.value >= sellersItem[sellerID][itemName].itemPrice, "Insufficient funds to purchase item.");

        // 3. Check item availability:
        require(sellersItem[sellerID][itemName].itemQuantity > 0, "Item out of stock.");

        // 4. Transfer funds to seller:
        sellersItem[sellerID][itemName].sellerAddress.transfer(sellersItem[sellerID][itemName].itemPrice);

        // 5. Update item quantity:
        sellersItem[sellerID][itemName].itemQuantity--;

        // 6. Emit purchase event:
        emit ItemPurchased(msg.sender, itemName, sellerID, sellersItem[sellerID][itemName].itemPrice);

        // 7. (Optional) Initiate escrow or delivery process:
        /* - If using escrow, create an escrow contract instance and transfer funds
        if (usingEscrow) {
            DecentralizedMarketEscrow escrow = new DecentralizedMarketEscrow(msg.sender, sellersItem[sellerID][itemName].sellerAddress);
            escrow.deposit{value: sellersItem[sellerID][itemName].itemPrice}(); // Transfer funds to escrow

            // Store escrow address for later tracking and resolution
            sellersItem[sellerID][itemName].escrowAddress = address(escrow);
        } else {
            // Direct transfer to seller (no escrow)
            sellersItem[sellerID][itemName].sellerAddress.transfer(sellersItem[sellerID][itemName].itemPrice);
        }
        */
        
        // - If physical delivery, initiate shipping or delivery mechanisms
    }



}






