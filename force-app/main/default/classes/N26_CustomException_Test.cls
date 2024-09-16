/*
*********************************************************
Apex Class Name    : N26_CustomException_Test (92%)
Created Date       : September 16, 2024
@description       : This test class validates the functionality of the N26_CustomException class by ensuring
                     that errors are logged correctly in the Error_Log__c object. It includes tests for 
                     logging an exception and handling an original exception.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-16-2024   Irfan Ali                            Initial Version
*********************************************************
*/
@isTest(SeeAllData=false)
public class N26_CustomException_Test {

    @isTest
    static void testCustomExceptionLogging() {
        // Test if the exception logs an error to Error_Log__c object
        Test.startTest();
        try {
            throw new N26_CustomException('Test error message', 'N26_ProductPricing_Controller');
        } catch (N26_CustomException e) {
            // Verify the exception was thrown and the error was logged
            Error_Log__c[] errorLogs = [SELECT Status__c, Error_Message__c, Action_Name__c FROM Error_Log__c];
            Assert.areEqual(1, errorLogs.size(), 'One Error_Log__c record should have been created.');
            Assert.areEqual('Open', errorLogs[0].Status__c, 'The status should be "Open".');
            Assert.areEqual('Test error message', errorLogs[0].Error_Message__c, 'The error message should match.');
            Assert.areEqual('N26_ProductPricing_Controller', errorLogs[0].Action_Name__c, 'The action name should match.');
        }
        Test.stopTest();
    }

    @isTest
    static void testCustomExceptionWithOriginalException() {
        // Simulate an exception by creating a custom exception or using a standard Salesforce exception
        Test.startTest();
        try {
            // Simulate an exception with an original exception
            throw new N26_CustomException('Test error with original exception', new DmlException(), 'N26_ProductPricing_Controller');
        } catch (N26_CustomException e) {
            // Verify the exception was thrown and the error was logged
            Error_Log__c[] errorLogs = [SELECT Status__c, Error_Message__c, Action_Name__c FROM Error_Log__c];
            Assert.areEqual(1, errorLogs.size(), 'One Error_Log__c record should have been created.');
            Assert.isTrue(errorLogs[0].Error_Message__c.contains('Original Exception'), 'The error message should contain the original exception.');
        }
        Test.stopTest();
    }
}