@isTest (seeAllData=false)
private class OrderTests {
    @TestSetup
    static void SetupTestData(){
        TestDataFactory.InsertTestData(20);        
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
}