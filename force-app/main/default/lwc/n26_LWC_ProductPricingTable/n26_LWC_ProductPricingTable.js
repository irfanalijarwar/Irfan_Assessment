import { LightningElement, api, wire, track } from 'lwc';
import getProductPricingData from '@salesforce/apex/N26_ProductPricing_Controller.getProductPricingData';

/*
*********************************************************
LWC Component Name : N26_LWC_ProductPricingTable
Created Date       : September 15, 2024
@description       : This Lightning Web Component (LWC) is used to display the product pricing data for a specific case. 
                     It calls an Apex method to retrieve product pricing details and dynamically displays them in a data table.
@author            : Irfan Ali
Modification Log:
Ver   Date         Author                               Modification
1.0   09-15-2024   Irfan Ali                            Initial Version
*********************************************************
*/

export default class N26_LWC_ProductPricingTable extends LightningElement {
    @api recordId;

    @track productList = [];
    @track countryName = '';
    @track errorMessage = '';
    error;

    // Single column definition for the unified datatable
    @track columns = [
        { label: 'Product Name', fieldName: 'productName', type: 'text' },
        { label: 'Country', fieldName: 'country', type: 'text' },
        { label: 'Cost per Calendar Month', fieldName: 'costPerMonth', type: 'text' },
        { label: 'ATM Fee in Other Currencies', fieldName: 'atmFee', type: 'text' },
        { label: 'Card Replacement Cost', fieldName: 'cardReplacementCost', type: 'text' }
    ];

    /*
    *********************************************************
    @Method Name    : wiredPricingData
    @description    : Wired method that retrieves product pricing data from the Apex class based on the caseId.
                      It handles both successful data retrieval and errors.
    @param          : error - Any errors returned from the Apex call
                      data - The pricing data returned from the Apex call
    @return         : None
    *********************************************************
    */
    @wire(getProductPricingData, { caseId: '$recordId' })
    wiredPricingData({ error, data }) {
        if (data) {
            if (data.errorMessage) {
                this.errorMessage = data.errorMessage;
                console.log('ddd :: ' + this.errorMessage);
                this.productList = [];
            } else {
                this.countryName = Object.keys(data.pricingData)[0];
                const productData = data.pricingData[this.countryName];

                if (productData && Array.isArray(productData)) {
                    this.productList = productData.map(product => ({
                        productName: product.productName,
                        country: this.countryName,
                        costPerMonth: product.costPerMonth,
                        atmFee: product.atmFee,
                        cardReplacementCost: product.cardReplacementCost
                    }));
                    this.errorMessage = '';
                } else {
                    this.productList = [];
                    this.errorMessage = 'No pricing data found for the selected country.';
                }
            }

            this.error = undefined;
        } else if (error) {
            // Log error for debugging
            console.log('error: ' + JSON.stringify(error));
            this.errorMessage = 'An error occurred while retrieving data. Please try again later.'; 
            this.productList = [];
        }
    }

    /*
    *********************************************************
    @Method Name    : hasData
    @description    : Getter method to check if productList has data. Used for conditional rendering in the template.
    @return         : Boolean - True if productList contains data, false otherwise
    *********************************************************
    */
    get hasData() {
        return this.productList.length > 0;
    }

    /*
    *********************************************************
    @Method Name    : hasError
    @description    : Getter method to check if an error message exists. Used for conditional rendering in the template.
    @return         : Boolean - True if there is an error message, false otherwise
    *********************************************************
    */
    get hasError() {
        return this.errorMessage !== '';
    }
}