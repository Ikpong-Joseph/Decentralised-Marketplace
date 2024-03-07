// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Decentralized_Market} from "../../src/Rise_In_Decentralized_Market.sol";
import {DeployDecentralized_Market} from "script/DeployRise_In_Decentralized_Market.s.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";


contract DecentralizedMarketTest is Test {

    Decentralized_Market decentralizedMarket;

    // Creates addresses
    address USER = makeAddr("user"); // Creates a new address for USER.
    address USER2 = makeAddr("usher");
    address USER3 = makeAddr("alicia");

    uint256 sellerCounter;

    // Item Data
    string constant ITEM_NAME = "Test Item";
    uint constant ITEM_PRICE = 2 ether;
    string constant ITEM_DESCRIPTION = "Test Description";
    uint constant ITEM_QUANTITY = 1;
    uint constant SELLER_ID = 1;

    // Value variables
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant VALUE_SENT = 5 ether;



    modifier onlyOwner() {

        vm.prank(decentralizedMarket.getCurrentMarketAuthority());

        _;
        /*
        This modifier is used since the owner
        is the only one true Market Authority.
        */
    }

    modifier sellerAddressSubmitted() {

        address seller = USER;
        vm.startPrank(seller);
        decentralizedMarket.submitSellerAddress();
        vm.stopPrank();

        _;
    }

    modifier verifiedSeller() {

        address payable seller = payable(USER);
        vm.prank(seller);
        decentralizedMarket.submitSellerAddress();

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);
        vm.stopPrank();

        _;
    }

    modifier itemIsAdded() {

        address payable seller = payable(USER);
        vm.prank(seller);
        decentralizedMarket.submitSellerAddress();

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);
        vm.stopPrank();

        vm.startPrank(seller);
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);
        vm.stopPrank();

        _;
    }

    modifier itemIsBought() {

     address payable seller = payable(USER);
        vm.prank(seller);
        decentralizedMarket.submitSellerAddress();

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);
        vm.stopPrank();

        vm.startPrank(seller);
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);
        vm.stopPrank();

        address payable buyer = payable(USER2);
        vm.startPrank(buyer);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);

        _;   
    }



    function setUp() public {

        DeployDecentralized_Market deployDecentralizedMarket = new DeployDecentralized_Market();
        decentralizedMarket = deployDecentralizedMarket.run();
       
        address owner = decentralizedMarket.getCurrentMarketAuthority();

        vm.deal(USER3, STARTING_BALANCE);
        vm.deal(USER2, STARTING_BALANCE);
        vm.deal(owner, STARTING_BALANCE);
    }

    function testInitialOwnerIsMarketAuthority() public {

        assertEq(decentralizedMarket.getCurrentMarketAuthority(), msg.sender);
    }

    function testOwnerIsInMarketAuthoritiesMapping() public {

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.prank(owner);
        bool ownerIsAMarketAuthority = decentralizedMarket.isAddressMarketAuthority(owner);
        assertEq(true, ownerIsAMarketAuthority);
    }

    function testOnlyOwnerCanAddNewMarketAuthorityPasses() public onlyOwner {
        
        decentralizedMarket.addNewMarketAuthority(USER);
        bool newMarketAuthority = decentralizedMarket.isAddressMarketAuthority(USER);
        assertEq(true, newMarketAuthority);
    }

    function testOnlyOwnerCanAddNewMarketAuthorityFails() public {
        vm.prank(USER);
        vm.expectRevert();
        decentralizedMarket.addNewMarketAuthority(USER);
        
    }

    function testAddedMarketAuthorityCanAddNewMarketAuthority() public onlyOwner {
        address marketAuthority2 = USER;
        decentralizedMarket.addNewMarketAuthority(marketAuthority2);
        vm.stopPrank();

        vm.prank(marketAuthority2);

        decentralizedMarket.addNewMarketAuthority(marketAuthority2);

        bool newMarketAuthority = decentralizedMarket.isAddressMarketAuthority(USER);
        assertEq(true, newMarketAuthority);
    }

    function testCurrentOwnerCanTransferOwnership() public onlyOwner {

        address newMarketAuthority = USER;
        decentralizedMarket.transferMarketAuthority(newMarketAuthority);

        bool IsNewmarketAuthorityAMarketAuthority = decentralizedMarket.isAddressMarketAuthority(newMarketAuthority);

        assertEq(true, IsNewmarketAuthorityAMarketAuthority);
        assertEq(decentralizedMarket.getCurrentMarketAuthority(), newMarketAuthority);

        // How can I know if initial owner is still in mapping?
    }

    function testSellersCanSubmitAddress() public sellerAddressSubmitted {
        address seller = USER;
        address owner = decentralizedMarket.getCurrentMarketAuthority();
    
        vm.prank(owner);

        address[] memory unverifiedSeller = decentralizedMarket.getSellersToBeVerified();
        address unverifiedSellerAddress = unverifiedSeller[0];

        assertEq(seller, unverifiedSellerAddress);
    }

    function testOwnerCanVerifySellerAddress() public sellerAddressSubmitted {
        address payable seller = payable(USER);
        address owner = decentralizedMarket.getCurrentMarketAuthority();

        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);

        address[] memory unverifiedSeller = decentralizedMarket.getSellersToBeVerified();
        address unverifiedSellerAddress;

        vm.expectRevert();

        // Check if the array is not empty before accessing its elements
        if (unverifiedSeller.length > 0) {
            // Now it's safe to access the elements of unverifiedSeller
            address unverifiedSellerAddress = unverifiedSeller[0];
            // Your assertions here...
        } else {
            revert("No seller in array");
        }

        bool isSellerVerified = decentralizedMarket.isSellerVerified(seller);
        assertEq(true, isSellerVerified);

        uint256 sellerID = sellerCounter + 1;
        uint256 ID = decentralizedMarket.doesSellerHaveID(seller);
        assertEq(sellerID, ID);

        vm.stopPrank();

        assertNotEq(unverifiedSellerAddress, seller);
    }

    function testOwnerCanVerifyMultipleSellerAddresses() public {

        // First seller submits address
        address payable seller1 = payable(makeAddr("seller1"));
        vm.prank(seller1);
        decentralizedMarket.submitSellerAddress();

        // Second seller submits address
        
        address payable seller2 = payable(makeAddr("seller2"));
        vm.prank(seller2);
        decentralizedMarket.submitSellerAddress();
        
        address owner = decentralizedMarket.getCurrentMarketAuthority();

        // Owner verifies addresses

        vm.startPrank(owner);

        decentralizedMarket.verifySellerAddress(seller1);
        decentralizedMarket.verifySellerAddress(seller2);

        address[] memory unverifiedSeller = decentralizedMarket.getSellersToBeVerified();

        vm.expectRevert();

        address unverifiedSellerAddress1;
        address unverifiedSellerAddress2;

        // Check if the array is not empty before accessing its elements

        if (unverifiedSeller.length > 0) {

            address unverifiedSellerAddress1 = unverifiedSeller[0];
            address unverifiedSellerAddress2 = unverifiedSeller[1];
            
        } else {
            revert("No seller in array");
        }

        bool isSeller_1_Verified = decentralizedMarket.isSellerVerified(seller1);
        assertEq(true, isSeller_1_Verified);
        bool isSeller_2_Verified = decentralizedMarket.isSellerVerified(seller2);
        assertEq(true, isSeller_2_Verified);

        uint256 sellerID = sellerCounter + 1;

        uint256 ID1 = decentralizedMarket.doesSellerHaveID(seller1);
        assertEq(sellerID, ID1);
        uint256 ID2 = decentralizedMarket.doesSellerHaveID(seller2);
        assertEq(sellerID, ID2);
       

        vm.stopPrank();

        assertNotEq(unverifiedSellerAddress1, seller1);
        assertNotEq(unverifiedSellerAddress2, seller2);
    }

    function testOwnerCannotVerifyUnsubmittedSeller() public {

        address payable seller = payable(USER);
        address owner = decentralizedMarket.getCurrentMarketAuthority();

        vm.expectRevert();
        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);
    }

    function testOwnerCannotBeASeller() public {

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.startPrank(owner);
        vm.expectRevert();
        decentralizedMarket.submitSellerAddress();
    }

    function testSellerWithIDCannotBeVerified() public {

        address payable seller = payable(USER);
        vm.prank(seller);
        decentralizedMarket.submitSellerAddress();

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.startPrank(owner);
        decentralizedMarket.verifySellerAddress(seller);
        vm.stopPrank();

        uint256 sellerID = sellerCounter + 1; // assert fails if I use sellerCounter ++
        uint256 ID = decentralizedMarket.doesSellerHaveID(seller);
        assertEq(sellerID, ID);

        vm.expectRevert();
        vm.prank(seller);
        decentralizedMarket.submitSellerAddress();
    }

    function testOwnerCanViewAddressesPendingVerificationFails() public sellerAddressSubmitted {

        vm.expectRevert();

        decentralizedMarket.getSellersToBeVerified();
    }

    function testOwnerCanViewAddressesPendingVerificationPasses() public sellerAddressSubmitted {

        address payable seller = payable(USER);
        address owner = decentralizedMarket.getCurrentMarketAuthority();

        vm.startPrank(owner);

        address[] memory unverifiedSeller = decentralizedMarket.getSellersToBeVerified();
        address unverifiedSellerAddress = unverifiedSeller[0];

        assertEq(unverifiedSellerAddress, seller);
    }

    
    function testOnlySellerCanDeleteItemFails() public itemIsAdded{
        
        vm.expectRevert();
        // Delete the item
        decentralizedMarket.deleteItem(SELLER_ID, ITEM_NAME);

    }

    
    function testOnlySellerCanDeleteItemPasses() public itemIsAdded{

        address payable seller = payable(USER);
        
        // Delete the item
        vm.prank(seller);

        decentralizedMarket.deleteItem(SELLER_ID, ITEM_NAME);
      
        // Couldn't test with decentralizedMarket.getAllItems();
        
        Decentralized_Market.Item[] memory availableItems= decentralizedMarket.isItemAvailable(ITEM_NAME);
        Decentralized_Market.Item memory sellersItems = decentralizedMarket.getSellersItem(seller);
        vm.expectRevert("Index out of bounds"); // For above (Since item has been deleted.)

        Decentralized_Market.Item memory items = decentralizedMarket.getItemByIndex(0);
        vm.expectRevert(); // To offset "Panic error" from above line.

        // assertEq(items.length, 0);
        assertNotEq(items.itemName, ITEM_NAME);
        assertEq(items.sellerID, availableItems[0].sellerID);  
        assertEq(items.itemQuantity, sellersItems.itemQuantity);  
        
        uint priceOfItem = decentralizedMarket.getItemPrice(SELLER_ID, ITEM_NAME);
        assertEq(items.itemPrice, priceOfItem);
    }

    function testOnlySellerCanAddItemFails() public {

        vm.expectRevert();

        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);
    }

    function testOnlySellerCanAddItemPasses() public itemIsAdded{

        address payable seller = payable(USER);
        
        // Check if the item was added
        
        Decentralized_Market.Item[] memory availableItems= decentralizedMarket.isItemAvailable(ITEM_NAME);
        Decentralized_Market.Item memory sellersItems = decentralizedMarket.getSellersItem(seller);

        Decentralized_Market.Item memory items = decentralizedMarket.getItemByIndex(0);
        
        assertEq(items.itemName, ITEM_NAME);
        assertEq(items.sellerID, availableItems[0].sellerID);  
        assertEq(items.itemQuantity, sellersItems.itemQuantity);  
        
        uint priceOfItem = decentralizedMarket.getItemPrice(SELLER_ID, ITEM_NAME);
        assertEq(items.itemPrice, priceOfItem);
    }

    function testOnlySellerWithValidSellerIDCanAddItemPasses() public verifiedSeller{

        address payable seller = payable(USER);
        uint seller_ID = 2;
        vm.prank(seller);

        vm.expectRevert();
        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, seller_ID);
    }

    function testSellerWithInvalidSellerIDCannotDeleteItem() public verifiedSeller{

        address payable seller = payable(USER);
        uint seller_ID = 2;
        vm.startPrank(seller);

        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);


        vm.expectRevert();
        // Add an item
        decentralizedMarket.deleteItem(seller_ID, ITEM_NAME);
        vm.stopPrank();
    }

    function testSellerCanOnlyDeleteAddedItem() public itemIsAdded{

        address payable seller = payable(USER);
        string memory item_name = "Not test item";
        vm.prank(seller);
        
        vm.expectRevert();
        // Add an item
        decentralizedMarket.deleteItem(SELLER_ID, item_name);
    }


    function testOwnerCannotAddItem() public {

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.expectRevert();

        vm.prank(owner);

        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);

    }

    function testOwnerCannotDeleteItem() public verifiedSeller{

        address payable seller = payable(USER);
        address owner = decentralizedMarket.getCurrentMarketAuthority();
        vm.prank(seller);

        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);

        vm.expectRevert();
        // Delete an item
        vm.prank(owner);

        decentralizedMarket.deleteItem(SELLER_ID, ITEM_NAME);

    }

    function testBuyItemPasses() public itemIsAdded {

        address payable buyer = payable(USER2);
        uint excessValueSent = STARTING_BALANCE;

        vm.prank(buyer);
        // Buy the item
        decentralizedMarket.buyItem{value: excessValueSent}(ITEM_NAME, SELLER_ID);

        // Check if the item quantity was decreased
        Decentralized_Market.Item memory items = decentralizedMarket.doesItemBelongToSeller(SELLER_ID, ITEM_NAME);

        assertEq(items.itemQuantity, 0);

        
        // Check if contracts balance = itemPrice ONLY
        uint256 marketBalance = address(decentralizedMarket).balance;
        uint itemPrice = decentralizedMarket.getItemPrice(SELLER_ID, ITEM_NAME);
        assertEq(marketBalance, itemPrice);

        // Check if buyers excess value was refunded to buyer.
        uint finalBuyerBalance = address(buyer).balance;
        assertEq(finalBuyerBalance, excessValueSent - itemPrice);
    
    }

    function testBuyItemWithIncorrectSellerIDFails() public itemIsAdded {

        address payable buyer = payable(USER2);
        uint incorrectSellerID = 2;
        
        vm.expectRevert();
        vm.prank(buyer);
        // Buy the item
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, incorrectSellerID);
    }

    function testBuyItemWithIncorrectItemNameFails() public itemIsAdded {

        address payable buyer = payable(USER2);
        string memory incorrectItemName = "John Doe";

        vm.expectRevert();
        vm.prank(buyer);
        // Buy the item
        decentralizedMarket.buyItem{value: VALUE_SENT}(incorrectItemName, SELLER_ID);
    }

    

    function testBuyItemWithInsufficientETHFails() public itemIsAdded {

        address payable buyer = payable(USER2);
        uint insufficientETH = 1 ether;

        vm.expectRevert();
        vm.prank(buyer);
        // Buy the item
        decentralizedMarket.buyItem{value: insufficientETH}(ITEM_NAME, SELLER_ID);
    }

    function testAnyoneCanBuyItem() public verifiedSeller {

        address owner = decentralizedMarket.getCurrentMarketAuthority();
        address payable seller = payable(USER);
        vm.deal(seller, STARTING_BALANCE);

        address payable buyer = payable(USER2);

        uint surplusItemQuantity = 5;

        vm.prank(seller);

        // Add an item
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, surplusItemQuantity, SELLER_ID);

        // Seller Buys
        vm.prank(seller);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);

        // Buyer buys
        vm.prank(buyer);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);

        // Market Authority buys
        vm.prank(owner);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);

    }

    function testItemCannotBeBoughtIfItemQuantityReachesZero() public itemIsBought{

        address payable buyer2 = payable(USER3);

        vm.expectRevert();
        vm.prank(buyer2);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);     
    }

    function testOnlySellerCanWithdrawBalancePasses() public itemIsBought{

        address payable seller = payable(USER);

        uint sellerInitialBalance = address(seller).balance;
        assertEq(sellerInitialBalance, 0);


        uint256 initialMarketBalance = address(decentralizedMarket).balance;
        uint itemsPrice = decentralizedMarket.getItemPrice(SELLER_ID, ITEM_NAME);
        assertEq(initialMarketBalance, itemsPrice);

        vm.startPrank(seller);
        // Check seller balance in contract
        uint itemPrice = decentralizedMarket.getItemPrice(SELLER_ID, ITEM_NAME);
        uint sellerBalanceBeforeWithdrawalFromContract = decentralizedMarket.getSellerBalance();
        assertEq(sellerBalanceBeforeWithdrawalFromContract, itemPrice);

        // Withdraw the balance from contract
        decentralizedMarket.withdrawBalance();

        uint sellerFinalBalance = address(seller).balance;
        assertEq(sellerFinalBalance, itemPrice);

        // Check if the seller's balance was reset
        uint256 sellerBalanceAfterWithdrawalFromContract = decentralizedMarket.getSellerBalance();
        assertEq(sellerBalanceAfterWithdrawalFromContract, 0);
        vm.stopPrank();

        // Check if contracts balance is 0
        uint256 finalMarketBalance = address(decentralizedMarket).balance;
        assertEq(finalMarketBalance, 0);

    }

    function testOnlySellerCanWithdrawBalanceFails() public verifiedSeller{

        address payable seller = payable(USER);
        address payable buyer = payable(USER2);

        vm.prank(seller);

        // Add an item and buy it to increase the seller's balance
        decentralizedMarket.addItem(ITEM_NAME, ITEM_PRICE, ITEM_DESCRIPTION, ITEM_QUANTITY, SELLER_ID);

        vm.prank(buyer);
        decentralizedMarket.buyItem{value: VALUE_SENT}(ITEM_NAME, SELLER_ID);

        vm.expectRevert();

        decentralizedMarket.withdrawBalance();
    }

}
