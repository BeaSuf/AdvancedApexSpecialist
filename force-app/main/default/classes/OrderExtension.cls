/**
 * @name OrderExtension
 * @description This class is provided for you to facilitate the Super Badge
**/
public without sharing class OrderExtension {

    public Order orderRecord {get;set;}
    public List<OrderItem> orderItemList {get;set;}
    public String selectedFamily {get;set;}
    public List<ChartHelper.ChartData> pieData {get;set;}
    public Decimal total {get;set;}

    public Map<Id,OrderItem> orderItemMap;
    ApexPages.StandardSetController standardSetController;

    public OrderExtension(ApexPages.StandardController standardController){
        orderRecord = (Order)standardController.getRecord();
        orderItemMap = new Map<Id,OrderItem>();
        if ( orderRecord.Id != null ){
            orderRecord = queryOrderRecord(orderRecord.Id);
        }

        initOrderItemData();
        queryAllActiveProductsByFamily();
    }

    //ToDo - Initial data load
    // populate orderItemMap with queried order items and
    // load chart data with initial items
    private void initOrderItemData(){
        for (OrderItem orderItem : orderRecord.OrderItems) {
            orderItemMap.put(orderItem.Product2Id, orderItem);
        }

        loadChartData();
    }

    //ToDo - The pie chart should display a wedge for each item in the order, with the value of the wedge equal to the quantity multiplied by the unit price
    private void loadChartData(){
        this.total = 0;
        pieData = new List<ChartHelper.ChartData>();

        for (OrderItem orderItem : orderItemMap.values()) {
            Double orderItemTolalPrice = (orderItem.Quantity * orderItem.UnitPrice);
            pieData.add(new ChartHelper.ChartData(orderItem.Product2.Name, orderItemTolalPrice));
            total += orderItemTolalPrice;
        }
    }

    //ToDo - The Products available for use on the page will be the entire set of all Active Products that Millennium Delivery sells.
    // Use the DEFAULT_ROWS constant to limit the number of rows displayed at one time in the product lis
    private void queryAllActiveProductsByFamily(){
        String query = 'SELECT Id, Pricebook2Id, Product2Id, UnitPrice, isActive, Product2.Name, Product2.Family, Product2.Quantity_Remaining__c ' +
                        'FROM PricebookEntry ' +
                        'WHERE isActive = true ';
        if(String.isNotBlank(selectedFamily) && selectedFamily != Constants.SELECT_ONE){
            query += 'AND Product2.Family = \'' + selectedFamily + '\'';
        }

        standardSetController = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        standardSetController.setPageSize(Constants.DEFAULT_ROWS);

        populateOrderItemList();
    }

    //ToDo: Implement your own method to populate orderItemList
    //  that you will call after pagination and/or family selection
    private void populateOrderItemList(){
        orderItemList= new List<OrderItem>();

        List<SObject> recordsSet = standardSetController.getRecords();

        if(recordsSet != null && recordsSet.size() > 0) {
            for(SObject obj : recordsSet){
                PricebookEntry pbEntry = (PricebookEntry)obj;

                if(orderItemMap.containsKey(pbEntry.Product2Id)){
                    orderItemList.add(orderItemMap.get(pbEntry.Product2Id));
                } else {
                    OrderItem orderItem = new OrderItem(
                        Quantity = 0,
                        PriceBookEntryId = pbEntry.Id,
                        Product2Id = pbEntry.Product2Id,
                        UnitPrice= pbEntry.UnitPrice,
                        Product2 = pbEntry.Product2
                    );
                    orderItemList.add(orderItem);
                    orderItemMap.put(pbEntry.Product2Id, orderItem);
                }
            }
        }
    }

    /**
     * @name OnFieldChange
     * @description
    **/
    public void onFieldChange(){
        //ToDo: Implement logic to store the values changed on the page
        //      and populate pieData
        //      and populate total

        for (OrderItem orderItem : orderItemList) {
            orderItemMap.put(orderItem.Product2Id, orderItem);
        }

       loadChartData();
    }

    /**
     * @name SelectFamily
     * @description
    **/
    public void selectFamily(){
        //ToDo: Implement logic to filter based on the selected product family
        queryAllActiveProductsByFamily();
    }


    /**
     * @name Save
     * @description
    **/
    public void save(){
        //ToDo: Implement logic to save the Order and populated OrderItems
        SavePoint sp = Database.setSavepoint();

        try {
            if(orderRecord.Pricebook2Id == null){
                orderRecord.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
            }

            upsert orderRecord;

            // Only Order Items with a Quantity greater than zero should be saved; others should not.
            // When editing an existing Order, any Order Items that have been modified to have a Quantity of zero should be deleted

            List<OrderItem> orderItemsToUpsert = new List<OrderItem>();
            List<OrderItem> orderItemsToDelete = new List<OrderItem>();

            for (OrderItem orderItem : orderItemMap.values()) {
                if (orderItem.Quantity > 0) {
                    if(orderItem.OrderId == null){
                        orderItem.OrderId = orderRecord.Id;
                    }
                    orderItemsToUpsert.add(orderItem);
                } else if(orderItem.Id != null){
                    orderItemsToDelete.add(new OrderItem(Id=orderItem.Id));
                    orderItem.Id = null;
                }
            }

            upsert orderItemsToUpsert;
            delete orderItemsToDelete;


            //If successful clear the list and display an informational message
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, orderItemsToUpsert.size() + ' Inserted and ' + orderItemsToDelete.size() + ' Deleted.'));
        } catch (Exception e){
            System.debug('Exception occured:' + e.getMessage());
            Database.rollback(sp);
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Constants.ERROR_MESSAGE));
        }
    }


    /**
     * @name First
     * @description
    **/
    public void first(){
        standardSetController.first();
        populateOrderItemList();
    }


    /**
     * @name Next
     * @description
    **/
    public void next(){
        standardSetController.next();
        populateOrderItemList();
    }


    /**
     * @name Previous
     * @description
    **/
    public void previous(){
        standardSetController.previous();
        populateOrderItemList();
    }

    /**
     * @name Last
     * @description
    **/
    public void last(){
        standardSetController.last();
        populateOrderItemList();
    }

    /**
     * @name GetHasPrevious
     * @description
    **/
    public Boolean getHasPrevious(){
        return standardSetController.getHasPrevious();
    }

    /**
     * @name GetHasNext
     * @description
    **/
    public Boolean getHasNext(){
        return standardSetController.getHasNext();
    }

    /**
     * @name GetTotalPages
     * @description
    **/
    public Integer getTotalPages(){
        return (Integer) Math.ceil(standardSetController.getResultSize()/(Decimal) Constants.DEFAULT_ROWS);
    }

    /**
     * @name GetPageNumber
     * @description
    **/
    public Integer getPageNumber(){
        return standardSetController.getPageNumber();
    }

    /**
     * @name GetFamilyOptions
     * @description
    **/
    public List<SelectOption> getFamilyOptions(){
        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(Constants.SELECT_ONE, Constants.SELECT_ONE));
        for (Schema.PicklistEntry pickListEntry : Constants.PRODUCT_FAMILY) {
            if(pickListEntry.Active == true) {
                options.add(new SelectOption(pickListEntry.getValue(), pickListEntry.getLabel()));
            }
        }

        return options;
    }

    /**
     * @name QueryOrderRecord
     * @description
    **/
    public static Order queryOrderRecord(Id orderId){
        return [
            SELECT Id, AccountId, EffectiveDate, Name, Status, Pricebook2Id,
                (
                    SELECT Id, OrderId, Quantity, UnitPrice, PricebookEntryId, Product2Id, Product2.Name, Product2.Family, Product2.Quantity_Remaining__c
                    FROM OrderItems
                )
            FROM Order
            WHERE Id = :orderId
            WITH SECURITY_ENFORCED
        ];
    }
}