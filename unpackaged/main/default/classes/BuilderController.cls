@isTest
global class BuilderController {

    /*------------------------------------------------------------------------
                 AccountsbyOpportunityBuilderStart
    ------------------------------------------------------------------------*/
    public class AccountsbyOpportunityBuilder {
        private Accounts_by_Opportunity__c obj = new Accounts_by_Opportunity__c();

        public AccountsbyOpportunityBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        public AccountsbyOpportunityBuilder withAccount(Account value) {
             obj.Account__c = value.Id;
             return this;
        }

        public AccountsbyOpportunityBuilder withOpportunity(Opportunity value) {
             obj.Opportunity__c = value.Id;
             return this;
        }

         public Accounts_by_Opportunity__c build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: Account__c, Opportunity__c. */
    public static AccountsbyOpportunityBuilder anAccountsbyOpportunity() { return new AccountsbyOpportunityBuilder(); }

    /*------------------------------------------------------------------------
                 AccountsbyOpportunityBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 AccountBuilderStart
    ------------------------------------------------------------------------*/
     public class AccountBuilder {
        private Account obj = new Account(Name = 'STRING');

        public AccountBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        /** (2022-04-29 12:37:50) Valores disponibles:  'Competitor', 'Customer', 'Integrator', 'Parent', 'Prospect', 'Reseller', 'Other' */
        public AccountBuilder withType(String value) {
             obj.Type = value;
             return this;
        }

        public AccountBuilder withBillingStreet(String value) {
             obj.BillingStreet = value;
             return this;
        }

        public AccountBuilder withBillingCity(String value) {
             obj.BillingCity = value;
             return this;
        }

        public AccountBuilder withBillingState(String value) {
             obj.BillingState = value;
             return this;
        }

        public AccountBuilder withBillingPostalCode(String value) {
             obj.BillingPostalCode = value;
             return this;
        }

        public AccountBuilder withBillingCountry(String value) {
             obj.BillingCountry = value;
             return this;
        }

        public AccountBuilder withPhone(String value) {
             obj.Phone = value;
             return this;
        }

        public AccountBuilder withCopyBillingAddresstoShippingAddress(Boolean value) {
             obj.Copy_Billing_Address_to_Shipping_Address__c = value;
             return this;
        }

        public AccountBuilder withPriceBook(Pricebook2 value) {
            obj.Price_Book__c = value.Id;
            return this;
        }

        /** (2023-02-09 13:24:59) Valores disponibles:  'SURAMERICA', 'NORTEAMERICA' */
        public AccountBuilder withELMEquipodeVentas(String value) {
            obj.ELM_Equipo_de_Ventas__c = value;
            return this;
       }

         public Account build() {
             return obj;
        }

        /** (2022-04-29 12:45:45) Valores disponibles:  'Africa', 'Canada', 'East APAC', 'Mexico/Central America/Caribbean', 'Middle East/Europe', 'Russia/CIS/Mongolia', 'USA', 'West APAC', 'Chile', 'Colombia', 'Ecuador', 'Guyana', 'Guyana Francesa', 'Paraguay', 'Perú', 'Suriname', 'Uruguay', 'Venezuela', 'Panamá' */
        public AccountBuilder withRegion(String value) {
            obj.Region__c = value;
            return this;
       }

        /** (2022-08-18 15:46:15) Valores disponibles:  'Mining', 'Aggregate', 'Construction', 'Aerospace & Defense', 'Energy', 'Government', 'Environmental', 'Manufacturing', 'Other' */
        public AccountBuilder withIELMCompetitorndustry(String value) {
            obj.IELM_Competitor_ndustry__c = value;
            return this;
       }

        public AccountBuilder withELMCompetitorPhone(String value) {
            obj.ELM_Competitor_Phone__c = value;
            return this;
        }

        public AccountBuilder withVendedorAlertaTemprana(User value) {
            obj.Vendedor_Alerta_Temprana__c = value.Id;
            return this;
        }


    }

    public static AccountBuilder anAccount() { return new AccountBuilder(); }

    public static AccountBuilder anAccountCompetitor() { 
        AccountBuilder val = new AccountBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Account', 'Competitor').Id;
        return val;
    }

    public static AccountBuilder anAccountCustomer() { 
        AccountBuilder val = new AccountBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Account', 'Customer').Id;
        return val;
    }

    /*------------------------------------------------------------------------
                 AccountBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 OpportunityBuilderStart
    ------------------------------------------------------------------------*/
    public class OpportunityBuilder {
        private Opportunity obj = new Opportunity(Name = 'STRING',
            StageName = 'Qualify Opportunity',
            CloseDate = Date.today(),
            Description = 'Test description',
            Ship_Date__c = System.today() + 5
        );

        public OpportunityBuilder withAccountId(Account value) {
             obj.AccountId = value.Id;
             return this;
        }

        public OpportunityBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        /** (2022-04-29 14:23:00) Valores disponibles:  'Qualify Opportunity', 'Qualification', 'Identify Decision Makers', 'Update Decision Makers', 'Create Account Plan', 'Update Account Plan', 'Develop Technical Proposal', 'Meeting Scheduled', 'Develop Commercial Proposal', 'Update Commercial Proposal', 'Proposal/Price Quote', 'Present Proposal', 'Negotiation/Review', 'Closed Won', 'Closed Lost', 'Closed - Inactive' */
        public OpportunityBuilder withStageName(String value) {
             obj.StageName = value;
             return this;
        }

        /** (2022-04-29 14:23:00) Valores disponibles:  'Liners', 'Crusher_Products', 'Grinding Media' */
        public OpportunityBuilder withType(String value) {
             obj.Type = value;
             return this;
        }

        /** (2022-04-29 14:23:00) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public OpportunityBuilder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Si', 'No' */
        public OpportunityBuilder withELMPropuestaaprobadaconcdigodepieza(String value) {
            obj.ELM_Propuestaaprobadacon_c_digo_de_pieza__c = value;
            return this;
        }

        public OpportunityBuilder withELMCdigoanteriorsihubiese(String value) {
            obj.ELM_C_digo_anterior_si_hubiese__c = value;
            return this;
        }

        public OpportunityBuilder withELMCantidadrequerida(String value) {
            obj.ELM_Cantidad_requerida__c = value;
            return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Si', 'No' */
        public OpportunityBuilder withELMInventariodelclienteactualrevisado(String value) {
            obj.ELM_Inventariodelcliente_actual_revisado__c = value;
            return this;
        }

        public OpportunityBuilder withELMPlazorequerido(String value) {
            obj.ELM_Plazo_requerido__c = value;
            return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Si', 'No' */
        public OpportunityBuilder withELMGarantias(String value) {
            obj.ELM_Garantias__c = value;
            return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Si', 'No' */
        public OpportunityBuilder withELMCompromisodecompradelcliente(String value) {
            obj.ELM_Compromiso_de_compra_del_cliente__c = value;
            return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Si', 'No' */
        public OpportunityBuilder withELMVBIvan(String value) {
            obj.ELM_VB_Ivan__c = value;
            return this;
        }

        /** (2022-07-22 14:06:50) Valores disponibles:  'Yes', 'No' */
        public OpportunityBuilder withHasOC(String value) {
            obj.Has_OC__c = value;
            return this;
        }

        public OpportunityBuilder withDescription(String value) {
            obj.Description = value;
            return this;
        }

        public OpportunityBuilder withShipDate(Date value) {
            obj.Ship_Date__c = value;
            return this;
        }

        public OpportunityBuilder withELMActivationDateReal(Date value) {
            obj.ELM_Activation_Date_Real__c = value;
            return this;
        }
        
        /** (2023-02-13 09:53:19) Valores disponibles:  'To Follow', 'En Tramite', 'Con OC' */
        public OpportunityBuilder withELMOrderType(String value) {
            obj.ELM_Order_Type__c = value;
            return this;
        }

         public Opportunity build() {
             return obj;
        }

    }

    public static OpportunityBuilder anOpportunity() { return new OpportunityBuilder(); }

    public static OpportunityBuilder anOpportunityComponentServices() { 
        OpportunityBuilder val = new OpportunityBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Opportunity', 'Component_Services').Id;
        return val;
    }

    public static OpportunityBuilder anOpportunityGrindingMedia() { 
        OpportunityBuilder val = new OpportunityBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Opportunity', 'Grinding_Media').Id;
        return val;
    }

    public static OpportunityBuilder anOpportunityRecurringSale() { 
        OpportunityBuilder val = new OpportunityBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Opportunity', 'Recurring_Sale').Id;
        return val;
    }

    public static OpportunityBuilder anOpportunityTrialSale() { 
        OpportunityBuilder val = new OpportunityBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Opportunity', 'Trial_Sale').Id;
        return val;
    }

    /*------------------------------------------------------------------------
                 OpportunityBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 AssetsbyOpportunityBuilderStart
    ------------------------------------------------------------------------*/
    public class AssetsbyOpportunityBuilder {
        private Assets_by_Opportunity__c obj = new Assets_by_Opportunity__c();

        public AssetsbyOpportunityBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        /** (2022-05-03 08:57:04) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public AssetsbyOpportunityBuilder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

        public AssetsbyOpportunityBuilder withOpportunity(Opportunity value) {
             obj.Opportunity__c = value.Id;
             return this;
        }

        public AssetsbyOpportunityBuilder withAsset(Asset value) {
             obj.Asset__c = value.Id;
             return this;
        }

         public Assets_by_Opportunity__c build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: Opportunity__c, Asset__c. */
    public static AssetsbyOpportunityBuilder anAssetsbyOpportunity() { return new AssetsbyOpportunityBuilder(); }

    /*------------------------------------------------------------------------
                 AssetsbyOpportunityBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 AssetBuilderStart
    ------------------------------------------------------------------------*/
     public class AssetBuilder {
        private Asset obj = new Asset(Name = 'STRING');

        public AssetBuilder withAccountId(Account value) {
            obj.AccountId = value.Id;
            return this;
       }

       public AssetBuilder withRecordTypeId(RecordType value) {
        obj.RecordTypeId = value.Id;
        return this;
        }

        public AssetBuilder withIsCompetitorProduct(Boolean value) {
             obj.IsCompetitorProduct = value;
             return this;
        }

        public AssetBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        public AssetBuilder withIsInternal(Boolean value) {
             obj.IsInternal = value;
             return this;
        }

        public AssetBuilder withMEElecmetalEquipment(Boolean value) {
             obj.ME_Elecmetal_Equipment__c = value;
             return this;
        }

        public AssetBuilder withCurrentlyInstalled(Boolean value) {
             obj.Currently_Installed__c = value;
             return this;
        }

        public AssetBuilder withPreviouslyInstalled(Boolean value) {
             obj.Previously_Installed__c = value;
             return this;
        }

        public AssetBuilder withNeverInstalled(Boolean value) {
             obj.Never_Installed__c = value;
             return this;
        }

        /** (2022-05-03 10:21:38) Valores disponibles:  'Alerta Temprana', 'Bolas (Grinding Media)', 'Chancado', 'Chutes', 'GET', 'Maestranza', 'Molienda', 'Ollas', 'Partes y Respuestos' */
        public AssetBuilder withLineofBusiness(String value) {
             obj.Line_of_Business__c = value;
             return this;
        }

         public Asset build() {
             return obj;
        }

    }

    public static AssetBuilder anAsset() { return new AssetBuilder(); }

    public static AssetBuilder anAssetCompetitor() { 
        AssetBuilder val = new AssetBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Asset', 'Competitor').Id;
        return val;
    }

    public static AssetBuilder anAssetCustomer() { 
        AssetBuilder val = new AssetBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Asset', 'Customer').Id;
        return val;
    }

    /*------------------------------------------------------------------------
                 AssetBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 ELMAccountsByAssetBuilderStart
    ------------------------------------------------------------------------*/
    public class ELMAccountsByAssetBuilder {
        private ELM_Accounts_By_Asset__c obj = new ELM_Accounts_By_Asset__c();

        public ELMAccountsByAssetBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        public ELMAccountsByAssetBuilder withAccount(Account value) {
             obj.Account__c = value.Id;
             return this;
        }

        public ELMAccountsByAssetBuilder withAsset(Asset value) {
             obj.Asset__c = value.Id;
             return this;
        }

         public ELM_Accounts_By_Asset__c build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: Account__c, Asset__c. */
    public static ELMAccountsByAssetBuilder anELMAccountsByAsset() { return new ELMAccountsByAssetBuilder(); }

    /*------------------------------------------------------------------------
                 ELMAccountsByAssetBuilderEnd
    ------------------------------------------------------------------------*/

        /*------------------------------------------------------------------------
                 ELMProductsbyAssetBuilderStart
    ------------------------------------------------------------------------*/
    public class ELMProductsbyAssetBuilder {
        private ELM_Products_by_Asset__c obj = new ELM_Products_by_Asset__c();

        public ELMProductsbyAssetBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        public ELMProductsbyAssetBuilder withELMAsset(Asset value) {
             obj.ELM_Asset__c = value.Id;
             return this;
        }

        public ELMProductsbyAssetBuilder withELMProduct(Product2 value) {
             obj.ELM_Product__c = value.Id;
             return this;
        }

         public ELM_Products_by_Asset__c build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: ELM_Asset__c. */
    public static ELMProductsbyAssetBuilder anELMProductsbyAsset() { return new ELMProductsbyAssetBuilder(); }

    /*------------------------------------------------------------------------
                 ELMProductsbyAssetBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 PricebookEntryBuilderStart
    ------------------------------------------------------------------------*/
    public class PricebookEntryBuilder {
        private PricebookEntry obj = new PricebookEntry(CurrencyIsoCode = 'AUD',
            UnitPrice = 1.1
        );

        public PricebookEntryBuilder withPricebook2Id(Pricebook2 value) {
             obj.Pricebook2Id = value.Id;
             return this;
        }

        public PricebookEntryBuilder withProduct2Id(Product2 value) {
             obj.Product2Id = value.Id;
             return this;
        }

        /** (2022-05-16 09:49:16) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public PricebookEntryBuilder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

        public PricebookEntryBuilder withUnitPrice(Decimal value) {
             obj.UnitPrice = value;
             return this;
        }

        public PricebookEntryBuilder withIsActive(Boolean value) {
             obj.IsActive = value;
             return this;
        }

        public PricebookEntryBuilder withUseStandardPrice(Boolean value) {
             obj.UseStandardPrice = value;
             return this;
        }

         public PricebookEntry build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: Pricebook2Id, Product2Id. */
    public static PricebookEntryBuilder aPricebookEntry() { return new PricebookEntryBuilder(); }

    /*------------------------------------------------------------------------
                 PricebookEntryBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 Pricebook2BuilderStart
    ------------------------------------------------------------------------*/
     public class Pricebook2Builder {
        private Pricebook2 obj = new Pricebook2(Name = 'STRING');

        public Pricebook2Builder withName(String value) {
             obj.Name = value;
             return this;
        }

        /** (2022-05-16 09:49:25) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public Pricebook2Builder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

        public Pricebook2Builder withIsActive(Boolean value) {
             obj.IsActive = value;
             return this;
        }

         public Pricebook2 build() {
             return obj;
        }

    }

    public static Pricebook2Builder aPricebook2() { return new Pricebook2Builder(); }

    /*------------------------------------------------------------------------
                 Pricebook2BuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 Product2BuilderStart
    ------------------------------------------------------------------------*/
     public class Product2Builder {
        private Product2 obj = new Product2(Name = 'STRING',
            CurrencyIsoCode = 'AUD'
        );

        public Product2Builder withName(String value) {
             obj.Name = value;
             return this;
        }

        /** (2022-05-16 09:51:42) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public Product2Builder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

         public Product2 build() {
             return obj;
        }

    }

    public static Product2Builder aProduct2() { return new Product2Builder(); }

    /*------------------------------------------------------------------------
                 Product2BuilderEnd
    ------------------------------------------------------------------------*/

        /*------------------------------------------------------------------------
                 UserBuilderStart
    ------------------------------------------------------------------------*/
    public class UserBuilder {
        private User obj = new User(Username = 'test@elecmetal.com',
            LastName = 'test lastname',
            Email = 'test@elecmetal.com',
            Alias = 'test.ln',
            CommunityNickname = 'somenickname',
            TimeZoneSidKey = 'Pacific/Kiritimati',
            LocaleSidKey = 'sq_AL',
            EmailEncodingKey = 'UTF-8',
            CurrencyIsoCode = 'AUD',
            LanguageLocaleKey = 'en_US',
            DigestFrequency = 'D',
            DefaultGroupNotificationFrequency = 'P'
        );

        public UserBuilder withProfileId(Profile value) {
             obj.ProfileId = value.Id;
             return this;
        }

        /** (2022-08-29 15:51:19) Valores disponibles:  'SURAMERICA', 'NORTEAMERICA' */
        public UserBuilder withELMEquipodeVentas(String value) {
            obj.ELM_Equipo_de_Ventas__c = value;
            return this;
        }

        /** (2022-08-29 16:04:05) Valores disponibles:  'Alerta Temprana', 'Bolas (Grinding Media)', 'Chancado', 'Chutes', 'GET', 'Maestranza', 'Molienda', 'Ollas', 'Partes y Respuestos' */
        public UserBuilder withLinesofbusiness(String value) {
             obj.Lines_of_business__c = value;
             return this;
        }

        public UserBuilder withUsername(String value) {
            obj.Username = value;
            return this;
       }

       public UserBuilder withEmail(String value) {
            obj.Email = value;
            return this;
       }

       public UserBuilder withAlias(String value) {
            obj.Alias = value;
            return this;
       }

        public UserBuilder withCommunityNickname(String value) {
        obj.CommunityNickname = value;
        return this;
        }

        public User build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: ProfileId. */
    public static UserBuilder anUser() { return new UserBuilder(); }

    /*------------------------------------------------------------------------
                 UserBuilderEnd
    ------------------------------------------------------------------------*/
 
    /*------------------------------------------------------------------------
                 ContactBuilderStart
    ------------------------------------------------------------------------*/
    public class ContactBuilder {
        private Contact obj = new Contact(LastName = 'STRING');

        public ContactBuilder withAccountId(Account value) {
             obj.AccountId = value.Id;
             return this;
        }

        public ContactBuilder withLastName(String value) {
             obj.LastName = value;
             return this;
        }

        public ContactBuilder withPhone(String value) {
             obj.Phone = value;
             return this;
        }

        public ContactBuilder withEmail(String value) {
             obj.Email = value;
             return this;
        }

        public ContactBuilder withLineofBusiness(String value) {
             obj.Line_of_Business__c = value;
             return this;
        }

        /** (2022-05-19 10:37:22) Valores disponibles:  'Comprador', 'Tomador de decisiones', 'Influenciador', 'Usuario' */
        public ContactBuilder withRole(String value) {
             obj.Role__c = value;
             return this;
        }

         public Contact build() {
             return obj;
        }

    }

    public static ContactBuilder aContact() { return new ContactBuilder(); }

    /*------------------------------------------------------------------------
                 ContactBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 AfterSalesBuilderStart
    ------------------------------------------------------------------------*/
    public class AfterSalesBuilder {
        private After_Sales__c obj = new After_Sales__c();

        public AfterSalesBuilder withOwnerId(Group value) {
             obj.OwnerId = value.Id;
             return this;
        }
        public AfterSalesBuilder withOwnerId(User value) {
             obj.OwnerId = value.Id;
             return this;
        }

        /** (2022-05-22 19:31:32) Valores disponibles:  'AUD', 'CAD', 'EUR', 'USD' */
        public AfterSalesBuilder withCurrencyIsoCode(String value) {
             obj.CurrencyIsoCode = value;
             return this;
        }

         public After_Sales__c build() {
             return obj;
        }

    }

    public static AfterSalesBuilder anAfterSales() { return new AfterSalesBuilder(); }

    /*------------------------------------------------------------------------
                 AfterSalesBuilderEnd
    ------------------------------------------------------------------------*/

        /*------------------------------------------------------------------------
                 ContractBuilderStart
    ------------------------------------------------------------------------*/
    public class ContractBuilder {
        private Contract obj = new Contract(Status = 'In Approval Process');

        public ContractBuilder withAccountId(Account value) {
             obj.AccountId = value.Id;
             return this;
        }

        public ContractBuilder withStartDate(Date value) {
             obj.StartDate = value;
             return this;
        }

        public ContractBuilder withContractTerm(Integer value) {
             obj.ContractTerm = value;
             return this;
        }

        /** (2022-05-23 00:30:19) Valores disponibles:  'In Approval Process', 'Activated', 'Draft', 'Expired' */
        public ContractBuilder withStatus(String value) {
             obj.Status = value;
             return this;
        }

        /** (2022-05-23 00:30:19) Valores disponibles:  'Standard', 'Consignment' */
        public ContractBuilder withELMContractType(String value) {
             obj.ELM_Contract_Type__c = value;
             return this;
        }

        public ContractBuilder withELMContractAmount(Decimal value) {
             obj.ELM_Contract_Amount__c = value;
             return this;
        }

        public ContractBuilder withELMLineoofBusiness(String value) {
             obj.ELM_Line_oof_Business__c = value;
             return this;
        }

         public Contract build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: AccountId. */
    public static ContractBuilder aContract() { return new ContractBuilder(); 
    
    }

    /*------------------------------------------------------------------------
                 ContractBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 QuoteBuilderStart
    ------------------------------------------------------------------------*/
    public class QuoteBuilder {
        private Quote obj = new Quote(Name = 'STRING');

        public QuoteBuilder withName(String value) {
             obj.Name = value;
             return this;
        }

        public QuoteBuilder withOpportunityId(Opportunity value) {
             obj.OpportunityId = value.Id;
             return this;
        }

         public Quote build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: OpportunityId. */
    public static QuoteBuilder aQuote() { return new QuoteBuilder(); }

    /*------------------------------------------------------------------------
                 QuoteBuilderEnd
    ------------------------------------------------------------------------*/

        /*------------------------------------------------------------------------
                 OrderBuilderStart
    ------------------------------------------------------------------------*/
    public class OrderBuilder {
        private Order obj = new Order(EffectiveDate = Date.today(),
            Status = 'Draft',
            CurrencyIsoCode = 'AUD'
        );

        public OrderBuilder withAccountId(Account value) {
             obj.AccountId = value.Id;
             return this;
        }

        public OrderBuilder withEffectiveDate(Date value) {
             obj.EffectiveDate = value;
             return this;
        }

        /** (2022-05-23 09:03:13) Valores disponibles:  'Draft', 'Activated' */
        public OrderBuilder withStatus(String value) {
             obj.Status = value;
             return this;
        }

         public Order build() {
             return obj;
        }

    }

    public static OrderBuilder anOrder() { return new OrderBuilder(); }

    /*------------------------------------------------------------------------
                 OrderBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 TaskBuilderStart
    ------------------------------------------------------------------------*/
    public class TaskBuilder {
        private Task obj = new Task(Status = 'Not Started',
            Priority = 'High'
        );

        public TaskBuilder withSubject(String value) {
             obj.Subject = value;
             return this;
        }

        /** (2022-05-23 10:27:02) Valores disponibles:  'Not Started', 'In Progress', 'Completed', 'Waiting on someone else', 'Deferred' */
        public TaskBuilder withStatus(String value) {
             obj.Status = value;
             return this;
        }

        /** (2022-05-23 10:27:02) Valores disponibles:  'High', 'Normal', 'Low' */
        public TaskBuilder withPriority(String value) {
             obj.Priority = value;
             return this;
        }

        public TaskBuilder withOwnerId(User value) {
             obj.OwnerId = value.Id;
             return this;
        }

         public Task build() {
             return obj;
        }

    }

    public static TaskBuilder aTask() { return new TaskBuilder(); }

    public static TaskBuilder aTaskTask() { 
        TaskBuilder val = new TaskBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Task', 'Task').Id;
        return val;
    }

    public static TaskBuilder aTaskTripReports() { 
        TaskBuilder val = new TaskBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Task', 'Trip_Reports').Id;
        return val;
    }

    public static TaskBuilder aTaskWhatsApp() { 
        TaskBuilder val = new TaskBuilder();
        val.obj.RecordTypeId = XappiaHelper.getRecordType('Task', 'WhatsApp').Id;
        return val;
    }

    /*------------------------------------------------------------------------
                 TaskBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 LeadBuilderStart
    ------------------------------------------------------------------------*/
    public class LeadBuilder {
        private Lead obj = new Lead(LastName = 'STRING',
            Company = 'STRING',
            Status = 'New'
        );

        public LeadBuilder withLastName(String value) {
             obj.LastName = value;
             return this;
        }

        public LeadBuilder withCompany(String value) {
             obj.Company = value;
             return this;
        }

        /** (2022-05-23 11:35:08) Valores disponibles:  'New', 'Contacted', 'Working', 'Qualified', 'Unqualified' */
        public LeadBuilder withStatus(String value) {
             obj.Status = value;
             return this;
        }

         public Lead build() {
             return obj;
        }

    }

    public static LeadBuilder aLead() { return new LeadBuilder(); }

    /*------------------------------------------------------------------------
                 LeadBuilderEnd
    ------------------------------------------------------------------------*/
    /*------------------------------------------------------------------------
                 ELMVaesBuilderStart
    ------------------------------------------------------------------------*/
    public class ELMVaesBuilder {
        private ELM_Vaes__c obj = new ELM_Vaes__c();

        public ELMVaesBuilder withELMProjectName(String value) {
             obj.ELM_Project_Name__c = value;
             return this;
        }

        public ELMVaesBuilder withELMAccount(Account value) {
             obj.ELM_Account__c = value.Id;
             return this;
        }

        /** (2022-07-07 13:43:09) Valores disponibles:  'Crushing', 'Mill Liners', 'Grinding Media', 'Early Alert', 'GET' */
        public ELMVaesBuilder withELMLineOfBusiness(String value) {
             obj.ELM_Line_Of_Business__c = value;
             return this;
        }

        public ELMVaesBuilder withELMContact(Contact value) {
             obj.ELM_Contact__c = value.Id;
             return this;
        }

         public ELM_Vaes__c build() {
             return obj;
        }

    }

    public static ELMVaesBuilder anELMVaes() { return new ELMVaesBuilder(); }

    /*------------------------------------------------------------------------
                 ELMVaesBuilderEnd
    ------------------------------------------------------------------------*/

        /*------------------------------------------------------------------------
                 OpportunityLineItemBuilderStart
    ------------------------------------------------------------------------*/
    public class OpportunityLineItemBuilder {
        private OpportunityLineItem obj = new OpportunityLineItem(Quantity = 1.5);

        public OpportunityLineItemBuilder withOpportunityId(Opportunity value) {
             obj.OpportunityId = value.Id;
             return this;
        }

        public OpportunityLineItemBuilder withProduct2Id(Product2 value) {
             obj.Product2Id = value.Id;
             return this;
        }

        public OpportunityLineItemBuilder withQuantity(Double value) {
             obj.Quantity = value;
             return this;
        }

        public OpportunityLineItemBuilder withUnitPrice(Decimal value) {
             obj.UnitPrice = value;
             return this;
        }

         public OpportunityLineItem build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: OpportunityId. */
    public static OpportunityLineItemBuilder anOpportunityLineItem() { return new OpportunityLineItemBuilder(); }

    /*------------------------------------------------------------------------
                 OpportunityLineItemBuilderEnd
    ------------------------------------------------------------------------*/

    /*------------------------------------------------------------------------
                 AccountShareBuilderStart
    ------------------------------------------------------------------------*/
    public class AccountShareBuilder {
        private AccountShare obj = new AccountShare(AccountAccessLevel = 'Read',
            OpportunityAccessLevel = 'None',
            CaseAccessLevel = 'None'
        );

        public AccountShareBuilder withAccountId(Account value) {
             obj.AccountId = value.Id;
             return this;
        }

        public AccountShareBuilder withUserOrGroupId(Group value) {
             obj.UserOrGroupId = value.Id;
             return this;
        }
        public AccountShareBuilder withUserOrGroupId(User value) {
             obj.UserOrGroupId = value.Id;
             return this;
        }

        /** (2023-02-13 08:31:55) Valores disponibles:  'None', 'Read', 'Edit' */
        public AccountShareBuilder withOpportunityAccessLevel(String value) {
             obj.OpportunityAccessLevel = value;
             return this;
        }

         public AccountShare build() {
             return obj;
        }

    }

    /** It require following fields to can be inserted: AccountId, UserOrGroupId. */
    public static AccountShareBuilder anAccountShare() { return new AccountShareBuilder(); }

    /*------------------------------------------------------------------------
                 AccountShareBuilderEnd
    ------------------------------------------------------------------------*/
 
}