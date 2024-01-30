// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


contract Decentralized_Market {

    /****************** DATA ****************/

    address public marketAuthority;
    //address[] public marketAuthorities;
    address[] sellersToBeVerified;
    uint256 sellerCounter = 1;
   

    struct Item {
        string itemName;
        uint itemPrice;
        string itemDescription;
        uint itemQuantity;
        uint sellerID;
        address payable sellerAddress;
    }  

    Item[] items;


   /****************** EVENTS ****************/

    event SellerAddressSubmitted(address indexed sellerAddress);
    event SellerVerified(address indexed sellerAddress, uint sellerID);
    event ItemAdded(address indexed Seller, uint sellerID, Item);
    event ItemDeleted(uint sellerID, string itemName);
    event NewMarketAuthorityAdded(address indexed addedBy, address indexed _newMarketAuthorityAddress);
    event MarketAuthorityTransferred(address indexed transferredFrom, address indexed transferredTo);
    event FormerMarketAuthorityDeleted(address indexed formerMarketAuthority);
    event ItemPurchased(address indexed Buyer, string itemName, uint sellerID, uint itemPrice);


    /****************** MAPPINGSS ****************/

    mapping(address sellerAddress => bool) sellers; // mapping to check if an address is a seller. Initialize: sellers(address/msg.sender)=true;
    mapping(address seller => Item) itemOwner;
    mapping(string itemName => Item[]) findItem;
    mapping(uint sellerId => mapping (string itemName => Item)) public sellersItem; // Used by buyers to confirm Items by seller. Calla ble by Users. Can be used to find item price or qty left.
    mapping (address sellerAddress => uint sellerID) public hasSellerID;
    mapping(address marketAuthority => bool) public marketAuthorities;
    mapping(address => uint256) sellersBalances;




    constructor(){
        marketAuthority = msg.sender;
        marketAuthorities[msg.sender] = true;
    }


    /******************************************** MODIFIERS *****************************************/

   
    modifier onlyMarketAuthority {
        require(marketAuthorities[msg.sender], "You must be a market authority to call this.");
        _;
    }

    modifier onlySeller {
        require(hasSellerID[msg.sender] != 0, "Only verified sellers allowed to call this");
        _;
    }


    /**************************************** FUNCTIONS ************************************************/


    function transferMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        marketAuthority = _newMarketAuthorityAddress;
       marketAuthorities[_newMarketAuthorityAddress] = true;
        emit MarketAuthorityTransferred(msg.sender, _newMarketAuthorityAddress);
        // Delete the authority at the found index
        delete marketAuthorities[msg.sender];
        emit FormerMarketAuthorityDeleted(msg.sender);
    }

    function addNewMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        marketAuthorities[_newMarketAuthorityAddress] = true;
        emit NewMarketAuthorityAdded(msg.sender, _newMarketAuthorityAddress);
    }
    
    function getItemsByName(string memory _itemName) public view returns (Item[] memory) {
        uint256 itemCount = 0;

        // Count the number of matching items
        for (uint256 i = 0; i < items.length; i++) {
            if (keccak256(abi.encodePacked(items[i].itemName)) == keccak256(abi.encodePacked(_itemName))) {
                itemCount++;
            }
        }

        // Create an array to store the matching items
        Item[] memory matchingItems = new Item[](itemCount);
        itemCount = 0;

        // Populate the array with matching items
        for (uint256 i = 0; i < items.length; i++) {
            if (keccak256(abi.encodePacked(items[i].itemName)) == keccak256(abi.encodePacked(_itemName))) {
                matchingItems[itemCount] = items[i];
                itemCount++;
            }
        }

        return matchingItems;
    }

    function addItem(string memory itemName, uint itemPrice, string memory itemDescription, uint itemQuantity, uint sellerID) public onlySeller{
        // Seller sets price in wei
        // Convert item price to Wei (ETH standard: 1e18)
        uint itemPriceInETH = itemPrice * 1e18; // Converts seller's itemPrice to ETH. Buyers sets denomination to ETH. Doesn't collect 0.xxxx.
        
        Item memory item = Item(itemName, itemPriceInETH, itemDescription, itemQuantity, sellerID, payable(msg.sender));
        require(bytes(sellersItem[sellerID][itemName].itemName).length == 0 , "Item name already exists.");
        require(hasSellerID[msg.sender] == sellerID, "Seller ID doesn't match.");
        items.push(item);
        itemOwner[payable(msg.sender)] = item;
        // findItem[itemName] = items;
        sellersItem[sellerID][itemName] = item;

        emit ItemAdded(msg.sender, sellerID, item);
        
    }

    // Function to get all items listed by sellers
    function getAllItems() public view returns (Item[] memory) {
        uint256 itemCount = 0;

        // Count the total number of items listed by sellers
        for (uint256 i = 0; i < items.length; i++) {
            if (hasSellerID[items[i].sellerAddress] != 0 &&
            sellersItem[items[i].sellerID][items[i].itemName].itemQuantity > 0) {
                itemCount++;
            }
        }

        // Create an array to store all items listed by sellers
        Item[] memory allItems = new Item[](itemCount);
        itemCount = 0;

        // Populate the array with items listed by sellers
        for (uint256 i = 0; i < items.length; i++) {
            if (hasSellerID[items[i].sellerAddress] != 0 &&
            sellersItem[items[i].sellerID][items[i].itemName].itemQuantity > 0) {
                allItems[itemCount] = items[i];
                itemCount++;
            }
        }

        return allItems;
    }

    function deleteItem(uint sellerID, string memory itemName) public onlySeller {
        require(sellersItem[sellerID][itemName].sellerAddress != address(0), "Item not found."); // Check for valid owner
        require(hasSellerID[msg.sender] == sellerID, "Seller ID doesn't match.");

         // Find the index of the item
        uint256 indexToDelete = findItemIndex(sellerID, itemName);

        // Ensure the item exists in the array
        require(indexToDelete < items.length, "Item not found");

        // Swap the item to be deleted with the last item in the array
        items[indexToDelete] = items[items.length - 1];

        // Reduce the array's length by 1
        items.pop();
        delete sellersItem[sellerID][itemName];

        // Emit an event for tracking
        emit ItemDeleted(sellerID, itemName);
    }

    function findItemIndex(uint256 sellerId, string memory itemName) internal view returns (uint256) {
        for (uint256 i = 0; i < items.length; i++) {
            if (items[i].sellerID == sellerId && keccak256(abi.encodePacked(items[i].itemName)) == keccak256(abi.encodePacked(itemName))) {
                return i;
            }
        }
        // Return a value indicating that the item was not found
        return type(uint256).max;
    }

    // Function for wannabe sellers to submit their addresses
    function submitSellerAddress() public {
        require(!sellers[msg.sender], "Address already submitted");
        sellers[msg.sender] = true;
        sellersToBeVerified.push(msg.sender);
        emit SellerAddressSubmitted(msg.sender);
    }

    // Function for market authorities to get addresses pending verification
    function getAddressesPendingVerification() public view onlyMarketAuthority returns (address[] memory) {
        return sellersToBeVerified;
    }

    // Function for marketAuthorities to verify addresses and assign sellerIDs
    function verifySellerAddress(address payable sellerAddress) public onlyMarketAuthority {
        require(sellers[sellerAddress], "Address not submitted");
        require(hasSellerID[sellerAddress] == 0, "Seller already has an ID");
        uint sellerID = sellerCounter++;
        sellers[msg.sender] = false;
        hasSellerID[sellerAddress] = sellerID;

        // Find the index of the seller in the sellersToBeVerified array
        uint256 indexToRemove;
        for (uint256 i = 0; i < sellersToBeVerified.length; i++) {
            if (sellersToBeVerified[i] == sellerAddress) {
                indexToRemove = i;
                break;
            }
        }

        // Ensure the seller is in the pending verification array
        require(indexToRemove < sellersToBeVerified.length, "Seller not found in pending verification");

        // Swap the element to be removed with the last element
        sellersToBeVerified[indexToRemove] = sellersToBeVerified[sellersToBeVerified.length - 1];

        // Reduce the array's length by 1
        sellersToBeVerified.pop();

        emit SellerVerified(sellerAddress, sellerID);
    }

    function buyItem(string memory itemName, uint sellerID) public payable {
        
        // 1. Validate item existence and seller:
        require(sellersItem[sellerID][itemName].sellerAddress != address(0), "Item not found or invalid seller.");

       // 2. Ensure sufficient funds from buyer:
        uint requiredAmount = sellersItem[sellerID][itemName].itemPrice;
        require(msg.value >= requiredAmount, "Please send enough amount required to purchase the item. Search sellersItem with item name and seller ID to verify price.");

        // 3. Check item availability:
        require(sellersItem[sellerID][itemName].itemQuantity > 0, "Item out of stock.");

        // 4. Update seller's balance:
        sellersBalances[sellersItem[sellerID][itemName].sellerAddress] += sellersItem[sellerID][itemName].itemPrice;

        // 5. Update item quantity:
        sellersItem[sellerID][itemName].itemQuantity--;

        // 6. Return excess funds to the buyer:
        if (msg.value > requiredAmount) {
            uint excessAmount = msg.value - requiredAmount;
            (bool success, ) = msg.sender.call{value: excessAmount}("");
            require(success, "Failed to return excess funds to the buyer");
        }

        // 7. Emit purchase event:
        emit ItemPurchased(msg.sender, itemName, sellerID, sellersItem[sellerID][itemName].itemPrice);

    }

    function getSellerBalance() public view onlySeller returns(uint) {
        return sellersBalances[msg.sender];
    /* 
    Had to add this in instead of viewing straight from the sellersBalances mapping
    so I could add the onlySeller restriction
    */
    }

    function withdrawBalance() public payable onlySeller {
        uint256 balance = sellersBalances[msg.sender];
        require(balance > 0, "No balance to withdraw");

        // Transfer funds to seller
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");

        // Reset seller's balance
        sellersBalances[msg.sender] = 0;
    }

    // Inside the Decentralized_Market contract (FOR TEST)

    function getItemByIndex(uint index) external view returns (Item memory) {
        require(index < items.length, "Index out of bounds");
        return items[index];
    }

}

/*
CHAINLINK ETH/USD ADDRESS ----   0x694AA1769357215DE4FAC081bf1f309aDC325306
*/