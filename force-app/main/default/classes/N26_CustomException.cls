/*
*********************************************************
Apex Class Name    : N26_CustomException
Created Date       : September 15, 2024
@description       : This class is a custom exception handler used to log error messages to the Error_Log__c object.
                     It provides two constructors: one to log an error message and another to log both an error message and the original exception.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-15-2024   Irfan Ali                            Initial Version
*********************************************************
*/

public class N26_CustomException extends Exception {

    /*
    *********************************************************
    @Method Name    : N26_CustomException
    @description    : Constructor that logs an error with a message and action name
    @param          : String message - The error message to log
                      String actionName - The name of the action where the error occurred
    @return         : None
    *********************************************************
    */
    public N26_CustomException(String message, String actionName) {
        logError(message, actionName);
    }

    /*
    *********************************************************
    @Method Name    : N26_CustomException
    @description    : Constructor that logs an error with a message, original exception, and action name
    @param          : String message - The error message to log
                      Exception originalException - The original exception caught
                      String actionName - The name of the action where the error occurred
    @return         : None
    *********************************************************
    */
    public N26_CustomException(String message, Exception originalException, String actionName) {
        String fullMessage = message + ' | Original Exception: ' + originalException.getMessage();
        logError(fullMessage, actionName);
    }

    /*
    *********************************************************
    @Method Name    : logError
    @description    : Private method used to log error details to the Error_Log__c object
    @param          : String errorMessage - The error message to log
                      String actionName - The name of the action where the error occurred
    @return         : None
    *********************************************************
    */
    private void logError(String errorMessage, String actionName) {
        try {
            Error_Log__c errorLog = new Error_Log__c();
            errorLog.Status__c = 'Open';
            errorLog.Error_Message__c = errorMessage;
            errorLog.Action_Name__c = actionName;
            insert errorLog;
        } catch (Exception e) {
            System.debug('Failed to log error in Error_Log__c: ' + e.getMessage());
        }
    }
}