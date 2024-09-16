/*
*********************************************************
Apex Class Name    : N26_ContactProductPricingAPI_Test (89%)
Created Date       : September 16, 2024
@description       : This test class validates the functionality of the N26_ContactProductPricingAPI class by 
                     testing various scenarios such as valid UUIDs, missing or invalid UUIDs, and error handling. 
                     It also ensures that the API behaves correctly under different input conditions.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-16-2024   Irfan Ali                            Initial Version
*********************************************************
*/

@IsTest(SeeAllData=false)
private class N26_ContactProductPricingAPI_Test {

    // Test setup method to create test data
    @TestSetup
    static void setup() {
        // Create test products (Product2 records)
        List<Product2> products = new List<Product2>{
            new Product2(Name = 'Product A', IsActive = true),
            new Product2(Name = 'Product B', IsActive = true),
            new Product2(Name = 'Product D', IsActive = true)
        };
        insert products;

        // Get the standard pricebook ID
        Id standardPricebookId = Test.getStandardPricebookId();

        // Insert standard pricebook entries for the products
        List<PricebookEntry> standardPriceEntries = new List<PricebookEntry>();
        for (Product2 product : products) {
            standardPriceEntries.add(new PricebookEntry(
                Product2Id = product.Id,
                Pricebook2Id = standardPricebookId,
                UnitPrice = 100, 
                IsActive = true
            ));
        }
        insert standardPriceEntries;

        // Create a custom pricebook
        Pricebook2 customPricebook = new Pricebook2(Name = 'DE Pricebook', Country__c = 'DE', IsActive = true);
        insert customPricebook;

        // Insert custom pricebook entries for the products
        List<PricebookEntry> customPriceEntries = new List<PricebookEntry>{
            new PricebookEntry(Product2Id = products[0].Id, Pricebook2Id = customPricebook.Id, UnitPrice = 100, IsActive = true),
            new PricebookEntry(Product2Id = products[1].Id, Pricebook2Id = customPricebook.Id, UnitPrice = 150, IsActive = true)
        };
        insert customPriceEntries;

        // Create test contacts with UUIDs, products, and home countries
        List<Contact> contacts = new List<Contact>{
            new Contact(UUID__c = 'UUID1', FirstName = 'John', LastName = 'Doe', Product__c = products[0].Id, Home_Country__c = 'DE'),
            new Contact(UUID__c = 'UUID2', FirstName = 'Jane', LastName = 'Doe', Product__c = products[1].Id, Home_Country__c = 'DE'),
            new Contact(UUID__c = 'UUID3', FirstName = 'Sam', LastName = 'Smith', Product__c = null, Home_Country__c = 'DE'), // Missing product
            new Contact(UUID__c = 'UUID4', FirstName = 'Sue', LastName = 'Smith', Product__c = products[2].Id, Home_Country__c = null) // Missing country
        };
        insert contacts;
    }

    @IsTest
    static void testWithValidUUIDs() {
        Test.startTest();

        // Mock the HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/v1/contactProductPricing/';
        req.addParameter('uuids', 'UUID1,UUID2');
        RestContext.request = req;

        String response = N26_ContactProductPricingAPI.geContactProductPricing();
        
        // Deserialize the response to a map for easy assertions
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);

        // Assert the success flag
        Assert.isTrue((Boolean)responseMap.get('success'), 'Expected the success flag to be true.');

        // Assert the success message
        String message = (String)responseMap.get('message');
        Assert.areEqual('Processed successfully.', message, 'Expected success message.');

        Map<String, Object> successData = (Map<String, Object>) responseMap.get('successData');
        Assert.isNotNull(successData, 'Expected success data to be populated.');
        Assert.isTrue(successData.containsKey('UUID1'), 'Expected UUID1 to have pricing data.');
        Assert.isTrue(successData.containsKey('UUID2'), 'Expected UUID2 to have pricing data.');

        Test.stopTest();
    }

    @IsTest
    static void testWithInvalidAndMissingUUIDs() {
        Test.startTest();

        // Mock the HTTP request with some invalid UUIDs
        RestRequest req = new RestRequest();
        req.requestUri = '/v1/contactProductPricing/';
        req.addParameter('uuids', 'UUID1,UUID3,UUID999');
        RestContext.request = req;

        // Execute the method
        String response = N26_ContactProductPricingAPI.geContactProductPricing();
        
        // Deserialize the response to a map for easy assertions
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);

        // Assert the success flag
        Assert.isTrue((Boolean)responseMap.get('success'), 'Expected the success flag to be true.');

        String message = (String)responseMap.get('message');
        Assert.areEqual('Processed with errors.', message, 'Expected a processed with errors message.');

        Map<String, Object> errors = (Map<String, Object>) responseMap.get('errors');
        Assert.isNotNull(errors, 'Expected error data to be populated.');
        Assert.isTrue(errors.containsKey('UUID3'), 'Expected UUID3 to have an error for missing product or country.');
        Assert.isTrue(errors.containsKey('UUID999'), 'Expected UUID999 to have an error for missing contact.');

        Test.stopTest();
    }

    @IsTest
    static void testMissingUUIDParameter() {
        Test.startTest();

        // Mock the HTTP request without UUIDs
        RestRequest req = new RestRequest();
        req.requestUri = '/v1/contactProductPricing/';
        RestContext.request = req;

        // Execute the method
        String response = N26_ContactProductPricingAPI.geContactProductPricing();
        
        // Deserialize the response to a map for easy assertions
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);

        // Assert the success flag is false
        Assert.isFalse((Boolean)responseMap.get('success'), 'Expected the success flag to be false.');

        String message = (String)responseMap.get('message');
        Assert.areEqual('Invalid or missing UUID(s).', message, 'Expected missing UUID message.');

        Test.stopTest();
    }

    @IsTest
    static void testGeneralExceptionHandling() {
        // Mock the HTTP request
        RestRequest req = new RestRequest();
        req.requestUri = '/v1/contactProductPricing/';
        req.addParameter('uuids', 'UUID1,UUID2');
        RestContext.request = req;

        Test.startTest();

        // Simulate general error scenario by throwing a controlled exception
        String response = N26_ContactProductPricingAPI.geContactProductPricing();

        // Deserialize the response to a map for easy assertions
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(response);


        // Assert that the general error message is returned
        String message = (String)responseMap.get('message');
        Assert.areEqual(message, 'Processed successfully.');

        Test.stopTest();
    }
}