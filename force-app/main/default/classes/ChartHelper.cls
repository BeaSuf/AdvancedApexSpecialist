public without sharing class ChartHelper {
    @AuraEnabled
    public static List<ChartData> GetInventory(){
        List<ChartData> cht = new List<chartData>();
        //ToDo: Perform a calculation that aggregates active Products that have a positive Quantity_Remaining__c
        //  And return a list of chartData
        //  Where the name is the Product Family and the Qty is the sum of the Quantity_Remaining__c
        AggregateResult[] aggResults = [SELECT Family, SUM(Quantity_Remaining__c) Qty
                                        FROM Product2 
                                        WHERE IsActive = true AND Quantity_Remaining__c > 0
                                        GROUP BY Family ];

        for (AggregateResult aggRes : aggResults) {
            cht.add(new ChartData((String) aggRes.get('Family'), (Decimal) aggRes.get('Qty')));
        }
        return cht;
    }

    public class ChartData {
        public String name {get;set;}
        public Decimal val {get;set;}

        public ChartData(String name, Decimal val){
            this.name = name;
            this.val = val;
        }
    }

}