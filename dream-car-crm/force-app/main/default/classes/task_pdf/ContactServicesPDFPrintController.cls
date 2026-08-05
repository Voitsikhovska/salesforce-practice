public with sharing class ContactServicesPDFPrintController {


    public Contact contactRecord {get;set;}

    public List<Service__c> services {get;set;}



    public ContactServicesPDFPrintController(){


    Id contactId =
        ApexPages.currentPage()
        .getParameters()
        .get('id');



    String recordTypeId =
        ApexPages.currentPage()
        .getParameters()
        .get('recordTypeId');



    Date startDate =
        Date.valueOf(
            ApexPages.currentPage()
            .getParameters()
            .get('startDate')
        );


    Date endDate =
        Date.valueOf(
            ApexPages.currentPage()
            .getParameters()
            .get('endDate')
        );



    contactRecord = [
        SELECT Id, Name
        FROM Contact
        WHERE Id=:contactId
    ];



    services = [
        SELECT Id,
            Name,
            Service_Date__c,
            Notes__c,
            RecordType.Name
        FROM Service__c
        WHERE Contact__c=:contactId
        AND RecordTypeId=:recordTypeId
        AND Service_Date__c >= :startDate
        AND Service_Date__c <= :endDate
        ORDER BY Service_Date__c
    ];


    }

}