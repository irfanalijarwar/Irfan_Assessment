# Salesforce Project Deployment Guide

This repository contains a Salesforce project that needs to be deployed to a Salesforce org. Below are the steps to clone the repository into Visual Studio Code (VS Code), authorize a Salesforce org, activate multi-currency, and deploy the project in stages.

## Prerequisites

Before you begin, ensure you have the following:
- [Salesforce CLI (SFDX)](https://developer.salesforce.com/tools/sfdxcli)
- [Visual Studio Code](https://code.visualstudio.com/)
- [Salesforce Extension Pack](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode) installed in VS Code
- A Salesforce Developer or Sandbox Org

---

## Steps to Clone and Authorize the Salesforce Org

1. **Clone the Repository into VS Code**

   Open the terminal in VS Code and run the following command to clone the repository:

   **git clone https://github.com/irfanalijarwar/Irfan_Assessment.git**
After cloning, open the project folder in VS Code:

cd your-repository
Authorize the Salesforce Org


Step 1: Activate Multi-Currency in Salesforce

Go to Setup in your Salesforce org.
Search for Company Information in the Quick Find box.
Click Edit.
Enable the Activate Multiple Currencies checkbox.
Save your changes.
Add Currencies (EUR, GBP)
After enabling multi-currency, go to Setup and search for Manage Currencies.
Click New to add new currencies.
Add Euro (EUR) and British Pound (GBP) with their respective conversion rates.
Save your changes.

Step 2: Deploy the Project Components in Sequence

2.1 Deploy the FlexiPage (First)
The first step is to deploy the FlexiPage. You can deploy the FlexiPage using the following command:

sfdx force:source:deploy -p force-app/main/default/flexipages -u <org-name>

2.2 Deploy Global Value Sets (Second)
After deploying the FlexiPage, deploy the Global Value Sets:

sfdx force:source:deploy -p force-app/main/default/globalValueSets -u <org-name>

2.3 Deploy Objects (Third)
Next, deploy the custom objects and fields. Run the following command to deploy a specific object:

sfdx force:source:deploy -p force-app/main/default/objects -u <org-name>

2.4 Deploy the Entire Project (Last)
Once you've deployed the key components, you can deploy the rest of the project:

sfdx force:source:deploy -p force-app/main/default -u <org-name>

Step 3: Generate Client Credentials for the Connected App for testing ProductPricing API class.


Data Model Design

1. Product2 Object:
Purpose: Stores the core product information (e.g., Standard, Black, Metal cards).

2. Pricebook2 Object:
Purpose: Represents different pricebooks (e.g., Standard Pricebook, Country-Specific Pricebooks, Special Offers Pricebook).
Approach: Use separate pricebooks for different regions or special offers. For example, you could have a Standard Pricebook, DE Pricebook, UK Pricebook and a Special Offer Pricebook.
Custom Fields:
Country (Picklist): Captures the country for which pricebook is being created.

3. PricebookEntry Object:
Purpose: Links products to pricebooks and defines specific prices based on contract length, special packages, or other factors.
Custom Fields:
Contract_Length__c (Picklist): Captures the contract length that the price applies to.
UnitPrice (Text): Captures actual cost of the product.
ATM_Fee_in_Other_Currencies__c (Percent): Stores the ATM fees percentage.
Card_Replacement_Cost__c (Currency): Stores Card replacement cost.
These custom fields on PricebookEntry allow you to easily modify the pricing for a product based on new factors like contract length or special offers, without needing to modify the base product details.

Flexibility and Scalability

1. To Modify an Existing Product:
Simply update the PricebookEntry to reflect any new contract lengths or pricing changes.

2. To Add a New Product:
Create a new Product2 record with relevant fields.
Add PricebookEntry records for each pricebook based on region and currency, defining the contract length prices and fees.
By storing contract length and other data in the PricebookEntry, you maintain flexibility to modify or add new products without modifying the core system.

3. Adding New Package:
If a new pricing package is introduced in the future (e.g., loyalty, Christmas), you can add a new Pricebook and attach PricebookEntry records to handle these scenarios without modifying existing records or product data.

Example Implementation

Scenario: Adding a New Product with 12 month Contract Lengths
Let’s assume we’re introducing a Metal Card with 12 month contract.

Product2 Record:
Name: Metal

PricebookEntry Records:
Contract_Length__c: 12 Months
Pricebook: Standard Pricebook, DE Pricebook, UK Pricebook, Special Package
UnitPrice: €20,00
ATM_Fee_in_Other_Currencies__c: 1.7%
Card_Replacement_Cost__c: €45,00


### Key Additions:
- **Data Model Design**: Explanation of the objects and fields used in the project, specifically for `Product2`, `Pricebook2`, and `PricebookEntry`.
- **Flexibility and Scalability**: Instructions on how to modify existing products, add new products, and introduce new pricing packages.
- **Example Implementation**: A practical scenario of adding a new product with special offers and multiple contract lengths.
