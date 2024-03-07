// SPDX-License-Identifier: MIT

/* WHAT IS LEFT?
*1 Converting itemPrice from USD to ETH
*2 HelperConfig, PriceConverter and mock tests currently not in use. Intended for 1.
*3 Re-evaluating Seller Items mappings in addItem(), buyItem() and deleteItem()
*4 Interactions.s.sol
*/

pragma solidity ^0.8.18;

import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

/**
 * ERRORS **********************************************
 */
error Not_Market_Authority();
error Market_Authorities_Not_Allowed();
error Not_Seller();
error Item_Already_Exist();
error Invalid_SellerID();
error Invalid_Item();
error Seller_Address_Already_Submitted();
error Seller_Address_Not_Submitted();
error Seller_Has_ID();
error Insufficient_Amount();
error Item_Out_Of_Stock();
error No_balance_to_withdraw();
error Invalid_SellerID_Or_Invalid_Item();

contract Decentralized_Market {
    using PriceConverter for uint256;

    /**
     * DATA **********************************************
     */
    address private s_marketAuthority;
    //address[] public marketAuthorities;
    address[] private s_sellersToBeVerified;
    uint256 sellerCounter = 1;

    struct Item {
        string itemName;
        uint256 itemPrice;
        string itemDescription;
        uint256 itemQuantity;
        uint256 sellerID;
        address payable sellerAddress;
    }

    Item[] s_items;

    AggregatorV3Interface private ETHUSD_priceFeed;

    /**
     * EVENTS *******************************************
     */
    event SellerAddressSubmitted(address indexed sellerAddress);
    event SellerVerified(address indexed sellerAddress, uint256 sellerID);
    event ItemAdded(address indexed Seller, uint256 sellerID, Item);
    event ItemDeleted(uint256 sellerID, string itemName);
    event NewMarketAuthorityAdded(address indexed addedBy, address indexed _newMarketAuthorityAddress);
    event MarketAuthorityTransferred(address indexed transferredFrom, address indexed transferredTo);
    event FormerMarketAuthorityDeleted(address indexed formerMarketAuthority);
    event ItemPurchased(address indexed Buyer, string itemName, uint256 sellerID, uint256 itemPrice);

    /**
     * MAPPINGS ******************************************
     */
    mapping(address sellerAddress => bool) private s_sellers; // mapping to check if an address is a seller.
    mapping(string itemName => Item[]) private s_findItem;
    mapping(uint256 sellerId => mapping(string itemName => Item)) private s_sellersItem; // Used by buyers to confirm Items by seller.
    mapping(address sellerAddress => uint256 sellerID) private s_hasSellerID;
    mapping(address marketAuthority => bool) private s_marketAuthorities;
    mapping(address sellerAddress => uint256 balance) private s_sellersBalances;
    mapping(address seller => Item) private s_itemOwner;

    /**
     * CONSTRUCTOR ******************************************
     */
    constructor(address priceFeed) {
        s_marketAuthority = msg.sender;
        s_marketAuthorities[msg.sender] = true;
        ETHUSD_priceFeed = AggregatorV3Interface(priceFeed);
        /**
         * ADDED ******
         */
    }

    /**
     * MODIFIERS ****************************************
     */
    modifier onlyMarketAuthority() {
        if (!s_marketAuthorities[msg.sender]) {
            revert Not_Market_Authority();
        }
        _;
    }

    modifier onlySeller() {
        if (s_hasSellerID[msg.sender] == 0) {
            revert Not_Seller();
        }
        _;
    }

    /**
     * FUNCTIONS ***********************************************
     */
    function transferMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        s_marketAuthority = _newMarketAuthorityAddress;
        s_marketAuthorities[_newMarketAuthorityAddress] = true;
        emit MarketAuthorityTransferred(msg.sender, _newMarketAuthorityAddress);

        // Delete the authority at the found index

        delete s_marketAuthorities[msg.sender];
        emit FormerMarketAuthorityDeleted(msg.sender);
    }

    function addNewMarketAuthority(address _newMarketAuthorityAddress) public onlyMarketAuthority {
        s_marketAuthorities[_newMarketAuthorityAddress] = true;
        emit NewMarketAuthorityAdded(msg.sender, _newMarketAuthorityAddress);
    }

    function getItemsByName(string memory _itemName) public view returns (Item[] memory) {
        uint256 itemCount = 0;

        // Count the number of matching items
        uint256 itemsLength = s_items.length;
        for (uint256 i = 0; i < itemsLength; i++) {
            if (keccak256(abi.encodePacked(s_items[i].itemName)) == keccak256(abi.encodePacked(_itemName))) {
                itemCount++;
            }
        }

        // Create an array to store the matching items
        Item[] memory matchingItems = new Item[](itemCount);
        itemCount = 0;

        // Populate the array with matching items
        for (uint256 i = 0; i < itemsLength; i++) {
            if (keccak256(abi.encodePacked(s_items[i].itemName)) == keccak256(abi.encodePacked(_itemName))) {
                matchingItems[itemCount] = s_items[i];
                itemCount++;
            }
        }

        return matchingItems;
    }

    /// Input item's price in USD value.
    function addItem(
        string memory itemName,
        uint256 itemPriceInUSD,
        string memory itemDescription,
        uint256 itemQuantity,
        uint256 sellerID
    ) public onlySeller {
        // Seller sets price in wei

        // Convert item price to Wei (ETH standard: 1e18)

        // uint itemPriceInETH = itemPrice * 1e18; // Converts seller's itemPrice to ETH. Buyers sets denomination to ETH. Doesn't collect 0.xxxx.

        // uint256 ethPrice = PriceConverter.getConversionRate(itemPriceInUSD, ETHUSD_priceFeed);
        // uint256 sellerID = s_hasSellerID[msg.sender];
        Item memory item = Item(
            itemName,
            // itemPriceInETH,
            itemPriceInUSD,
            // ethPrice,
            itemDescription,
            itemQuantity,
            sellerID,
            payable(msg.sender)
        );

        if (bytes(s_sellersItem[sellerID][itemName].itemName).length != 0) {
            revert Item_Already_Exist();
        }

        if (s_hasSellerID[msg.sender] != sellerID) {
            revert Invalid_SellerID();
        }

        s_items.push(item);

        s_itemOwner[payable(msg.sender)] = item;

        s_findItem[itemName] = s_items;

        s_sellersItem[sellerID][itemName] = item;

        emit ItemAdded(msg.sender, sellerID, item);
    }
    // function getAllItems() public view returns (Item[] memory) {
    //     return s_items;
    // }
    // Function to get all items listed by sellers

    function getSellersItem( address sellerAddress) public view returns (Item memory) {
        return s_itemOwner[sellerAddress];
    }

    function getAllItems() public view returns (Item[] memory) {
        uint256 i = 0;
        uint256 itemCount = 0;
        uint256 itemsLength = s_items.length;
        uint256 quantityOfItemBySeller = s_sellersItem[s_items[i].sellerID][s_items[i].itemName].itemQuantity;

        // Count the total number of items listed by sellers
        for (i; i < itemsLength; i++) {
            if (s_hasSellerID[s_items[i].sellerAddress] != 0 && quantityOfItemBySeller > 0) {
                itemCount++;
            }
        }

        // Create an array to store all items listed by sellers
        Item[] memory allItems = new Item[](itemCount);
        itemCount = 0;

        // Populate the array with items listed by sellers
        for (i; i < itemsLength; i++) {
            if (s_hasSellerID[s_items[i].sellerAddress] != 0 && quantityOfItemBySeller > 0) {
                allItems[itemCount] = s_items[i];
                itemCount++;
            }
        }

        return allItems;
    }

    function deleteItem(uint256 sellerID, string memory itemName) public onlySeller {
        if (s_hasSellerID[msg.sender] != sellerID) {
            revert Invalid_SellerID();
        }
        if (s_sellersItem[sellerID][itemName].sellerAddress == address(0)) {
            revert Invalid_Item();
        } // Check for valid owner

        // Find the index of the item
        uint256 indexToDelete = findItemIndex(sellerID, itemName);
        uint256 itemsLength = s_items.length;

        // Ensure the item exists in the array
        require(indexToDelete < itemsLength, "Item not found");

        // Swap the item to be deleted with the last item in the array
        s_items[indexToDelete] = s_items[itemsLength - 1];

        // Reduce the array's length by 1
        s_items.pop();
        delete s_sellersItem[sellerID][itemName];
        delete s_itemOwner[payable(msg.sender)];

        delete s_findItem[itemName];


        // Emit an event for tracking
        emit ItemDeleted(sellerID, itemName);
    }

    function findItemIndex(uint256 sellerId, string memory itemName) internal view returns (uint256) {
        uint256 itemsLength = s_items.length;

        for (uint256 i = 0; i < itemsLength; i++) {
            if (
                s_items[i].sellerID == sellerId
                    && keccak256(abi.encodePacked(s_items[i].itemName)) == keccak256(abi.encodePacked(itemName))
            ) {
                return i;
            }
        }
        // Return a value indicating that the item was not found
        return type(uint256).max;
    }

    // Function for wannabe sellers to submit their addresses
    function submitSellerAddress() public {
        for (uint256 i = 0; i < s_sellersToBeVerified.length; i++) {
            address sellerAddress = s_sellersToBeVerified[i];

            if (sellerAddress == msg.sender) {
                revert Seller_Address_Already_Submitted();
            }
        }

        if (s_hasSellerID[msg.sender] != 0) {
            //(sellerAddress != address(0))
            revert Seller_Has_ID();
        }

        if (s_marketAuthorities[msg.sender] == true) {
            revert Market_Authorities_Not_Allowed();
        }

        s_sellersToBeVerified.push(msg.sender);

        emit SellerAddressSubmitted(msg.sender);
    }

    // Function for market authorities to get addresses pending verification
    function getAddressesPendingVerification() public view onlyMarketAuthority returns (address[] memory) {
        return s_sellersToBeVerified;
    }

    // Function for marketAuthorities to verify addresses and assign sellerIDs
    function verifySellerAddress(address payable sellerAddress) public onlyMarketAuthority {
        for (uint256 i = 0; i < s_sellersToBeVerified.length; i++) {
            address pendingSeller = s_sellersToBeVerified[i];

            if (pendingSeller == address(0)) {
                revert Seller_Address_Already_Submitted();
            }
        }

        if (s_hasSellerID[sellerAddress] != 0) {
            revert Seller_Has_ID();
        }

        uint256 sellerID = sellerCounter++;

        s_sellers[msg.sender] = true;

        s_hasSellerID[sellerAddress] = sellerID;

        // Find the index of the seller in the sellersToBeVerified array

        uint256 indexToRemove;

        uint256 sellersToBeVerified = s_sellersToBeVerified.length;

        for (uint256 i = 0; i < sellersToBeVerified; i++) {
            if (s_sellersToBeVerified[i] == sellerAddress) {
                indexToRemove = i;

                break;
            }
        }

        // Ensure the seller is in the pending verification array

        require(indexToRemove < sellersToBeVerified, "Seller not found in pending verification");

        // Swap the element to be removed with the last element

        s_sellersToBeVerified[indexToRemove] = s_sellersToBeVerified[sellersToBeVerified - 1];

        // Reduce the array's length by 1

        s_sellersToBeVerified.pop();

        emit SellerVerified(sellerAddress, sellerID);
    }

    function buyItem(string memory itemName, uint256 sellerID) public payable {
        // 1. Validate item existence and seller:

        if (s_sellersItem[sellerID][itemName].sellerAddress == address(0)) {
            revert Invalid_SellerID_Or_Invalid_Item();
        }
        // 2.a Ensure sufficient funds from buyer:
        uint itemPriceInETH = s_sellersItem[sellerID][itemName].itemPrice;
        if (msg.value < itemPriceInETH) {
            revert Insufficient_Amount();
        }

        // // 2.b Ensure sufficient ETH funds from buyer who'll see the price as USD
        // uint256 requiredAmount = (s_sellersItem[sellerID][itemName].itemPrice).getConversionRate(ETHUSD_priceFeed);
        // if (msg.value < requiredAmount) {
        //     revert Insufficient_Amount();
        // }

        // 3. Check item availability:
        if (s_sellersItem[sellerID][itemName].itemQuantity == 0) {
            revert Item_Out_Of_Stock();
        }

        

        // 4. Update seller's balance:
        s_sellersBalances[s_sellersItem[sellerID][itemName].sellerAddress] += itemPriceInETH;

        // 5. Update item quantity:
        s_sellersItem[sellerID][itemName].itemQuantity--;

        // 6. Return excess funds to the buyer:
        if (msg.value > itemPriceInETH) {
            uint256 excessAmount = msg.value - itemPriceInETH;
            (bool success,) = msg.sender.call{value: excessAmount}("");
            require(success, "Failed to return excess funds to the buyer");
        }

        // 7. Emit purchase event:
        emit ItemPurchased(msg.sender, itemName, sellerID, s_sellersItem[sellerID][itemName].itemPrice);
    }

    function withdrawBalance() public payable onlySeller {
        uint256 balance = s_sellersBalances[msg.sender];
        if (balance <= 0) {
            revert No_balance_to_withdraw();
        }

        // Transfer funds to seller
        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");

        // Reset seller's balance
        s_sellersBalances[msg.sender] = 0;
    }

    /**
     *  GETTERS *******************
     */
    function getItemPrice(uint256 sellerID, string memory itemName) external view returns (uint256) {
        uint256 requiredAmount = s_sellersItem[sellerID][itemName].itemPrice; // .getConversionRate(ETHUSD_priceFeed)
        return requiredAmount;
    }

    function getItemByIndex(uint256 index) external view returns (Item memory) {
        require(index < s_items.length, "Index out of bounds");
        return s_items[index];
    }

    function getCurrentMarketAuthority() external view returns (address) {
        return s_marketAuthority;
    }

    function isAddressMarketAuthority(address marketAuthority) external view returns (bool) {
        return s_marketAuthorities[marketAuthority];
    }

    function getSellersToBeVerified() external view onlyMarketAuthority returns (address[] memory) {
        return s_sellersToBeVerified;
    }

    function isSellerVerified(address sellerAddress) external view returns (bool) {
        return s_sellers[sellerAddress];
    }

    function doesSellerHaveID(address sellerAddress) external view returns (uint256) {
        return s_hasSellerID[sellerAddress];
    }

    function doesItemBelongToSeller(uint256 sellerId, string memory itemName) external view returns (Item memory) {
        return s_sellersItem[sellerId][itemName];
    }

    function getSellerBalance() external view onlySeller returns (uint256) {
        return s_sellersBalances[msg.sender];
    }

    function isItemAvailable(string memory itemName) external view returns (Item[] memory) {
        return s_findItem[itemName];
    }
}

/*
CHAINLINK ETH/USD ADDRESS ----   0x694AA1769357215DE4FAC081bf1f309aDC325306
*/
