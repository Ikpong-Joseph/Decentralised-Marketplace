// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/************************************ ERRORS ***********************************************/

error Not_Market_Authority();
error Not_Seller();
error Item_Already_Exist();
error Invalid_SellerID();
error Invalid_Item();
error Seller_Address_Already_Submitted();
error Seller_Address_Not_Submitted();
error Seller_Has_ID();
error Insufficient_Amount();
error Out_Of_Stock();
error No_balance_to_withdraw();


contract Decentralized_Market {
    
    /************************************ DATA ***********************************************/

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


   /**************************************** EVENTS ********************************************/

    event SellerAddressSubmitted(address indexed sellerAddress);
    event SellerVerified(address indexed sellerAddress, uint sellerID);
    event ItemAdded(address indexed Seller, uint sellerID, Item);
    event ItemDeleted(uint sellerID, string itemName);
    event NewMarketAuthorityAdded(address indexed addedBy, address indexed _newMarketAuthorityAddress);
    event MarketAuthorityTransferred(address indexed transferredFrom, address indexed transferredTo);
    event FormerMarketAuthorityDeleted(address indexed formerMarketAuthority);
    event ItemPurchased(address indexed Buyer, string itemName, uint sellerID, uint itemPrice);


    /**************************************** MAPPINGSS *******************************************/

    mapping(address sellerAddress => bool) sellers; // mapping to check if an address is a seller.
    mapping(string itemName => Item[]) findItem;
    mapping(uint sellerId => mapping (string itemName => Item)) public sellersItem; // Used by buyers to confirm Items by seller. 
    mapping (address sellerAddress => uint sellerID) public hasSellerID;
    mapping(address marketAuthority => bool) public marketAuthorities;
    mapping(address => uint256) sellersBalances;
    mapping(address seller => Item) itemOwner;




    constructor(){
        marketAuthority = msg.sender;
        marketAuthorities[msg.sender] = true;
    }


    /******************************************** MODIFIERS *****************************************/

   
    modifier onlyMarketAuthority {
        if(!marketAuthorities[msg.sender]){revert Not_Market_Authority();}
        _;
    }

    modifier onlySeller {
        if(hasSellerID[msg.sender] == 0){revert Not_Seller();}
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
        if(bytes(sellersItem[sellerID][itemName].itemName).length != 0){revert Item_Already_Exist();}
        if(hasSellerID[msg.sender] != sellerID){revert Invalid_SellerID();}
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
        if(hasSellerID[msg.sender] != sellerID){revert Invalid_SellerID();}
        if(sellersItem[sellerID][itemName].sellerAddress == address(0)){revert Invalid_Item();} // Check for valid owner
        

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
        if(sellers[msg.sender]){revert Seller_Address_Already_Submitted();}
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
        if(!sellers[sellerAddress]){revert Seller_Address_Not_Submitted();}
        if(hasSellerID[sellerAddress] != 0){revert Seller_Has_ID();}
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

        if(sellersItem[sellerID][itemName].sellerAddress == address(0)){revert Invalid_Item();}
       // 2. Ensure sufficient funds from buyer:
        uint requiredAmount = sellersItem[sellerID][itemName].itemPrice;
        if(msg.value < requiredAmount){revert Insufficient_Amount();}

        // 3. Check item availability:
        if(sellersItem[sellerID][itemName].itemQuantity == 0){revert Out_Of_Stock();}

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
        if(balance <= 0){revert No_balance_to_withdraw();}

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
