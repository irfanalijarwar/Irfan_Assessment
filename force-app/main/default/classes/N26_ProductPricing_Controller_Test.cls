/*
*********************************************************
Apex Class Name    : N26_ProductPricing_Controller_Test (86%)
Created Date       : September 16, 2024
@description       : This test class validates the functionality of the N26_ProductPricing_Controller class by 
                     testing different scenarios such as valid data retrieval, handling of missing contact or 
                     product data, and exception handling. It ensures the controller behaves correctly in all 
                     edge cases.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-16-2024   Irfan Ali                            Initial Version
*********************************************************
*/

@IsTest(SeeAllData=false)
public class N26_ProductPricing_Controller_Test {

    @testSetup
    static void setupTestData() {
        // Create test Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;

        // Get the standard Pricebook
        Id standardPricebook = Test.getStandardPricebookId();

        // Create custom Pricebook
        Pricebook2 testPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true,
            Country__c = 'DE'
        );
        insert testPricebook;

        // Create PricebookEntry in standard Pricebook
        PricebookEntry standardPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = standardPricebook,
            UnitPrice = 16,
            ATM_Fee_in_Other_Currencies__c = 0,
            Card_Replacement_Cost__c = 45,
            IsActive = true,
            CurrencyIsoCode = 'EUR'
        );
        insert standardPricebookEntry;

        // Create PricebookEntry in custom Pricebook
        PricebookEntry customPricebookEntry = new PricebookEntry(
            Product2Id = testProduct.Id,
            Pricebook2Id = testPricebook.Id,
            UnitPrice = 20,
            ATM_Fee_in_Other_Currencies__c = 0,
            Card_Replacement_Cost__c = 50,
            IsActive = true,
            CurrencyIsoCode = 'EUR'
        );
        insert customPricebookEntry;

        // Create Contact with Product and Country
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Product__c = testProduct.Id,
            Home_Country__c = 'DE'
        );
        insert testContact;

        // Create Case linked to Contact
        Case testCase = new Case(
            ContactId = testContact.Id,
            Status = 'New'
        );
        insert testCase;
    }

    @IsTest
    static void testGetProductPricingData_Success() {
        // Fetch the test case
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        // Call the method for a valid case
        N26_ProductPricing_Controller.ResponseWrapper result = N26_ProductPricing_Controller.getProductPricingData(testCase.Id);
        
        // Validate the response data
        System.assertNotEquals(null, result.pricingData, 'Expected pricing data to be returned.');
        System.assertEquals(null, result.errorMessage, 'No error message should be returned.');
        
        // Validate product pricing details
        System.assert(result.pricingData.containsKey('DE'), 'Pricing data should contain country DE.');
        List<N26_ProductPricing_Controller.ProductPricingTable> pricingTable = result.pricingData.get('DE');
        System.assertEquals(1, pricingTable.size(), 'Expected one product pricing entry for DE.');
        System.assertEquals('Test Product', pricingTable[0].productName, 'Product name should match.');
        System.assertEquals('EUR 20.00', pricingTable[0].costPerMonth, 'Expected correct unit price.');
        System.assertEquals('Free', pricingTable[0].atmFee, 'ATM fee should be Free.');
        System.assertEquals('EUR 50.00', pricingTable[0].cardReplacementCost, 'Card replacement cost should match.');
    }

    @IsTest
    static void testGetProductPricingData_MissingContact() {
        // Create a Case without a Contact
        Case testCaseNoContact = new Case(Status = 'New');
        insert testCaseNoContact;

        // Call the method with the Case having no Contact
        N26_ProductPricing_Controller.ResponseWrapper result = N26_ProductPricing_Controller.getProductPricingData(testCaseNoContact.Id);
        
        // Validate the error message when Contact is missing
        System.assertEquals(null, result.pricingData, 'Pricing data should be null for missing Contact.');
        System.assertEquals(System.Label.MISSING_PRODUCT_OR_COUNTRY_MSG + ' on the associated Contact.', result.errorMessage, 'Expected specific error message for missing Contact data.');
    }

    @IsTest
    static void testGetProductPricingData_CaseIdNull() {
        // Test the method when caseId is null
        try {
            N26_ProductPricing_Controller.getProductPricingData(null);
            System.assert(false, 'Expected an exception to be thrown when caseId is null.');
        } catch (N26_CustomException e) {
            System.assertEquals('Script-thrown exception', e.getMessage(), 'Expected exception message to match.');
        }
    }

    @IsTest
    static void testGetProductPricingData_NoPricingDetails() {
        // Create a Contact with no product
        Contact contactWithoutProduct = new Contact(
            FirstName = 'NoProduct',
            LastName = 'Contact',
            Home_Country__c = 'DE'
        );
        insert contactWithoutProduct;

        // Create a case for the contact without a product
        Case caseWithoutProduct = new Case(
            ContactId = contactWithoutProduct.Id,
            Status = 'New'
        );
        insert caseWithoutProduct;

        // Call the method and validate when no pricing details exist
        N26_ProductPricing_Controller.ResponseWrapper result = N26_ProductPricing_Controller.getProductPricingData(caseWithoutProduct.Id);
        
        // Ensure that pricing data is null
        System.assertEquals(null, result.pricingData, 'Expected null pricing data for contact without product.');
        System.assertNotEquals(null, result.errorMessage, 'Expected error message when pricing details cannot be found.');
    }

    @IsTest
    static void testGetProductPricingData_ExceptionHandling() {
        // Insert Contact without Product and test the exception scenario
        Contact errorContact = new Contact(
            FirstName = 'Error',
            LastName = 'Contact',
            Home_Country__c = 'DE'
        );
        insert errorContact;

        // Insert a case for the contact
        Case caseWithError = new Case(
            ContactId = errorContact.Id,
            Status = 'New'
        );
        insert caseWithError;

        // Call the method and validate error handling
        N26_ProductPricing_Controller.ResponseWrapper result = N26_ProductPricing_Controller.getProductPricingData(caseWithError.Id);
        
        // Ensure error response is handled properly
        System.assertEquals(null, result.pricingData, 'Expected no pricing data for invalid Contact data.');
        System.assertNotEquals(null, result.errorMessage, 'Expected an error message when pricing details cannot be fetched.');
    }
}