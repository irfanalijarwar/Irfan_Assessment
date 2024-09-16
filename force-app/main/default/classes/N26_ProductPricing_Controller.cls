/*
*********************************************************
Apex Class Name    : N26_ProductPricing_Controller
Created Date       : September 15, 2024
@description       : This class is used to fetch product pricing data based on the associated contact's product and home country in a Case record. 
                     It returns pricing details for the product from the relevant Pricebook based on the home country.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-15-2024   Irfan Ali                            Initial Version
*********************************************************
*/

public with sharing class N26_ProductPricing_Controller {

    private static final String EXCEPTION_MSG = 'Case ID cannot be null.';
    private static final String MISSING_PRODUCT_OR_COUNTRY_MSG = System.Label.MISSING_PRODUCT_OR_COUNTRY_MSG + ' on the associated Contact.';
    private static final String GENERAL_ERROR_MSG = System.Label.GENERAL_ERROR_MSG;

    // Wrapper class to include both data and error message
    public class ResponseWrapper {
        @AuraEnabled public Map<String, List<ProductPricingTable>> pricingData;
        @AuraEnabled public String errorMessage;
        
        public ResponseWrapper(Map<String, List<ProductPricingTable>> pricingData, String errorMessage) {
            this.pricingData = pricingData;
            this.errorMessage = errorMessage;
        }
    }

    /*
    *********************************************************
    @Method Name    : getProductPricingData
    @author         : Irfan Ali
    @description    : Method used to retrieve product pricing details based on the Case ID. The associated Contact's product and home country are checked for pricing data.
    @param          : Id caseId - The ID of the Case record
    @return         : ResponseWrapper - A wrapper class containing the pricing data or an error message
    *********************************************************
    */
    @AuraEnabled(cacheable=true)
    public static ResponseWrapper getProductPricingData(Id caseId) {
        ResponseWrapper response;
        if (caseId == null) {
            response = new ResponseWrapper(null, GENERAL_ERROR_MSG);
            throw new N26_CustomException(EXCEPTION_MSG, 'N26_ProductPricing_Controller');
        }
        try {
            Case caseRecord = getCaseData(caseId);

            if (caseRecord.Contact == null || String.isBlank(caseRecord.Contact.Product__c) || String.isBlank(caseRecord.Contact.Home_Country__c)) {
                response = new ResponseWrapper(null, MISSING_PRODUCT_OR_COUNTRY_MSG);
            } 
            else {
                Map<String, List<ProductPricingTable>> pricingData = fetchPricingDetails(caseRecord.Contact.Product__c, caseRecord.Contact.Home_Country__c);
                response = new ResponseWrapper(pricingData, null);
            }  

        } catch (N26_CustomException e) {
            response = new ResponseWrapper(null, e.getMessage());
        } catch (Exception e) {
            // Handle general exceptions and log them
            response = new ResponseWrapper(null, GENERAL_ERROR_MSG);
        }

        return response;
    }

    /*
    *********************************************************
    @Method Name    : getCaseData
    @author         : Irfan Ali
    @description    : Method used to retrieve Case and associated Contact data
    @param          : Id caseId - The ID of the Case record
    @return         : Case - The Case record with related contact information
    *********************************************************
    */
    private static Case getCaseData(Id caseId) {
        Case caseRecord = [SELECT Contact.Product__c, Contact.Home_Country__c FROM Case WHERE Id = :caseId LIMIT 1];
        return caseRecord;
    }

    /*
    *********************************************************
    @Method Name    : fetchPricingDetails
    @description    : Method to fetch pricing details based on product and home country
    @param          : Id productId - The ID of the product
                      String homeCountry - The home country of the contact
    @return         : Map<String, List<ProductPricingTable>> - Pricing details for the product
    *********************************************************
    */
    private static Map<String, List<ProductPricingTable>> fetchPricingDetails(Id productId, String homeCountry) {
        Map<String, List<ProductPricingTable>> countryPricingMap = new Map<String, List<ProductPricingTable>>();
        try {
            List<PricebookEntry> entries = [
                SELECT 
                    Product2.Name, 
                    UnitPrice, 
                    ATM_Fee_in_Other_Currencies__c, 
                    Card_Replacement_Cost__c, 
                    Pricebook2.Country__c, 
                    CurrencyIsoCode
                FROM PricebookEntry
                WHERE Product2Id = :productId
                AND Pricebook2.Country__c = :homeCountry
                AND IsActive = true
            ];
            
            // Early return if no pricing data is found
            if (entries.isEmpty()) {
                return countryPricingMap;
            }

            // Prepare list for product pricing
            List<ProductPricingTable> pricingData = new List<ProductPricingTable>();
            for (PricebookEntry entry : entries) {
                pricingData.add(new ProductPricingTable(
                    entry.Product2.Name,
                    formatCurrency(entry.UnitPrice, entry.CurrencyIsoCode),
                    formatAtmFee(entry.ATM_Fee_in_Other_Currencies__c),
                    formatCurrency(entry.Card_Replacement_Cost__c, entry.CurrencyIsoCode)
                ));
            }

            // Add pricing data for the country
            countryPricingMap.put(homeCountry, pricingData);

        } catch (Exception e) {
            throw new N26_CustomException(e.getMessage(), 'N26_ProductPricing_Controller');
        }
        
        return countryPricingMap;
    }

    /*
    *********************************************************
    @Method Name    : formatCurrency
    @description    : Helper method to format currency values
    @param          : Decimal value - The currency value
                      String currencySymbol - The symbol for the currency
    @return         : String - The formatted currency value
    *********************************************************
    */
    private static String formatCurrency(Decimal value, String currencySymbol) {
        return value != null ? currencySymbol + ' ' + value.setScale(2) : 'N/A';
    }

    /*
    *********************************************************
    @Method Name    : formatAtmFee
    @description    : Helper method to format ATM Fee
    @param          : Decimal atmFee - The ATM fee value
    @return         : String - The formatted ATM fee
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
}