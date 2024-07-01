//  SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/Fundme.sol";
import {DeployFundMe} from "../script/DeployFundme.s.sol";

contract FundmeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("User");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded {
          vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarValue() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionisAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // The next Line should Revert ! 
        // Assert (this Transaction should Fail / Revert)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public funded {
    
        uint256 amountFunded = fundMe.GetAddresstoAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFundersToArrayOfFunders() public funded {
    
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
        
    }

    function testWithdrawWithSingleFunder() public funded {

        // Arrange !

        uint256 Starting_Owner_Balance = fundMe.getOwner().balance;
        uint256 Starting_Fundme_Balance = address(fundMe).balance;

        // Act !
        uint256 gasStart = gasleft(); // 1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // cost = 200
        fundMe.withdraw(); // should have spent GAS ?

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert !

        uint256 ending_Owner_Balance = fundMe.getOwner().balance;
        uint256 ending_Fundme_Balance = address(fundMe).balance;
        assertEq(ending_Fundme_Balance, 0);
        assertEq(Starting_Fundme_Balance + Starting_Owner_Balance, ending_Owner_Balance);
    }

    function testWithdrawFromMultipleFunders() public funded {

        // Arrange

        uint160 NumberofFunders = 10; // as of Solidity V - 0.8 you can no longer cast explicitly from address to uint256 !
        uint160 StartingFundersIndex = 1;
        for(uint160 i = StartingFundersIndex ; i < NumberofFunders ; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 Starting_Owner_Balance = fundMe.getOwner().balance;
        uint256 Starting_Fundme_Balance = address(fundMe).balance;


       // Act

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert 

        assert(address(fundMe).balance == 0);
        assert(Starting_Fundme_Balance + Starting_Owner_Balance == fundMe.getOwner().balance);

    }

    function testWithdrawFromMultipleFundersCheaper() public funded {

        // Arrange

        uint160 NumberofFunders = 10; // as of Solidity V - 0.8 you can no longer cast explicitly from address to uint256 !
        uint160 StartingFundersIndex = 1;
        for(uint160 i = StartingFundersIndex ; i < NumberofFunders ; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 Starting_Owner_Balance = fundMe.getOwner().balance;
        uint256 Starting_Fundme_Balance = address(fundMe).balance;


       // Act

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert 

        assert(address(fundMe).balance == 0);
        assert(Starting_Fundme_Balance + Starting_Owner_Balance == fundMe.getOwner().balance);

    }
}


// What can we do with Addresses outside our System ?
// 1. Unit :
// Testing a Specific part of our code !
// 2. Integration :
// Testing how our code works with other parts of the Code !
// 3. Forked : 
// - Testing our code on a simulated real environment ! 
// 4. Staging :
// Testing our code in a Real Environment that is not Prod !












