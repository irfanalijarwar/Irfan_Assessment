/*
*********************************************************
Apex Class Name    : N26_ContactProductPricingAPI
Created Date       : September 15, 2024
@description       : This API retrieves the product pricing information for contacts based on a list of UUIDs provided in the request.
                     It fetches the related product and country information from the associated contact record and retrieves the pricing details accordingly.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-15-2024   Irfan Ali                            Initial Version
*********************************************************
*/

@RestResource(urlMapping='/v1/contactProductPricing/*')
global with sharing class N26_ContactProductPricingAPI {

    private static final String EXCEPTION_MSG = 'Invalid or missing UUID(s).';
    private static final String NO_CONTACT_FOUND_MSG = System.Label.NO_CONTACT_FOUND_MSG;
    private static final String MISSING_PRODUCT_OR_COUNTRY_MSG = System.Label.MISSING_PRODUCT_OR_COUNTRY_MSG +' for the contact with UUID: ';
    private static final String GENERAL_ERROR_MSG = System.Label.GENERAL_ERROR_MSG;

    /*
    *********************************************************
    @Method Name    : geContactProductPricing
    @description    : API method that retrieves the product pricing information for contacts using their UUIDs.
                      The product and country information from the contact is used to fetch pricing details from the PricebookEntry object.
    @param          : None
    @return         : String - A JSON-formatted string with the product pricing data or error messages
    *********************************************************
    */
    @HttpGet
    global static String geContactProductPricing() {
        String responseMessage = '';
        Map<String, Object> resultMap = new Map<String, Object>();
        Map<String, ContactPricingData> successData = new Map<String, ContactPricingData>();
        Map<String, String> errorData = new Map<String, String>();

        try {
            // Get the UUIDs from query parameters
            String uuidParam = RestContext.request.params.get('uuids');
            if (String.isBlank(uuidParam)) {
                errorData.put('error', EXCEPTION_MSG);
                resultMap.put('success', false);
                resultMap.put('message', EXCEPTION_MSG);
                resultMap.put('errors', errorData);
                return JSON.serialize(resultMap);
            }

            List<String> uuidList = uuidParam.split(',');

            // Fetch Contacts using the UUID list
            List<Contact> contactRecords = getContactsByUUIDs(uuidList);
            Set<String> foundUUIDs = new Set<String>();

            // Collect valid Contact UUIDs and map by Contact Id
            Map<Id, String> contactUUIDMap = new Map<Id, String>();
            for (Contact contact : contactRecords) {
                foundUUIDs.add(contact.UUID__c);

                if (String.isBlank(contact.Product__c) || String.isBlank(contact.Home_Country__c)) {
                    errorData.put(contact.UUID__c, MISSING_PRODUCT_OR_COUNTRY_MSG + contact.UUID__c);
                } else {
                    contactUUIDMap.put(contact.Id, contact.UUID__c);
                }
            }

            // Handle UUIDs that were not found
            for (String uuid : uuidList) {
                if (!foundUUIDs.contains(uuid)) {
                    errorData.put(uuid, NO_CONTACT_FOUND_MSG + uuid);
                }
            }

            if (!contactUUIDMap.isEmpty()) {
                List<Contact> validContacts = [SELECT Id, Name, Product__c, Home_Country__c, UUID__c FROM Contact WHERE Id IN :contactUUIDMap.keySet()];
                Map<Id, Map<String, List<ProductPricingTable>>> pricingDataMap = getBulkProductPricing(validContacts);

                // Populate success data
                for (Contact contact : validContacts) {
                    Map<String, List<ProductPricingTable>> pricingData = pricingDataMap.get(contact.Id);
                    successData.put(contact.UUID__c, new ContactPricingData(contact.Name, pricingData));
                }
            }

            // Prepare the final response
            resultMap.put('success', true);
            resultMap.put('successData', successData);
            resultMap.put('errors', errorData);

            // Set message based on whether errors exist
            if (errorData.isEmpty()) {
                resultMap.put('message', 'Processed successfully.');
            } else {
                resultMap.put('message', 'Processed with errors.');
            }

            // Return the response as a JSON string
            responseMessage = JSON.serialize(resultMap);
            return responseMessage;

        } catch (Exception e) {
            resultMap.put('success', false);
            resultMap.put('message', GENERAL_ERROR_MSG + ' Details: ' + e.getMessage());
            return JSON.serialize(resultMap);
        }
    }

    /*
    *********************************************************
    @Method Name    : getBulkProductPricing
    @description    : Fetches the product pricing data for all valid contacts in bulk.
                      Queries the PricebookEntry object using the product and country of each contact.
    @param          : List<Contact> contacts - List of valid contacts
    @return         : Map<Id, Map<String, List<ProductPricingTable>>> - A map containing pricing data for each contact
    *********************************************************
    */
    public static Map<Id, Map<String, List<ProductPricingTable>>> getBulkProductPricing(List<Contact> contacts) {
        Set<Id> productIds = new Set<Id>();
        Set<String> countries = new Set<String>();

        // Prepare data to query PricebookEntry in bulk
        for (Contact contact : contacts) {
            productIds.add(contact.Product__c);
            countries.add(contact.Home_Country__c);
        }

        // Query all relevant pricing details in one go
        List<PricebookEntry> entries = [
            SELECT Product2.Name, UnitPrice, ATM_Fee_in_Other_Currencies__c, Card_Replacement_Cost__c, Pricebook2.Country__c, CurrencyIsoCode, Product2Id
            FROM PricebookEntry
            WHERE Product2Id IN :productIds
            AND Pricebook2.Country__c IN :countries
            AND IsActive = true
        ];

        if (entries.isEmpty()) {
            // If no pricebook or entries found, throw a custom exception
            throw new N26_CustomException('No Pricebook or Pricebook entries found', 'N26_ContactProductPricingAPI');
        }

        // Prepare a map to store pricing data by contact
        Map<Id, Map<String, List<ProductPricingTable>>> contactPricingMap = new Map<Id, Map<String, List<ProductPricingTable>>>();

        // Map product and country details back to each contact
        for (Contact contact : contacts) {
            Map<String, List<ProductPricingTable>> countryPricingMap = new Map<String, List<ProductPricingTable>>();
            List<ProductPricingTable> pricingData = new List<ProductPricingTable>();

            for (PricebookEntry entry : entries) {
                if (contact.Product__c == entry.Product2Id && contact.Home_Country__c == entry.Pricebook2.Country__c) {
                    pricingData.add(new ProductPricingTable(
                        entry.Product2.Name,
                        formatCurrency(entry.UnitPrice, entry.CurrencyIsoCode),
                        formatAtmFee(entry.ATM_Fee_in_Other_Currencies__c),
                        formatCurrency(entry.Card_Replacement_Cost__c, entry.CurrencyIsoCode)
                    ));
                }
            }

            if (!pricingData.isEmpty()) {
                countryPricingMap.put(contact.Home_Country__c, pricingData);
            }

            contactPricingMap.put(contact.Id, countryPricingMap);
        }

        return contactPricingMap;
    }

    /*
    *********************************************************
    @Method Name    : getContactsByUUIDs
    @description    : Fetches the Contact records using a list of UUIDs.
    @param          : List<String> uuidList - List of UUIDs
    @return         : List<Contact> - List of contacts with the provided UUIDs
    *********************************************************
    */
    private static List<Contact> getContactsByUUIDs(List<String> uuidList) {
        return [
            SELECT UUID__c, Id, Name, Product__c, Home_Country__c 
            FROM Contact 
            WHERE UUID__c IN :uuidList
        ];
    }

    /*
    *********************************************************
    @Method Name    : formatCurrency
    @description    : Helper method to format the currency values.
    @param          : Decimal value - The value to be formatted
                      String currencySymbol - The currency symbol to use
    @return         : String - Formatted currency value
    *********************************************************
    */
    private static String formatCurrency(Decimal value, String currencySymbol) {
        return value != null ? currencySymbol + ' ' + value.setScale(2) : 'N/A';
    }

    /*
    *********************************************************
    @Method Name    : formatAtmFee
    @description    : Helper method to format the ATM fee.
    @param          : Decimal atmFee - The ATM fee value to be formatted
    @return         : String - Formatted ATM fee
    *********************************************************
    */
    private static String formatAtmFee(Decimal atmFee) {
        return (atmFee != null && atmFee > 0) ? atmFee.setScale(2) + '%' : 'Free';
    }

    // Wrapper class for Product Pricing Table
    public class ProductPricingTable {
        @AuraEnabled public String productName;
        @AuraEnabled public String costPerMonth;
        @AuraEnabled public String atmFee;
        @AuraEnabled public String cardReplacementCost;

        public ProductPricingTable(String productName, String costPerMonth, String atmFee, String cardReplacementCost) {
            this.productName = productName;
            this.costPerMonth = costPerMonth;
            this.atmFee = atmFee;
            this.cardReplacementCost = cardReplacementCost;
        }
    }

    // Response Wrapper Class for Bulk Response
    global class BulkResponseWrapper {
        public Boolean success;
        public String message;
        public Map<String, ContactPricingData> successData;
        public Map<String, String> errors;

        public BulkResponseWrapper(Boolean success, String message, Map<String, ContactPricingData> successData, Map<String, String> errors) {
            this.success = success;
            this.message = message;
            this.successData = successData;
            this.errors = errors;
        }
    }

    // Class to hold contact name and pricing data
    global class ContactPricingData {
        public String contactName;
        public Map<String, List<ProductPricingTable>> pricingData;

        public ContactPricingData(String contactName, Map<String, List<ProductPricingTable>> pricingData) {
            this.contactName = contactName;
            this.pricingData = pricingData;
        }
    }
}