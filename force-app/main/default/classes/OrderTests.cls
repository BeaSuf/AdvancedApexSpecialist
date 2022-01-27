@isTest (seeAllData=false)
private class OrderTests {
    @TestSetup
    static void SetupTestData(){
        TestDataFactory.InsertTestData(Constants.DEFAULT_ROWS);
    }

    @isTest
    static void OrderUpdate_UnitTest(){
        Order order = [SELECT Id, Name, Status FROM Order WHERE Status = :Constants.DRAFT_ORDER_STATUS LIMIT 1];
        Product2 originalProduct = [SELECT Id, Name, Quantity_Ordered__c FROM Product2 LIMIT 1];

        order.Status = Constants.ACTIVATED_ORDER_STATUS;
        update order;

        Product2 updatedProduct = [SELECT Id, Name, Quantity_Ordered__c FROM Product2 LIMIT 1];

        TestDataFactory.VerifyQuantityOrdered(originalProduct, updatedProduct, Constants.DEFAULT_ROWS);
    }

    @isTest
    static void OrderExtension_UnitTest(){
        // Initialise the page
        PageReference pageRef = Page.OrderEdit;
        
        Test.setCurrentPage(pageRef);
        
        Order order = [SELECT Id, Status FROM Order LIMIT 1];

        ApexPages.StandardController stdcontroller = new ApexPages.StandardController(order);
        OrderExtension ext = new OrderExtension(stdcontroller);

        System.assertEquals(5, ext.orderItemList.size());
        
        ext.OnFieldChange();
        ext.SelectFamily();
        ext.Save();
        ext.First();
        ext.Next();
        ext.Previous();
        ext.Last();
        ext.GetHasPrevious();
        ext.GetHasNext();
        ext.GetTotalPages();
        ext.GetPageNumber();
        List<SelectOption> options = ext.GetFamilyOptions();
    }
    
}