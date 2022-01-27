public class Product2Extension {

    public List<ProductWrapper> productsToInsert {get;set;}

    public Product2Extension(ApexPages.StandardController controller){
        productsToInsert = new List<ProductWrapper>();
        addRows();
    }

    public void AddRows(){
        for ( Integer i=0; i<Constants.DEFAULT_ROWS; i++ ){
            productsToInsert.add( new ProductWrapper() );
        }
    }

    public List<ChartHelper.ChartData> GetInventory(){
        return ChartHelper.GetInventory();
    }

    public PageReference Save(){
        SavePoint sp = Database.setSavepoint();

        Map<Integer, Product2> fullProductRecords = new Map<Integer, Product2>();
		Map<Integer, PriceBookEntry> priceBookEntriesPerProduct = new Map<Integer, PriceBookEntry>();  
        try {
            for (Integer i = 0; i < productsToInsert.size(); i++) {
                // Only entries on the page that have all fields populated should be saved; other entries shouldn’t be saved                
                ProductWrapper pw = productsToInsert[i];
                if(String.isNotBlank(pw.productRecord.Name) &&
                    String.isNotBlank(pw.productRecord.Family) && pw.productRecord.Family!=Constants.SELECT_ONE &&
                    pw.productRecord.isActive &&
                    pw.pricebookEntryRecord.UnitPrice != null && pw.pricebookEntryRecord.UnitPrice != 0 && 
                    pw.productRecord.Initial_Inventory__c != null && pw.productRecord.Initial_Inventory__c != 0){                       
                        fullProductRecords.put(i, pw.productRecord);  
                        priceBookEntriesPerProduct.put(i, pw.pricebookEntryRecord);
                }
            }

            insert fullProductRecords.values();

            List<PriceBookEntry> priceBookEntryRecords = new List<PriceBookEntry>();
            for (Integer index : fullProductRecords.keySet()) {                
                PriceBookEntry pbe = priceBookEntriesPerProduct.get(index);
                pbe.Product2Id = fullProductRecords.get(index).Id;                
                pbe.IsActive = true;
                pbe.Pricebook2Id = Constants.STANDARD_PRICEBOOK_ID;
                priceBookEntryRecords.add(pbe);                
            }
            
            insert priceBookEntryRecords;

            //If successful clear the list and display an informational message
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, fullProductRecords.size() + ' Inserted'));
            productsToInsert.clear();   //Do not remove
            addRows();  //Do not remove
        } catch (Exception e){
            System.debug('Exception occured:' + e.getMessage());
            Database.rollback(sp);
            apexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Constants.ERROR_MESSAGE));
        }
        return null;
    }

    public List<SelectOption> GetFamilyOptions(){
        List<SelectOption> options = new List<SelectOption>();

        options.add(new SelectOption(Constants.SELECT_ONE, Constants.SELECT_ONE));
        for (Schema.PicklistEntry pickListEntry : Constants.PRODUCT_FAMILY) {
            if(pickListEntry.Active == true){
                options.add(new SelectOption(pickListEntry.getValue(), pickListEntry.getLabel()));
            }
        }

        return options;
    }
    
    public class ProductWrapper {
        public Product2 productRecord {get;set;}
        public PriceBookEntry pricebookEntryRecord {get;set;}

        public ProductWrapper() {
            this.productRecord = new Product2(Initial_Inventory__c =0, Name='Test Product', isActive=true);
            this.pricebookEntryRecord = new PricebookEntry(Unitprice=0.0);
        }    
    }
}
    