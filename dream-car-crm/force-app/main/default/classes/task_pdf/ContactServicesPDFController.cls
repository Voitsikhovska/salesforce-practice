public with sharing class ContactServicesPDFController {

    public Id contactId {get;set;}

    public String selectedRecordTypeId {get;set;}

    public Date startDate {get;set;}

    public Date endDate {get;set;}

    public Boolean saveAsFile {get;set;}


    public List<SelectOption> recordTypes {
        get {
            List<SelectOption> options = new List<SelectOption>();

            for(RecordType rt : [
                SELECT Id, Name
                FROM RecordType
                WHERE SObjectType = 'Service__c'
            ]) {

                options.add(
                    new SelectOption(
                        rt.Id,
                        rt.Name
                    )
                );
            }

            return options;
        }
    }


    public ContactServicesPDFController(
        ApexPages.StandardController controller
    ){

        contactId = controller.getId();

        saveAsFile = false;
    }



public PageReference generatePDF(){

    if (String.isBlank(selectedRecordTypeId) || startDate == null || endDate == null) {
        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.ERROR,
            'Please select a record type and both dates.'
        ));
        return null;
    }

    if (startDate > endDate) {
        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.ERROR,
            'Start date must be before end date.'
        ));
        return null;
    }

    PageReference pdfPage = Page.ServicesPDFPrint; 
    pdfPage.getParameters().put('id', contactId);
    pdfPage.getParameters().put('recordTypeId', selectedRecordTypeId);
    pdfPage.getParameters().put('startDate', String.valueOf(startDate));
    pdfPage.getParameters().put('endDate', String.valueOf(endDate));

    if (saveAsFile) {
        Blob pdfBody = pdfPage.getContentAsPDF();

        Contact contact = [SELECT Id, Name FROM Contact WHERE Id = :contactId];

        ContentVersion file = new ContentVersion();
        file.Title = 'Services_' + contact.Name + '_' + Date.today();
        file.PathOnClient = file.Title + '.pdf';
        file.VersionData = pdfBody;
        file.FirstPublishLocationId = contactId;
        insert file;

        ApexPages.addMessage(new ApexPages.Message(
            ApexPages.Severity.CONFIRM,
            'PDF saved to Contact files.'
        ));
        return null;
    }

    return pdfPage;
}

}