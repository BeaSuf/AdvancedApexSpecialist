@isTest
private class Product2Tests {

    /**
     * @name product2Extension_UnitTest
     * @description UnitTest for product2Extension
    **/
    static TestMethod void Product2Extension_UnitTest(){

        // Initialise the page
        PageReference productPage = Page.Product2New;
        
        // Prepare test data
        List<Product2> products = TestDataFactory.ConstructProducts(Constants.DEFAULT_ROWS);    
        List<PriceBookEntry> pricebookEntries = TestDataFactory.ConstructPricebookEntries(products);

        // Initialise the standardController
        ApexPages.StandardController controller = new ApexPages.StandardController(products[0]);

        Test.startTest();
            // Initialise the extension controller
            Product2Extension ext = new Product2Extension(controller);

            // At first visit to the page, there should be multiple rows displayed on the screen
            System.assertEquals(Constants.DEFAULT_ROWS, ext.productsToInsert.size());

            // When the Add button is clicked, additional set of rows should be added
            ext.addRows();
            System.assertEquals(Constants.DEFAULT_ROWS * 2, ext.productsToInsert.size());


            // Verify that populated rows are saved and unpopulated rows are not saved. 
            // Loop through the rows in the productsToInsert list and populate the values of the first 5 records, 
            for (Integer i = 0; i < Constants.DEFAULT_ROWS; i++) {
                ext.productsToInsert.get(i).productRecord = products.get(i);
                ext.productsToInsert.get(i).pricebookEntryRecord = pricebookEntries.get(i);
            }
            
            // and then simulate clicking the Save button. Verify that the button worked by asserting that only 5 products were saved.
            ext.save();
            List<Product2> fullProducts = [SELECT Id FROM Product2];
            System.assertEquals(Constants.DEFAULT_ROWS, fullProducts.size());
        Test.stopTest();
    }
}