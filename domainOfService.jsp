<%@page import="dm.utils.CustomRemoteException" %>
<%@page import="dm.web.utils.RequestReader,java.sql.Date, dm.web.cust.CustomerBiz, dm.persist.mmaint.PlaceCode,java.util.HashMap"
		errorPage="../common/error.jsp"%>
<%@ page import="dm.persist.cust.*" %>
<%@ page import="dm.persist.common.*" %>
<%@ page import="dm.web.common.*" %>
<%@ page import="dm.common.*" %>

<%@ page import="org.apache.poi.util.StringUtil" %>
<%@ page import="dm.utils.CommonUtils" %>
<%@ page import="dm.web.accounts.AccountOpenBiz" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="dm.persist.mmaint.PlaceStdCode" %>
<%@ page import="java.lang.reflect.Array" %>
<%@include file="../common/top.inc.jsp"%>
<%--#18601 INCAPABLES_ CUSTOMER Changes, Ehsan Yazdani Rad, 2022-July-03 --%>
<%--*******ENTITY, TABLE and related info are DOMAINOFSERVICE(DOS)*******--%>
<%
    final String PS_SAVE_DOS        = "PS_SAVE_DOS";
    final String SEPRATOR           = "///";
    activeTab 	                    = TextUtil.getLocalizedLabel("domain.of.service");
	PAGE_TITLE = TextUtil.getLocalizedLabel("domain.of.service");
	BODY_ONLOAD = "";

	String processingStep 			= request.getParameter("processingStep");
	String changeTxnAare 			= request.getParameter("changeTxnArea");
	String bank 		 			= USER_SESSION.getCommonSess().getBank();
	String userCode 				= USER_SESSION.getCommonSess().getUserCode().toUpperCase();
	Date currDate   				= USER_SESSION.getCommonSess().getCurrentDate();
    CreateCustomerInfo customerInfo = USER_SESSION.getCustSess().getCreateCustomerInfo();
	Customer customer 				= customerInfo.getCustomer();
	dateFormat = USER_SESSION.getCommonSess().getBankDefaultDateFormat();
	String currentDt    			= DateUtil.formatDate(USER_SESSION.getCommonSess().getCurrentDate(), dateFormat);
    int iAction						= 0;
    int srNO 						= 1;
    int index 						= -1;
    String direction = USER_SESSION.getLoginInfo().getLocale().equals(LoginInfo.LOCALE_EN_US) ? "ltr" :"rtl";
    BranchParam branchParam 		= AppMgr.getBranchParam(USER_SESSION.getCommonSess().getBank(), USER_SESSION.getCommonSess().getBranch());
    TransactionAreas[] txnAreas 				= null;
    boolean isModify = false;

    PopInfo countryPInfo = new PopInfo();
    Country country = new Country();
    countryPInfo.setPO(country);
    countryPInfo.setCodeFieldName(TransactionAreas.PROP_SOURCE_COUNTRY_CODE);
    countryPInfo.setDescFieldName(TransactionAreas.PROP_SOURCE_COUNTRY_CODE+"_DESC");
    countryPInfo.setCodeFieldHeader(TextUtil.getLocalizedLabel("country"));
    countryPInfo.setDescFieldHeader(TextUtil.getLocalizedLabel("name"));
    countryPInfo.setPopTitle(TextUtil.getLocalizedLabel("countries.lookup"));
    USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_COUNTRY, countryPInfo);

    PopInfo statePInfo = new PopInfo();
    State state = new State();
    statePInfo.setPO(state);
    statePInfo.setCodeFieldName(TransactionAreas.PROP_SOURCESTATE_CODE);
    statePInfo.setDescFieldName(TransactionAreas.PROP_SOURCESTATE_CODE+"_DESC");
    statePInfo.setCodeFieldHeader(TextUtil.getLocalizedLabel("state"));
    statePInfo.setDescFieldHeader(TextUtil.getLocalizedLabel("name"));
    statePInfo.setPopTitle(TextUtil.getLocalizedLabel("state.lookup"));
    USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_STATE, statePInfo);

    PopInfo countryPinfo2 = new PopInfo();
    Country country2 = new Country();
    countryPinfo2.setPO(country2);
    countryPinfo2.setCodeFieldName(TransactionAreas.PROP_DESTINATION_COUNTRY_CODE);
    countryPinfo2.setDescFieldName(TransactionAreas.PROP_DESTINATION_COUNTRY_CODE+"_DESC");
    countryPinfo2.setCodeFieldHeader(TextUtil.getLocalizedLabel("country"));
    countryPinfo2.setDescFieldHeader(TextUtil.getLocalizedLabel("name"));
    countryPinfo2.setPopTitle(TextUtil.getLocalizedLabel("countries.lookup"));
    USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_COUNTRY2, countryPinfo2);

    PopInfo statePInfo2 = new PopInfo();
    State state2 = new State();
    statePInfo2.setPO(state2);
    statePInfo2.setCodeFieldName(TransactionAreas.PROP_DESTINATION_STATE_CODE);
    statePInfo2.setDescFieldName(TransactionAreas.PROP_DESTINATION_STATE_CODE+"_DESC");
    statePInfo2.setCodeFieldHeader(TextUtil.getLocalizedLabel("state"));
    statePInfo2.setDescFieldHeader(TextUtil.getLocalizedLabel("name"));
    statePInfo2.setPopTitle(TextUtil.getLocalizedLabel("state.lookup"));
    USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_STATE2, statePInfo2);



	int txnType						= customerInfo.getTxnType();
	PAGE_TITLE 						= ((txnType == IConstants.MODIFY)?TextUtil.getLocalizedLabel("customer.modification"):PAGE_TITLE);
	int tabIdx						= 1;
    String sex                      = "";
    boolean auth                    = false;
	DomainOfService domainOfService;
    int ageLocal = -1;
    AccountOpenBiz accountOpenBiz  = new AccountOpenBiz();
    CustomerBiz customerBiz = new CustomerBiz();
    if (customerInfo.getTxnType() == IConstants.AUTHORISE)
    {
        auth = true;
    }
    if (customerInfo.getMisSubCode()!= null)
    {
        if (customerInfo.getMisSubCode().getSubCode().equals("008"))
        {
            sex = "M";
        }
        else
        {
            sex = "F";
        }
    }
    if (request.getParameter("SrNo")!=null) {
        srNO = Integer.parseInt(request.getParameter("SrNo"));
    }
    if (request.getParameter("index")!=null) {
        index = Integer.parseInt(request.getParameter("index"));
    }
    if (request.getParameter("Action")!=null) {
        iAction = Integer.parseInt(request.getParameter("Action"));
    }
    String pattern = "yyyy-MM-dd";
    SimpleDateFormat sdf = new SimpleDateFormat(pattern);
    /*Get range constraints*/
    SearchBiz searchBiz = new SearchBiz();
    RangeConstraints[] matureKinds =searchBiz.fetchRangeConstraintsList(
            DomainOfService.PROP_MATURE_KIND.toUpperCase(),
            DomainOfService.TABLE_NAME.toUpperCase());
    RangeConstraints[] incapableKinds =searchBiz.fetchRangeConstraintsListSortedByReason(
            DomainOfService.PROP_INCAPABLE_KIND.toUpperCase(),
            DomainOfService.TABLE_NAME.toUpperCase());
    // مهجور
    RangeConstraints[] accountOpeningPurpose = searchBiz.fetchRangeConstraintsListSortedByReason(
            DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE.toUpperCase(),
            DomainOfService.TABLE_NAME);
    // بالغ
    RangeConstraints[] accountOpeningPurposeMature = searchBiz.fetchRangeConstraintsListSortedByReason(
            DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE.toUpperCase()+"_MATURE",
            DomainOfService.TABLE_NAME);
    RangeConstraints[] depositPredication = searchBiz.fetchRangeConstraintsListSortedByReason(
            DomainOfService.PROP_DEPOSIT_PREDICATION.toUpperCase(),
            DomainOfService.TABLE_NAME);
    RangeConstraints[] depositReasonPredication = searchBiz.fetchRangeConstraintsListSortedByReason(
            DomainOfService.PROP_DEPOSIT_REASON_PREDICATION.toUpperCase(),
            DomainOfService.TABLE_NAME);
    RangeConstraints[] configs = searchBiz.fetchRangeConstraintsListSortedByReason(
            "CONFIG",
            DomainOfService.TABLE_NAME);
    RangeConstraints[] rangeAmounts = searchBiz.fetchRangeConstraintsListSortedByReason(
            "AMOUNT",
            DomainOfService.TABLE_NAME);
    final int MAX_AGE = Integer.parseInt(configs[0].getLookupCode());
    final int ADULT_MALE_MAX_AGE = Integer.parseInt(configs[1].getLookupCode());
    final int ADULT_FEMALE_MAX_AGE = Integer.parseInt(configs[2].getLookupCode());
    searchBiz = null;
    isModify = customerInfo.getTxnType() == IConstants.MODIFY ;
    String mandatorySymb = isModify ? "" :"*";

    domainOfService = customerInfo.getDomainOfService();
    if (customerInfo.getCustomer().getDateOfBirth() != null) {
        ageLocal = DateUtil.diff(customerInfo.getCustomer().getDateOfBirth(), DateUtil.addDate(new java.util.Date(), -1))[0];
//        ageLocal = DateUtil.diff(customerInfo.getCustomer().getDateOfBirth(),DateUtil.addDate(new java.util.Date(),1) )[0];
    } else {
        ageLocal = -1;
    }
    /*Fill session if not filled yet*/
    if (domainOfService == null) {
        domainOfService = new DomainOfService();
        if (ageLocal >= 0) {
            if (!accountOpenBiz.isMinorBaseOnSpecificAge(customerInfo.getCustomer().getDateOfBirth(),new java.util.Date(),MAX_AGE)) {
                domainOfService.setMature(DomainOfService.CNS_MATURE_MATURE);
            } else {
                domainOfService.setMature(DomainOfService.CNS_MATURE_INCAPABLE);
            }
        }
    }

    if (processingStep != null && processingStep.equalsIgnoreCase(PS_SAVE_DOS)) {
        domainOfService.setMature(request.getParameter(DomainOfService.PROP_MATURE));
        domainOfService.setAccountOpenningPurpose(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE+"_MATURE")));
        domainOfService.setCustomerId(customerInfo.getCustomer().getCustomerCode());
        domainOfService.setBank(customerInfo.getBankCode());
        domainOfService.setCustomerIsn(customer.getCustIsn());
        domainOfService.setDepositPredication(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_DEPOSIT_PREDICATION)));
        domainOfService.setDepositReasonPredication(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_DEPOSIT_REASON_PREDICATION)));
        domainOfService.setExpenditureForcastMonthly(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY)) ? new Long(NumberUtil.tryToParsLong(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY).replace(",", ""), 0)) : (Long) null);
        domainOfService.setExpenditureForcastQuarterly(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY)) ? new Long(NumberUtil.tryToParsLong(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY).replace(",", ""), 0)) : (Long) null);
        domainOfService.setExpenditureForcastYearly(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY)) ? new Long(NumberUtil.tryToParsLong(request.getParameter(DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY).replace(",", ""), 0)) : (Long) null);
        if (request.getParameter(DomainOfService.PROP_MATURE).equals(DomainOfService.CNS_MATURE_MATURE))
        {
            domainOfService.setMatureKind(request.getParameter(DomainOfService.PROP_MATURE_KIND));
            domainOfService.setIncapableKind(null);

            domainOfService.setAnnualDeposit(request.getParameter(DomainOfService.PROP_ANNUAL_DEPOSIT));
            domainOfService.setAnnualWithdrawal(request.getParameter(DomainOfService.PROP_ANNUAL_WITHDRAWAL));
            domainOfService.setMaximumDeposit(request.getParameter(DomainOfService.PROP_MAXIMUM_DEPOSIT));
            domainOfService.setMaximumWithdrawal(request.getParameter(DomainOfService.PROP_MAXIMUM_WITHDRAWAL));
            domainOfService.setIntroducerName(request.getParameter(DomainOfService.PROP_INTRODUCER_NAME));
            domainOfService.setContactNo(request.getParameter(DomainOfService.PROP_CONTACTNO));
            domainOfService.setPredictionofAnualIncome(request.getParameter(DomainOfService.PROP_PREDICTIONOF_ANUAL_INCOME));
            domainOfService.setAmountOfResources(request.getParameter(DomainOfService.PROP_AMOUNT_OF_RESOURCES));
            domainOfService.setOtherSourcesofIncome(request.getParameter(DomainOfService.PROP_OTHER_SOURCES_OF_INCOME));
        }
        else
        {
            domainOfService.setMatureKind(null);
            domainOfService.setIncapableKind(request.getParameter(DomainOfService.PROP_INCAPABLE_KIND));

            domainOfService.setAccountOpenningPurpose(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE)));

            domainOfService.setNumberOfShortTermAcct(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT)) ? new Long(request.getParameter(DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT)).longValue():0);
            domainOfService.setNumberOfLongTermAcct(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT)) ? new Long(request.getParameter(DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT)).longValue():0);
            domainOfService.setNumberOfSavingCurrentAcct(!CommonUtils.IsNullOrEmpty(request.getParameter(DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT)) ? new Long(request.getParameter(DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT)).longValue():0);

            domainOfService.setMonthlyDeposit(request.getParameter(DomainOfService.PROP_MONTHLY_DEPOSIT));
            domainOfService.setMonthlyWithdrawal(request.getParameter(DomainOfService.PROP_MONTHLY_WITHDRAWAL));

            domainOfService.setQuarterlyDeposit(request.getParameter(DomainOfService.PROP_QUARTERLY_DEPOSIT));
            domainOfService.setQuarterlyWithdrawal(request.getParameter(DomainOfService.PROP_QUARTERLY_WITHDRAWAL));

            domainOfService.setAnnualDeposit(request.getParameterValues(DomainOfService.PROP_ANNUAL_DEPOSIT)[1]);
            domainOfService.setAnnualWithdrawal(request.getParameterValues(DomainOfService.PROP_ANNUAL_WITHDRAWAL)[1]);

            domainOfService.setTotalMonthlyExpenses(request.getParameter(DomainOfService.PROP_TOTAL_MONTHLY_EXPENSES));

            domainOfService.setMaximumDeposit("");
            domainOfService.setMaximumWithdrawal("");
            domainOfService.setIntroducerName("");
            domainOfService.setContactNo("");
            domainOfService.setPredictionofAnualIncome("");
            domainOfService.setAmountOfResources("");
            domainOfService.setOtherSourcesofIncome("");
        }

        domainOfService.setDepositReasonPredication(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_DEPOSIT_REASON_PREDICATION)));
        domainOfService.setDepositReasonPredicationComment(TextUtil.join(SEPRATOR, request.getParameterValues(DomainOfService.PROP_DEPOSIT_REASON_PREDICATION_COMMENT)));

        if (USER_SESSION.hasExceptions() == false ) {
            if(customerInfo.getTxnType() == IConstants.MODIFY) {
                boolean[] recordModified = customerInfo.IsRecordModified();
                recordModified[18] = true;
                customerInfo.setIsRecordModified(recordModified);
            }
            customerInfo.setCustomer(customer);
            customerInfo.setDomainOfService(domainOfService);
            USER_SESSION.getCustSess().setCreateCustomerInfo(customerInfo);
            if (changeTxnAare ==null || !changeTxnAare.equalsIgnoreCase("Y"))
                response.sendRedirect("addModMisCode.jsp");
        }
    }
    if (changeTxnAare!=null && changeTxnAare.equalsIgnoreCase("Y")){
        int recAction = IConstants.ADD;
        if(request.getParameterValues("isExistInDB")!= null && iAction == IConstants.MODIFY && txnType == IConstants.MODIFY ){
            String [] existInDb = request.getParameterValues("isExistInDB");
            recAction = ((existInDb[index]!= null && existInDb[index].equalsIgnoreCase("true"))?IConstants.MODIFY:IConstants.ADD);
        }

        TransactionAreas transactionArea = new TransactionAreas();
        transactionArea = (TransactionAreas)RequestReader.populateTxnInfo(request, transactionArea);
        txnAreas = customerInfo.getTxnAreaList();
        if (iAction == IConstants.ADD){
            if(txnType == IConstants.MODIFY  ){
                transactionArea.setActionFlag(recAction);
                boolean [] recordModified =customerInfo.IsRecordModified();
                recordModified[19] = true;
                customerInfo.setIsRecordModified(recordModified);
            }
            if (customerInfo.getCustomer() != null && customerInfo.getCustomer().getCustIsn() != 0) {
                transactionArea.setCustomerIsn(customerInfo.getCustomer().getCustIsn());
                transactionArea.setCustomerId(customerInfo.getCustomer().getCustId());
            }
            customerInfo.setTxnAreas(transactionArea);
        } else if (iAction == IConstants.MODIFY && index > -1) {
            if (txnType == IConstants.MODIFY ){
                transactionArea.setActionFlag(recAction);
                customer = customerInfo.getCustomer();
                //Added by Swati for rel ver. 7.0.9 w.r.t issue #15558 on 20-Feb-2019
                if (customer != null && customer.getCustIsn() != 0) {
                    transactionArea.setCustomerIsn(customer.getCustIsn());
                    //transactionArea.setBan(customer.getBank());
                    //addr.setBranch(USER_SESSION.getCommonSess().getBranch());
                    transactionArea.setCustomerId(customer.getCustId());
                }
                boolean existInDB = (recAction == IConstants.ADD?false :true);
                transactionArea.setExistInDB(existInDB);
                boolean [] recordModified =customerInfo.IsRecordModified();
                recordModified[19] = true;
                customerInfo.setIsRecordModified(recordModified);
            }
            customerInfo.replaceTxnAreas(transactionArea,index);
        } else if (iAction == IConstants.DELETE && index > -1) {
            if(txnType == IConstants.MODIFY  ){
                int [] deletedSrNo ;
                if(customerInfo.getTxnAreaDeletedSrNo()!=null){
                    int size = customerInfo.getTxnAreaDeletedSrNo().length;
                    deletedSrNo = new int[size + 1];
                    for(int idx = 0; idx < size ;idx++){
                        deletedSrNo[idx] = customerInfo.getTxnAreaDeletedSrNo()[idx];
                    }
                    deletedSrNo[size] = txnAreas[index].getSrlNo();
                } else {
                    deletedSrNo = new int [1];
                    deletedSrNo[0] = txnAreas[index].getSrlNo();
                }
                int[] olddeletedSrNo = customerInfo.getTxnAreaDeletedSrNo();
                if(olddeletedSrNo != null){
                    int[] combineArray = (int[]) Array.newInstance(deletedSrNo.getClass().getComponentType(), deletedSrNo.length + olddeletedSrNo.length);
                    System.arraycopy(deletedSrNo, 0, combineArray, 0, deletedSrNo.length);
                    System.arraycopy(olddeletedSrNo, 0, combineArray, deletedSrNo.length, olddeletedSrNo.length);
                    deletedSrNo = combineArray;
                }
                customerInfo.setTxnAreaDeletedSrNo(deletedSrNo);
                boolean [] recordModified =customerInfo.IsRecordModified();
                recordModified[19] = true;
                customerInfo.setIsRecordModified(recordModified);
            }
            //Modified by AmolB ver-4.0.4 , on 23-July-2013 w.r.t Bug #393
            customerInfo.removeTxnArea(index);
            if(txnType != IConstants.MODIFY){
                txnAreas = customerInfo.getTxnAreaList();
                if (txnAreas != null) {
                    int serialNo = 1;
                    for (int i=0;i<txnAreas.length;i++) {
                        txnAreas[i].setSrlNo(serialNo);
                        serialNo++;
                    }
                }
            }
        }
        processingStep = null;
    }
    txnAreas = customerInfo.getTxnAreaList();

    if (txnAreas != null)
    {
        for (int i=0;i<txnAreas.length;i++) {
            srNO = txnAreas[i].getSrlNo() + 1;
        }
        if (txnAreas.length < 1) {
            srNO = 1;
        }
    }

	if (processingStep == null ) {
 		BODY_ONLOAD = "";
	} else if (processingStep.equalsIgnoreCase("NEXT") == true) {
        USER_SESSION.getCustSess().setCreateCustomerInfo(customerInfo);
        response.sendRedirect("authorizeMisCode.jsp");
    }
%>
<%@ include file="../common/header.inc.jsp" %>

<style>
    .va {
        vertical-align: middle
    }
    .petty_table {
        margin: 0px;
        padding: 0px;
        display: inline-block;
        vertical-align: middle;
        border: 0px;
        table-layout: fixed;
        border-collapse: collapse;
    }

    .petty_table td {
        border: 0px !important;
        padding-right: 0px !important;
        margin: 0px !important;
    }

    .petty_table td input[type=checkbox] {
        margin-right: 0px !important;
        padding: 0px !important;
    }

    .w100 {
        width: 100px !important;
    }

    .w150 {
        width: 300px !important;
        margin: 0px;
        padding: 0px
    }

    .BodyTable tr td {
        padding: 0px !important;
    }

    .w150 input {
        margin: 0px !important;
    }

    .w50 {
        width: 160px !important;
    }

    .h32 {
        height: 32px
    }

    .h32 td {
        height: 32px !important;
    }
</style>
<script language="javascript" src="../common/ajax.js"></script>
<script language="javascript" src="../../jscripts/jquery.js"></script>
<table class="PageHeaderTable">
    <tr>
        <th class="PageHeaderCell"><%=PAGE_TITLE%>
        </th>
    </tr>
</table>
<%@include file="customerDetail.inc.jsp" %>




<form name="caller" method="post">
    <input type="hidden" name="isModify" value="<%=isModify%>">
    <%@include file="createCustomerTabs.inc.jsp" %>
    <%@include file="../common/displayMessages.inc.jsp" %>
    <%if (customerInfo.getCustomer().getDateOfBirth() == null)
    {%>

    <fmt:message key="please.enter.birthdate.first"/>

    <%} else {%>
    <script language="javascript">
        var age = <%=ageLocal%>;
        var bdate = '<%=sdf.format(DateUtil.convertToJalali(customerInfo.getCustomer().getDateOfBirth()))%>';
        var now = '<%=sdf.format(DateUtil.convertToJalali(new java.util.Date()))%>';
        var age_problem = '<%=TextUtil.getLocalizedMessage(new ExCode("dos.message.selected.option.not.approciate.with.age"),USER_SESSION.getLoginInfo().getLocale())%>';
        var age_sex_problem = '<%=TextUtil.getLocalizedMessage(new ExCode("dos.message.selected.option.not.approciate.with.age.sex"),USER_SESSION.getLoginInfo().getLocale())%>';
        function isMinor(birthDate,currDate,specificAge)
        {
            if (birthDate == null) {
                return false;
            }

            bshamsi = birthDate.split('-');
            var byear = parseInt(bshamsi[0],10);
            var bmonth = parseInt(bshamsi[1],10);
            var bday = parseInt(bshamsi[2],10);

            cShamsi = currDate.split('-');
            var cyear = parseInt( cShamsi[0],10);
            var cmonth = parseInt( cShamsi[1],10);
            var cday = parseInt( cShamsi[2],10);

            var yDiff = cyear - byear;
            if (yDiff == specificAge)
            {
                if (cmonth == bmonth)
                {
                    if ( cday >= bday) {
                        return false;
                    }else
                    {
                        return true;
                    }
                }
                else if (cmonth> bmonth)
                {
                    return false;
                }
                return true;

            } else if (yDiff > specificAge)
            {
                return false;
            }

            return true;
        }
        function init() {
            $("input[id^='<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_']").change(function (e) {
                checkStateOfReason();
            });

            $('input[type=radio][name="<%=DomainOfService.PROP_MATURE%>"]').change(function (e) {
                if( $(this).is(":checked") ){ // check if the radio is checked
                    checkStateOfMaturity();
                }
            });

            $('select[name="<%=DomainOfService.PROP_MATURE_KIND%>"]').change(function (e) {
                if (age!=-1)
                    switch ($(this).find("option:selected").val()) {
                        case '<%=DomainOfService.CNS_MATURE_KIND_M%>':
                            if (isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                            }
                            break;
                        case '<%=DomainOfService.CNS_MATURE_KIND_I%>':
                            if (!isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                            }
                            break;
                    }
            });
            $('select[name="<%=DomainOfService.PROP_INCAPABLE_KIND%>"]').change(function (e) {
                if (age!=-1)
                    switch ($(this).find("option:selected").val()) {
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_M%>':
                            if ('<%=sex%>' == 'F')
                            {
                                if (!isMinor(bdate, now, <%=ADULT_FEMALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                }
                            }
                            else {
                                if (!isMinor(bdate, now, <%=ADULT_MALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                }
                            }
                            break;
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_A%>':
                            if ('<%=sex%>' == 'F')
                            {
                                if (isMinor(bdate, now, <%=ADULT_FEMALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                }
                            }
                            else {
                                if (isMinor(bdate, now, <%=ADULT_MALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                }
                            }
                            if (!isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                            }
                            break;
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_N%>':
                            if (isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                            }
                            break;
                    }
            });
            checkStateOfMaturity();
            checkStateOfReason();
        }

        function checkStateOfMaturity()
        {
            var maturityState = $('input[type=radio][name="<%=DomainOfService.PROP_MATURE%>"]:checked').val();
            if (maturityState == "<%=DomainOfService.CNS_MATURE_MATURE%>" )
            {
                $('#<%=DomainOfService.PROP_MATURE_KIND%>').attr( "disabled", false );
                $('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').attr( "disabled", true );
                $("#<%=DomainOfService.PROP_INCAPABLE_KIND%>").val("");
            }
            if (maturityState == "<%=DomainOfService.CNS_MATURE_INCAPABLE%>" )
            {
                $('#<%=DomainOfService.PROP_MATURE_KIND%>').attr( "disabled", true );
                $('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').attr( "disabled", false );
                $("#<%=DomainOfService.PROP_MATURE_KIND%>").val("");
            }
        }
        function checkStateOfReason()
        {
            debugger;
            var options = $("input[type='checkbox'][id^='<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_']");
            <%--var options = Array.from(document.querySelectorAll('[id^=<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_]'));--%>
            for (var index = 0; index < options.length; index++) {
                var id = $(options[index]).attr('id');
                var id_index = id.lastIndexOf("_") + 1;
                var item_index = id.substring(id_index);
                $('#<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment' + item_index).attr('disabled',!$(options[index]).is(':checked'));
                if ($(options[index]).is(':checked'))
                {
                    var label = $("label[for='" + id + "']");
                    $('#<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment' + item_index)[0].mandatory="yes";
                    $('#<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment' + item_index)[0].display="<%=TextUtil.getLocalizedLabel("comment")%> " + $(label).text().trim();
                } else {
                    $('#<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment' + item_index)[0].mandatory = "no";
                    $('#<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment' + item_index).val("");
                }

            }
        }

        function validation(frm) {
            debugger;
            var maturityState = $('input[type=radio][name="<%=DomainOfService.PROP_MATURE%>"]:checked').val();
            if (!maturityState) {
                alert('cannot be null <%=TextUtil.getLocalizedLabel("dos.adult.kind",USER_SESSION.getLoginInfo().getLocale())%>/<%=TextUtil.getLocalizedLabel("dos.incapable.kind",USER_SESSION.getLoginInfo().getLocale())%>')
                return false;
            }

            if (maturityState == "<%=DomainOfService.CNS_MATURE_MATURE%>") {
                if ($('#<%=DomainOfService.PROP_MATURE_KIND%>').val() == "") {
                    alert('cannot be null <%=TextUtil.getLocalizedLabel("dos.adult.kind",USER_SESSION.getLoginInfo().getLocale())%>');
                    $('#<%=DomainOfService.PROP_MATURE_KIND%>').focus();
                    return false;
                }
                if (age != -1)
                    switch ($('#<%=DomainOfService.PROP_MATURE_KIND%>').val()) {
                        case '<%=DomainOfService.CNS_MATURE_KIND_M%>':
                            if (isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                                return false;
                            }
                            break;
                        case '<%=DomainOfService.CNS_MATURE_KIND_I%>':
                            if (!isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                                return false;
                            }
                            break;
                    }

                //Check expenditure
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.mandatory="no";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.data=null;
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.mandatory="no";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.data=null;
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.mandatory="no";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.data=null;
            }
            if (maturityState == "<%=DomainOfService.CNS_MATURE_INCAPABLE%>" )
            {
                if ($('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').val() == "")
                {
                    alert('cannot be null <%=TextUtil.getLocalizedLabel("dos.incapable.kind",USER_SESSION.getLoginInfo().getLocale())%>');
                    $('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').focus();
                    return false;
                }

                if (age!=-1)
                    switch ($('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').val()) {
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_M%>':
                            if ('<%=sex%>' == 'F')
                            {
                                if (!isMinor(bdate, now, <%=ADULT_FEMALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                    return false;
                                }
                            }
                            else {
                                if (!isMinor(bdate, now, <%=ADULT_MALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                    return false;
                                }
                            }
                            break;
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_A%>':
                            if ('<%=sex%>' == 'F')
                            {
                                if (isMinor(bdate, now, <%=ADULT_FEMALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                    return false;
                                }
                            }
                            else {
                                if (isMinor(bdate, now, <%=ADULT_MALE_MAX_AGE%>)) {
                                    alert(age_sex_problem);
                                    return false;
                                }
                            }
                            if (!isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                                return false;
                            }
                            break;
                        case '<%=DomainOfService.CNS_INCAPABLE_KIND_N%>':
                            if (isMinor(bdate, now, <%=MAX_AGE%>)) {
                                alert(age_problem);
                                return false;
                            }
                            break;
                    }


                //Check expenditure
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.mandatory="yes";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.display="<%=TextUtil.getLocalizedLabel("dos.total.expenditure.forecast") + " " + TextUtil.getLocalizedLabel("dos.tef.monthly")%>";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.data="num";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.allowzero=true;
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.negativeallowed="false";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.mandatory="yes";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.display="<%=TextUtil.getLocalizedLabel("dos.total.expenditure.forecast") + " " +TextUtil.getLocalizedLabel("dos.tef.quarterly")%>";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.data="num";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.allowzero=true;
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.negativeallowed="false";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.mandatory="yes";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.display="<%=TextUtil.getLocalizedLabel("dos.total.expenditure.forecast") + " " +TextUtil.getLocalizedLabel("dos.tef.yearly")%>";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.data="num";
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.allowzero=true;
                //frm.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.negativeallowed="false";

            }

            if (frm.isModify.value == 'false' && !validateCheckbox()){
                return false;
            }
            if (!validateComboBox()){
                return false;
            }
            if (!validateInputText()){
                return false;
            }
            if (isMature()){
                if (frm.isModify.value == 'false' && (document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value == null || document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value.trim().length == 0)){
                    document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.focus();
                    alert('<fmt:message key="other.sources.of.income"/>'+'  '+'<fmt:message key="can.not.be.null"/>');
                    return false;
                }

                if (document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value != null && document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value.trim().length > 0){
                    var chars = "{}=`/~'\\!#@&$%^*()_+|:><?,;'[]\"";
                    var field = frm.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value;
                    for (var i= 0; i < field.length; i++) {
                        if (chars.indexOf(field.charAt(i)) >= 0) {
                            alert("<%=TextUtil.getLocalizedMessage("special.chars.are.not.allowed.in.other.sources.of.income")%>");
                            frm.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.focus();
                            return false ;
                        }
                    }
                }

            }
            frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.mandatory = "no";
            frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.mandatory = "no";
            frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.mandatory = "no";
            frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.mandatory = "no";

            // .mandatory="no";
            // .data = "alphaNum";
            frm.<%=DomainOfService.PROP_MATURE%>.mandatory="yes";
            frm.<%=DomainOfService.PROP_MATURE%>.message="<fmt:message key="dos.adult.kind"/>";

            if (frm.<%=DomainOfService.PROP_MATURE%>.value == '<%=DomainOfService.CNS_MATURE_MATURE%>' && (document.caller.totalRec == undefined || document.caller.totalRec.value == 0)){
                alert('<fmt:message key="expected.geographical.areaof.frequent.transactions.msg"/>'+'\n'+'<fmt:message key="please.press.add.btn"/>');
                document.caller.btnAdd.focus();
                return false;
            }

            if (validate(frm) == true) {
                frm.processingStep.value = "<%=PS_SAVE_DOS%>";
                frm.btnSubmit.disabled = true;
                frm.submit();
            } else {
                frm.btnSubmit.disabled = false;
                return false;
            }

        }
        function goToNextURL(frm) {

            if(confirm("<%=TextUtil.getLocalizedMessage(ExCode.CustEx.CONTINUE_WITHOUT_SAVE)%>")) {
                javascript:location.replace('addModMisCode.jsp');
            } else {
                return false;
            }
        }
        function buttonAction(frm){
            frm.processingStep.value = "NEXT";
            frm.btnNext.disabled = true;
            frm.submit();
        }

        function isMature() {
            flag = false;
            var radioBtns = document.caller.mature;
            for (var i = 0; i < radioBtns.length; i++) {
                if (radioBtns[i].checked && radioBtns[i].value == '<%=DomainOfService.CNS_MATURE_MATURE%>') {
                    flag = true;
                }
            }
            return flag;
        }

        function check() {
            var flag = isMature();
            if (!flag) {
                document.getElementById("dos_purpose_account_opening").style.display = '';
                document.getElementById("numberof_accounts_with_other_credit_institutions").style.display = '';
                document.getElementById("predictionof_total_deposit_withdrawal_amounts").style.display = '';
                document.getElementById("quarterly_deposit_withdrawal").style.display = '';
                document.getElementById("annual_deposit_withdrawal").style.display = '';
                document.getElementById("dostotal_expenditure_forecast").style.display = '';
                document.getElementById("dos_predictionof_deposit_types").style.display = '';
                document.getElementById("dospredicting_reason_deposit").style.display = '';


                var elements = document.getElementsByName("dospredicting_reason_deposit_checkbox");
                for (var j = 0; j < elements.length; j++) {
                    elements[j].style.display = '';
                }
                document.getElementById("dos_purpose_account_opening_mature").style.display = 'none';
                document.getElementById("forecastof_the_annual_amount").style.display = 'none';
                document.getElementById("predictionofthe_maximum_amountof_each_transaction").style.display = 'none';
                document.getElementById("mature_introducer_information").style.display = 'none';
                document.getElementById("predictionof_anual_income").style.display = 'none';
                document.getElementById("other_sourcesof_income").style.display = 'none';
                document.getElementById("amountof_resources").style.display = 'none';

                var acctPurpose = document.getElementsByName('<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_MATURE');
                for(var k =0 ; k<acctPurpose.length;k++){
                    acctPurpose[k].checked = false;
                }

                var annualDeposit = document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>')[0];
                annualDeposit.value= '';

                var annualWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>')[0];
                annualWithdrawal.value = '';

                var maximumDeposit = document.getElementsByName('<%=DomainOfService.PROP_MAXIMUM_DEPOSIT%>')[0];
                maximumDeposit.value = '';

                var maximumWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_MAXIMUM_WITHDRAWAL%>')[0];
                maximumWithdrawal.value = '';

                var anualIncome = document.getElementsByName('<%=DomainOfService.PROP_PREDICTIONOF_ANUAL_INCOME%>')[0];
                anualIncome.value = '';

                var amountOfResources = document.getElementsByName('<%=DomainOfService.PROP_AMOUNT_OF_RESOURCES%>')[0];
                amountOfResources.value = '';

                document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>.value = '';
                document.caller.<%=DomainOfService.PROP_CONTACTNO%>.value = '';
                document.caller.<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>.value = '';

                document.getElementById("txnAreaTbl").style.display = 'none';
                document.getElementById("resultTbl").style.display = 'none';
            }
            if (flag) {
                document.getElementById("dos_purpose_account_opening").style.display = 'none';
                document.getElementById("numberof_accounts_with_other_credit_institutions").style.display = 'none';
                document.getElementById("predictionof_total_deposit_withdrawal_amounts").style.display = 'none';
                document.getElementById("quarterly_deposit_withdrawal").style.display = 'none';
                document.getElementById("annual_deposit_withdrawal").style.display = 'none';
                document.getElementById("dostotal_expenditure_forecast").style.display = 'none';
                document.getElementById("dos_predictionof_deposit_types").style.display = 'none';
                document.getElementById("dospredicting_reason_deposit").style.display = 'none';
                var elements = document.getElementsByName("dospredicting_reason_deposit_checkbox");
                for (var j = 0; j < elements.length; j++) {
                    elements[j].style.display = 'none';
                }


                document.getElementById("dos_purpose_account_opening_mature").style.display = '';
                document.getElementById("forecastof_the_annual_amount").style.display = '';
                document.getElementById("predictionofthe_maximum_amountof_each_transaction").style.display = '';
                document.getElementById("mature_introducer_information").style.display = '';
                document.getElementById("predictionof_anual_income").style.display = '';
                document.getElementById("other_sourcesof_income").style.display = '';
                document.getElementById("amountof_resources").style.display = '';
                document.getElementById("txnAreaTbl").style.display = '';
                document.getElementById("resultTbl").style.display = '';

                var acctPurposeI = document.getElementsByName('<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>');
                for(var m =0 ; m<acctPurposeI.length;m++){
                    acctPurposeI[m].checked = false;
                }
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>.value = '';
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>.value = '';
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>.value = '';

                var monthlyDeposit = document.getElementsByName('<%=DomainOfService.PROP_MONTHLY_DEPOSIT%>')[0];
                monthlyDeposit.value = '';

                var monthlyWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_MONTHLY_WITHDRAWAL%>')[0];
                monthlyWithdrawal.value = '';

                var quarterlyDeposit = document.getElementsByName('<%=DomainOfService.PROP_QUARTERLY_DEPOSIT%>')[0];
                quarterlyDeposit.value = '';

                var quarterlyWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_QUARTERLY_WITHDRAWAL%>')[0];
                quarterlyWithdrawal.value = '';

                var annualDeposit =document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>')[1];
                annualDeposit.value = '';

                var annualWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>')[1];
                annualWithdrawal.value = '';

                var monthlyExpenses = document.getElementsByName('<%=DomainOfService.PROP_TOTAL_MONTHLY_EXPENSES%>')[0];
                monthlyExpenses.value = '';
            }
        }

        function validateCheckbox() {
            var checkBoxName = isMature() ? '<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_MATURE' : '<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>';
            var acctPurpose = document.getElementsByName(checkBoxName);
            var nbChecked = 0;
            var isChecked = true;
            for (var i = 0; i < acctPurpose.length; i++) {
                if (acctPurpose[i].checked) {
                    nbChecked++;
                }
            }
            if (nbChecked == 0) {
                isChecked = false;
                if (isMature()){
                    alert('<%=TextUtil.getLocalizedMessage(
                        new ExCode("dos.message.please.select.atleast.on.option",new String[]{TextUtil.getLocalizedLabel( "dos.purpose.account.opening.mature")}),USER_SESSION.getLoginInfo().getLocale())%>');
                }else{
                    alert('<%=TextUtil.getLocalizedMessage(
                        new ExCode("dos.message.please.select.atleast.on.option",new String[]{TextUtil.getLocalizedLabel( "dos.purpose.account.opening")}),USER_SESSION.getLoginInfo().getLocale())%>');
                }
            }
            if (isChecked == true && !isMature() == true){
                var depositPrediction = document.getElementsByName('<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>');
                var checkedCount = 0;
                for (var j=0; j<depositPrediction.length ; j++){
                    if (depositPrediction[j].checked){
                        checkedCount++;
                    }
                }
                if (checkedCount == 0){
                    isChecked = false;
                    alert('<%=TextUtil.getLocalizedLabel( "please.select.atleast.one.option.from.the.deposit.method.prediction",USER_SESSION.getLoginInfo().getLocale())%>');
                }
            }
            if (isChecked == true && !isMature() == true){
                var depositReasonPrediction = document.getElementsByName('<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>');
                var checkedCount = 0;
                for (var j=0; j<depositReasonPrediction.length ; j++){
                    if (depositReasonPrediction[j].checked){
                        checkedCount++;
                    }
                }
                if (checkedCount == 0){
                    isChecked = false;
                    alert('<%=TextUtil.getLocalizedLabel( "please.select.atleast.one.option.from.the.deposit.reason.prediction",USER_SESSION.getLoginInfo().getLocale())%>');
                }
            }
            return isChecked;
        }
        function validateComboBox(){
            if (isMature()){
                var annualDeposit =document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>')[0].value;
                if (annualDeposit == ''){
                    alert('<fmt:message key="please.select.one.option.of.annual.deposit"/>');
                    return false;
                }
                var annualWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>')[0].value;
                if (annualWithdrawal == ''){
                    alert('<fmt:message key="please.select.an.option.of.annual.withdrawal"/>');
                    return false;
                }
                var maximumDeposit = document.getElementsByName('<%=DomainOfService.PROP_MAXIMUM_DEPOSIT%>')[0].value;
                if (maximumDeposit == ''){
                    alert('<fmt:message key="please.select.an.option.for.the.maximum.deposit.amount"/>');
                    return false;
                }
                var maximumWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_MAXIMUM_WITHDRAWAL%>')[0].value;
                if (maximumWithdrawal == ''){
                    alert('<fmt:message key="please.select.an.option.for.the.maximum.withdrawal.amount"/>');
                    return false;
                }

                var anualIncome = document.getElementsByName('<%=DomainOfService.PROP_PREDICTIONOF_ANUAL_INCOME%>')[0].value;
                if (anualIncome == ''){
                    alert('<fmt:message key="please.select.an.option.to.predict.the.amount.of.annual.income"/>');
                    return false;
                }
                var amountOfResources = document.getElementsByName('<%=DomainOfService.PROP_AMOUNT_OF_RESOURCES%>')[0].value;
                if (amountOfResources == ''){
                    alert('<fmt:message key="please.select.an.option.for.the.amount.of.property.resources"/>');
                    return false;
                }
            }else{
                var monthlyDeposit = document.getElementsByName('<%=DomainOfService.PROP_MONTHLY_DEPOSIT%>')[0].value
                if (monthlyDeposit == ''){
                    alert('<fmt:message key="please.select.amonthly.deposit.option"/>');
                    return false;
                }

                var monthlyWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_MONTHLY_WITHDRAWAL%>')[0].value
                if (monthlyWithdrawal == ''){
                    alert('<fmt:message key="please.select.amonthly.withdrawal.option"/>');
                    return false;
                }

                var quarterlyDeposit = document.getElementsByName('<%=DomainOfService.PROP_QUARTERLY_DEPOSIT%>')[0].value
                if (quarterlyDeposit == ''){
                    alert('<fmt:message key="please.choose.an.option.ofquarterly.deposit"/>');
                    return false;
                }

                var quarterlyWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_QUARTERLY_WITHDRAWAL%>')[0].value
                if (quarterlyWithdrawal == ''){
                    alert('<fmt:message key="please.select.aquarterly.withdrawal.option"/>');
                    return false;
                }

                var annualDeposit =document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>')[1].value;
                if (annualDeposit == ''){
                    alert('<fmt:message key="please.select.one.option.of.annual.deposit"/>');
                    return false;
                }
                var annualWithdrawal = document.getElementsByName('<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>')[1].value;
                if (annualWithdrawal == ''){
                    alert('<fmt:message key="please.select.an.option.of.annual.withdrawal"/>');
                    return false;
                }

                var monthlyExpenses = document.getElementsByName('<%=DomainOfService.PROP_TOTAL_MONTHLY_EXPENSES%>')[0].value;
                if (monthlyExpenses == ''){
                    alert('<fmt:message key="please.select.an.option.for.total.monthly.expenses"/>');
                    return false;
                }
            }
            return true;
        }
        function validateInputText(){
            if (isMature()){
                document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>.mandatory = "no";
                document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>.checkSpecialChar = "yes";
                document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>.display = '<fmt:message key="introducer.name"/>';
                if (checkLength(document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>,600) == false)
                    return false;

                document.caller.<%=DomainOfService.PROP_CONTACTNO%>.mandatory = "no";
                document.caller.<%=DomainOfService.PROP_CONTACTNO%>.data = "num";
                document.caller.<%=DomainOfService.PROP_CONTACTNO%>.display = ' <fmt:message key="contact.no"/> ';
                if (checkLength(document.caller.<%=DomainOfService.PROP_CONTACTNO%>,45) == false)
                    return false;

                return true;

            }else{
                document.caller.<%=DomainOfService.PROP_INTRODUCER_NAME%>.mandatory = "no";
                document.caller.<%=DomainOfService.PROP_CONTACTNO%>.mandatory = "no";

                if (document.caller.isModify.value == 'false'){
                    document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>.mandatory = "yes";
                    document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>.mandatory = "yes";
                    document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>.mandatory = "yes";
                }

                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>.data = "num";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>.negativeallowed = "false";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>.display = ' <fmt:message key="short.term.account"/> ';
                if (checkLength(document.caller.<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>,2) == false)
                    return false;


                document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>.data = "num";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>.negativeallowed = "false";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>.display = ' <fmt:message key="long.term.account"/> ';
                if (checkLength(document.caller.<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>,2) == false)
                    return false;


                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>.data = "num";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>.negativeallowed = "false";
                document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>.display = ' <fmt:message key="saving.current.account"/> ';
                if (checkLength(document.caller.<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>,2) == false)
                    return false;

                return true;
            }
        }
        function countryCallBack(id)
        {
            if (arguments[0] == 1)
            {
                document.caller.<%=PassportDetails.PROP_BORN_COUNTRY%>.value = arguments[2][0];
                document.caller.<%=PassportDetails.PROP_BORN_COUNTRY%>Desc.value = arguments[2][1];
            }
            else if (arguments[0] == 2){
                document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.value = arguments[2][0];
                document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>Desc.value = arguments[2][1];
            }else{
                document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.value = arguments[2][0];
                document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>Desc.value = arguments[2][1];
            }
        }

        function removeAddress(frm)
        {
            if(confirm("<%=TextUtil.getLocalizedMessage(ExCode.CustEx.DEL_CURR_VALUES)%>"))
            {
                frm.processingStep.value = "<%=PS_SAVE_DOS%>";
                frm.changeTxnArea.value = "Y";
                frm.Action.value = "<%=IConstants.DELETE%>";
                return true;
            }
            else
            {
                return false;
            }
        }

        function saveTxnArea(frm,varAction)
        {
            frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.display='<fmt:message key= "source.country" />';
            frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.mandatory = "yes";

            frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.display='<fmt:message key= "source.city" />';
            frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.mandatory = "yes";

            <%-- Changes done by Vinayak on 05.Sep.2013 w.r.t. Issue# 1153 for the release 4.0.10  --%>
            frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.display='<fmt:message key= "destination.country" />';
            frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.mandatory = "yes";

            frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.display='<fmt:message key= "destination.city" />';
            frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.mandatory = "yes";


            if (checkSpecialChars(frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>) == false){
                return false;
            }

            if (checkSpecialChars(frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>) == false){
                return false;
            }

            if (checkLength(document.caller.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>,50) == false)
                return false;

            if (checkLength(document.caller.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>,50) == false)
                return false;


            if(validate(frm))
            {

                frm.changeTxnArea.value = 'Y';
                frm.processingStep.value = "<%=PS_SAVE_DOS%>";
                frm.Action.value = varAction;

                frm.btnAdd.disabled = true;
                frm.submit();
                return true;
            }
            else{
                return false;
            }
        }

        function checkLength(elem,size){
            if (elem == null || elem == undefined || elem.disabled == true){
                return true;
            }
            if (elem.value.trim().length > size){

                var message = " <fmt:message key='msg.length.should.be.less.than.or.equal'>"
                    + "<fmt:param>" + size + "</fmt:param>"
                    + "</fmt:message>";

                alert(elem.display + message) ;
                elem.focus();
                return false;
            }
            else{
                return true;
            }
        }

        function transferAddressDetails(frm,radioNo)
        {
            if(frm.totalRec.value==1)
            {
                if(frm.txnAreaSrlNo.value == null){
                    frm.<%=TransactionAreas.PROP_SRL_NO%>.value=frm.txnAreaSrlNo[radioNo-1].value;
                    frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.value=frm.existSourceCountryCode[radioNo-1].value;
                    frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.value=frm.existSourceStateCode[radioNo-1].value;
                    frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.value=frm.existDestinationCountryCode[radioNo-1].value;
                    frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.value=frm.existDestinationStateCode[radioNo-1].value;
                }
                else
                {
                    frm.<%=TransactionAreas.PROP_SRL_NO%>.value=frm.txnAreaSrlNo.value;
                    frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.value=frm.existSourceCountryCode.value;
                    frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.value=frm.existSourceStateCode.value;
                    frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.value=frm.existDestinationCountryCode.value;
                    frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.value=frm.existDestinationStateCode.value;
                }
            }
            else
            {
                frm.<%=TransactionAreas.PROP_SRL_NO%>.value=frm.txnAreaSrlNo[radioNo-1].value;
                frm.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.value=frm.existSourceCountryCode[radioNo-1].value;
                frm.<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.value=frm.existSourceStateCode[radioNo-1].value;
                frm.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.value=frm.existDestinationCountryCode[radioNo-1].value;
                frm.<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.value=frm.existDestinationStateCode[radioNo-1].value;
            }
            frm.index.value = radioNo-1;
        }
        function enableDisableButtons(frm)
        {
            frm.btnModify.disabled = false;
            if(frm.count.value == 1) {
                frm.btnDelete.disabled = true;
            } else {
                frm.btnDelete.disabled = false;
            }
            frm.btnAdd.disabled = true;
        }
        function enableDisableButtonsForReset(frm)
        {
            frm.btnModify.disabled = true;
            frm.btnDelete.disabled = true;
            frm.btnAdd.disabled = false;
        }

        function checkSpecialChars(elem){
            var chars = "0123456789{}=`./~'\\!#$%^*()_-+|:><?,;'[]\"";
            var field = elem.value;
            for (var i= 0; i < field.length; i++) {
                if (chars.indexOf(field.charAt(i)) >= 0) {
                    alert("<%=TextUtil.getLocalizedMessage("numeric.special.chars.are.not.allowed")%>");
                    elem.focus();
                    return false ;
                }
            }
            return true;
        }
    </script>
    <% if (processingStep == null) { %>
    <table class="BodyTable" id="domainOfServiceTbl">
        <input type="hidden" name="Action" value="<%=IConstants.ADD%>">
        <input type="hidden" name="SrNo" value="<%=srNO+1%>">
        <input type="hidden" name="index" value="-1">
        <input type="hidden" name="addressCount" value ="1">
        <tr class="BodyTableRow">
            <td class="FieldLabel">
                <input id="<%=DomainOfService.PROP_MATURE%>1" type="radio" name="<%=DomainOfService.PROP_MATURE%>"
                       value="<%=DomainOfService.CNS_MATURE_MATURE%>"
                       onchange="check()"
                    <%=domainOfService.getMature()!=null && domainOfService.getMature().equals(DomainOfService.CNS_MATURE_MATURE)?"checked='checked'":"" %>
                       class="FieldText" tabindex="<%=tabIdx++%>" style="vertical-align: middle">
                <label for="<%=DomainOfService.PROP_MATURE%>1" style="vertical-align: middle">
                    <fmt:message key='dos.adult'/>
                </label>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_MATURE_KIND%>" id="<%=DomainOfService.PROP_MATURE_KIND%>"
                        class="FieldText" disabled="disabled">
                    <option value=""><fmt:message key="not.selected"/></option>
                    <%
                        for (int i = 0; i < matureKinds.length; i++) {
                    %>
                    <option value="<%=matureKinds[i].getShortDesc()%>" <%=(domainOfService.getMatureKind() != null && matureKinds[i].getShortDesc().equals(domainOfService.getMatureKind())) ? "selected='selected'" : ""%>>
                        <%=TextUtil.getLocalizedLabel(matureKinds[i].getLongDesc(), USER_SESSION.getCommonSess().getLocale())%>
                    </option>
                    <%
                        }
                    %>
                </select>
            </td>
            <td colspan="5"></td>
        </tr>
        <tr class="BodyTableRow">
            <td class="FieldLabel">
                <input id="<%=DomainOfService.PROP_MATURE%>2" type="radio" name="<%=DomainOfService.PROP_MATURE%>"
                       value="<%=DomainOfService.CNS_MATURE_INCAPABLE%>" maxlength="10" size='11'
                       onchange="check()"
                    <%=domainOfService.getMature()!=null && domainOfService.getMature().equals(DomainOfService.CNS_MATURE_INCAPABLE)?"checked='checked'":"" %>
                       class="FieldText" tabindex="<%=tabIdx++%>" style="vertical-align: middle">
                <label for="<%=DomainOfService.PROP_MATURE%>2" style="vertical-align: middle">
                    <fmt:message key='dos.incapable'/>
                </label>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_INCAPABLE_KIND%>" id="<%=DomainOfService.PROP_INCAPABLE_KIND%>"
                        class="FieldText" disabled="disabled">
                    <option value=""><fmt:message key="not.selected"/></option>
                    <%
                        for (int i = 0; i < incapableKinds.length; i++) {
                    %>
                    <option value="<%=incapableKinds[i].getShortDesc()%>" <%=(domainOfService.getIncapableKind() != null && incapableKinds[i].getShortDesc().equals((domainOfService.getIncapableKind()))) ? "selected='selected'" : ""%>>
                        <%=TextUtil.getLocalizedLabel(incapableKinds[i].getLongDesc(), USER_SESSION.getCommonSess().getLocale())%>
                    </option>
                    <%
                        }
                    %>
                </select>
            </td>
            <td colspan="5"></td>
        </tr>

        <tr class="BodyTableRow" id="dos_purpose_account_opening">
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='dos.purpose.account.opening'/></td>

            <%for (int i = 0; i < accountOpeningPurpose.length; i++) {%>
            <td>
                <input name="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>"
                       id="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_<%=accountOpeningPurpose[i].getShortDesc()%>item<%=i+1%>"
                       type="checkbox" value="<%=accountOpeningPurpose[i].getShortDesc()%>"
                       class="va FieldText"
                    <%=domainOfService.getAccountOpenningPurpose()!= null && domainOfService.getAccountOpenningPurpose().contains(accountOpeningPurpose[i].getShortDesc())?"checked='checked'":""%>>
                <label for="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_<%=accountOpeningPurpose[i].getShortDesc()%>item<%=i+1%>"
                       class="va">
                    <%=TextUtil.getLocalizedLabel(accountOpeningPurpose[i].getLongDesc(), USER_SESSION.getCommonSess().getLocale())%>
                </label>
            </td>
            <%}%>
            <td colspan="2"></td>
        </tr>

        <tr class="BodyTableRow" id="dos_purpose_account_opening_mature">
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='dos.purpose.account.opening.mature'/></td>
            <%for (int i = 0; i < accountOpeningPurposeMature.length; i++) {%>
            <td>
                <input name="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_MATURE"
                       id="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_<%=accountOpeningPurposeMature[i].getShortDesc()%>item<%=i+1%>"
                       type="checkbox" value="<%=accountOpeningPurposeMature[i].getShortDesc()%>"
                       class="va FieldText"
                    <%=domainOfService.getAccountOpenningPurpose()!= null && domainOfService.getAccountOpenningPurpose().contains(accountOpeningPurposeMature[i].getShortDesc())?"checked='checked'":""%>>
                <label for="<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_<%=accountOpeningPurposeMature[i].getShortDesc()%>item<%=i+1%>"
                       class="va">
                    <%=TextUtil.getLocalizedLabel(accountOpeningPurposeMature[i].getLongDesc(), USER_SESSION.getCommonSess().getLocale())%>
                </label>
            </td>
            <%}%>
        </tr>

        <tr class="BodyTableRow" id="forecastof_the_annual_amount">
            <td class="FieldLabel"><sup class='LegendText'>*</sup><fmt:message key="forecastof.the.annual.amount"/></td>
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='annual.deposit'/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getAnnualDeposit()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key="annual.withdrawal"/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getAnnualWithdrawal()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="2"></td>
        </tr>
        <tr class="BodyTableRow" id="predictionofthe_maximum_amountof_each_transaction">
            <td class="FieldLabel"><sup class='LegendText'>*</sup><fmt:message key="predictionof.the.maximum.amountof.each.transaction"/></td>
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='maximum.deposit'/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_MAXIMUM_DEPOSIT%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getMaximumDeposit()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key="maximum.withdraw"/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_MAXIMUM_WITHDRAWAL%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getMaximumWithdrawal()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="2"></td>
        </tr>

        <tr class="BodyTableRow" id="mature_introducer_information">
            <td class="FieldLabel"><fmt:message key="mature.introducer.information"/></td>
            <td class="FieldLabel"><fmt:message key='short.name'/></td>
            <td colspan="2">
                <input type="text" class="FieldText" name="<%=DomainOfService.PROP_INTRODUCER_NAME%>"
                       value="<%=domainOfService.getIntroducerName()!= null ?String.valueOf(domainOfService.getIntroducerName()):""%>" maxlength="600" size="50">
            </td>
            <td class="FieldLabel"><fmt:message key="contact.no"/></td>
            <td colspan="2">
                <input type="text" class="FieldText" name="<%=DomainOfService.PROP_CONTACTNO%>"
                       value="<%=domainOfService.getContactNo()!= null ?String.valueOf(domainOfService.getContactNo()):""%>" maxlength="45">
            </td>
        </tr>

        <tr class="BodyTableRow" id="predictionof_anual_income">
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='predictionof.anual.income'/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_PREDICTIONOF_ANUAL_INCOME%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getPredictionofAnualIncome()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="5"></td>
        </tr>
        <tr id="amountof_resources">
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='amountof.resources'/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_AMOUNT_OF_RESOURCES%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getAmountOfResources()    ))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="5"></td>
        </tr>
        <tr><td colspan="7"></td></tr>
        <tr id="other_sourcesof_income" >
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='other.sources.of.income'/></td>
            <td colspan="2">
                <textarea cols="40" name="<%=DomainOfService.PROP_OTHER_SOURCES_OF_INCOME%>" tabindex="<%=tabIdx++%>" maxlength="150"><%= domainOfService.getOtherSourcesofIncome()!= null ?domainOfService.getOtherSourcesofIncome():""%></textarea>
            </td>
            <td colspan="4"></td>
        </tr>

        <tr class="BodyTableRow" id="numberof_accounts_with_other_credit_institutions">
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='number.of.accounts.with.other.credit.institutions'/>&nbsp;</td>
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='short.term.account'/></td>
            <td>
                <input type="text" class="FieldText" name="<%=DomainOfService.PROP_NUMBER_OF_SHORT_TERM_ACCT%>" maxlength="2"
                       value="<%=String.valueOf(domainOfService.getNumberOfShortTermAcct())%>">
            </td>
            <td class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='long.term.account'/></td>
            <td>
                <input type="text" class="FieldText" name="<%=DomainOfService.PROP_NUMBER_OF_LONG_TERM_ACCT%>" maxlength="2"
                       value="<%=String.valueOf(domainOfService.getNumberOfLongTermAcct())%>">
            </td>
            <td class="FieldLabel" width="14%"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='saving.current.account'/></td>
            <td>
                <input type="text" class="FieldText" name="<%=DomainOfService.PROP_NUMBER_OF_SAVING_CURRENT_ACCT%>" maxlength="2"
                       value="<%=String.valueOf(domainOfService.getNumberOfSavingCurrentAcct())%>">
            </td>
        </tr>
        <tr>
            <td colspan="7"></td>
        </tr>
        <tr class="BodyTableRow" id="predictionof_total_deposit_withdrawal_amounts">
            <td  class="FieldLabel"><sup class='LegendText'>*</sup><fmt:message key='prediction.of.total.deposit.withdrawal.amounts'/>&nbsp;</td>
            <td  class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='monthly.deposit'/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_MONTHLY_DEPOSIT%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getMonthlyDeposit()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key="monthly.withdrawal"/></span>
            </td>
            <td >
                <select name="<%=DomainOfService.PROP_MONTHLY_WITHDRAWAL%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getMonthlyWithdrawal()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="2"></td>
        </tr>

        <tr class="BodyTableRow" id="quarterly_deposit_withdrawal">
            <td >&nbsp;</td>
            <td  width="14%" class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='quarterly.deposit'/></span>
            </td>
            <td  width="14%">
                <select name="<%=DomainOfService.PROP_QUARTERLY_DEPOSIT%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getQuarterlyDeposit()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td  width="14%" class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key="quarterly.withdrawal"/></span>
            </td>
            <td  width="14%">
                <select name="<%=DomainOfService.PROP_QUARTERLY_WITHDRAWAL%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getQuarterlyWithdrawal()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td  width="14%"></td>
            <td  width="14%"></td>
        </tr>

        <tr class="BodyTableRow" id="annual_deposit_withdrawal">
            <td  width="14%">&nbsp;</td>
            <td  width="14%" class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key='annual.deposit'/></span>
            </td>
            <td  width="14%">
                <select name="<%=DomainOfService.PROP_ANNUAL_DEPOSIT%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getAnnualDeposit()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td  width="14%" class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>"><fmt:message key="annual.withdrawal"/></span>
            </td>
            <td>
                <select name="<%=DomainOfService.PROP_ANNUAL_WITHDRAWAL%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=(rangeAmounts[i].getShortDesc().equals(domainOfService.getAnnualWithdrawal()))?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td  width="14%"></td>
            <td  width="14%"></td>
        </tr>

        <tr>
            <td colspan="7"></td>
        </tr>
        <tr id="dostotal_expenditure_forecast">
            <td  width="14%" class="FieldLabel"><sup class='LegendText'>*</sup>
                <span dir="<%=direction%>">
                    <fmt:message key='dos.total.expenditure.forecast'/>&nbsp;<fmt:message key="dos.tef.monthly"/>&nbsp;(<fmt:message key="rial"/>)
                </span>
            </td>
            <td  width="14%">
                <select name="<%=DomainOfService.PROP_TOTAL_MONTHLY_EXPENSES%>"  onchange="">
                    <option value=""><fmt:message key="not.selected" /> </option>
                    <%
                        if (rangeAmounts.length > 0) {
                            for (int i = 0; i < rangeAmounts.length; i++) {
                    %>
                    <option value="<%=rangeAmounts[i].getShortDesc()%>" <%=rangeAmounts[i].getShortDesc().equals(domainOfService.getTotalMonthlyExpenses())?"selected='selected'":""%>>
                        <%=TextUtil.getLocalizedLabel(rangeAmounts[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
                    </option>
                    <%
                            }
                        }
                    %>
                </select>
            </td>
            <td colspan="5"></td>
        </tr>
        <tr class="BodyTableRow" id="dos_predictionof_deposit_types">
            <td  width="14%" class="FieldLabel"><sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='dos.prediction.of.deposit.types'/></td>
            <td  width="14%">
                <input type="checkbox" name="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>"
                       id="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_C%>"
                       value="<%=DomainOfService.CNS_DEPOSIT_PREDICTION_C%>"
                    <%=domainOfService.getDepositPredication()!= null && domainOfService.getDepositPredication().contains(DomainOfService.CNS_DEPOSIT_PREDICTION_C)?"checked='checked'":""%>
                       class="va FieldCheckBox">
                <label for="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_C%>"
                       class="va">
                    <fmt:message key="dos.pdt.cash"/>
                </label>
            </td>
            <td  width="14%">
                <input type="checkbox" name="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>"
                       id="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_E%>"
                       value="<%=DomainOfService.CNS_DEPOSIT_PREDICTION_E%>"
                    <%=domainOfService.getDepositPredication()!= null && domainOfService.getDepositPredication().contains(DomainOfService.CNS_DEPOSIT_PREDICTION_E)?"checked='checked'":""%>
                       class="va FieldCheckBox">
                <label for="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_E%>"
                       class="va">
                    <fmt:message key="dos.pdt.cheque"/>
                </label>
            </td>
            <td  width="14%">
                <input type="checkbox" name="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>"
                       id="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_Q%>"
                       value="<%=DomainOfService.CNS_DEPOSIT_PREDICTION_Q%>"
                    <%=domainOfService.getDepositPredication()!= null && domainOfService.getDepositPredication().contains(DomainOfService.CNS_DEPOSIT_PREDICTION_Q)?"checked='checked'":""%>
                       class="va FieldCheckBox">
                <label for="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_Q%>"
                       class="va">
                    <fmt:message key="dos.pdt.epayment"/>
                </label>
            </td>
            <td  width="14%">
                <input type="checkbox" name="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>"
                       id="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_O%>"
                       value="<%=DomainOfService.CNS_DEPOSIT_PREDICTION_O%>"
                    <%=domainOfService.getDepositPredication()!= null && domainOfService.getDepositPredication().contains(DomainOfService.CNS_DEPOSIT_PREDICTION_O)?"checked='checked'":""%>
                       class="va FieldCheckBox">
                <label for="<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_O%>"
                       class="va">
                    <fmt:message key="other"/>
                </label>
            </td>
            <td  width="14%"></td>
            <td  width="14%"></td>
        </tr>
        <tr id="dospredicting_reason_deposit">
            <td  width="14%" class="FieldLabel">
                <sup class='LegendText'><%=mandatorySymb%></sup><fmt:message key='dos.predicting.reason.deposit'/>:
            </td>
            <td colspan="6"></td>
        </tr>
        <% int counter = 0;
            for (int i = 0; i < depositReasonPredication.length; i++) {%>
        <%
            boolean isChecked = domainOfService.getDepositReasonPredication() != null && domainOfService.getDepositReasonPredication().contains(depositReasonPredication[i].getShortDesc());
            String comment = "";
            if (isChecked)
                comment = domainOfService.getDepositReasonPredicationComment().split(SEPRATOR)[counter++];
        %>
        <tr name="dospredicting_reason_deposit_checkbox">
            <td  width="14%">
                <input id="<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_<%=depositReasonPredication[i].getShortDesc()%>item_<%=i+1%>"
                       name="<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>"
                    <%=isChecked?"checked='checked'":""%>
                       type="checkbox" value="<%=depositReasonPredication[i].getShortDesc()%>" class="va FieldText">
                <label for="<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_<%=depositReasonPredication[i].getShortDesc()%>item_<%=i+1%>"
                       class="va">
                    &nbsp;<%=TextUtil.getLocalizedLabel(depositReasonPredication[i].getLongDesc(), USER_SESSION.getCommonSess().getLocale())%>
                </label>
            </td>
            <td  width="14%" class="FieldLabel">

                <fmt:message key="comment"/>
                <input maxlength="100" size="32" type="text" class="FieldText"
                       name="<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION_COMMENT%>"
                       value="<%=comment%>"
                       id="<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_comment<%=i+1%>" disabled="disabled">
            </td>
            <td colspan="5"></td>
        </tr>
        <%}%>


        <table class="BodyTable" id="txnAreaTbl">
            <input type="hidden" name="<%=TransactionAreas.PROP_SRL_NO%>" value="<%=srNO%>">
            <tr class="BodyTableRow">
                <td class="SectionCaption" colspan="7">
                    <fmt:message key="expected.geographical.areaof.frequent.transactions" />
                </td>
            </tr>
            <%
                Address address = customerBiz.validateCountryAndInitializeState(branchParam.getDefaultCountry());
            %>
            <tr class="BodyTableRow" name="source">
                <td width="20%"><sup class='LegendText'>*</sup><fmt:message key="source.country"/></td>
                <td  width="20%">
                    <input name="<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>" class="FieldText"  display="<fmt:message key= 'country.code' />" mandatory="yes" tabindex='<%=tabIdx++%>' maxlength='3' readonly value="<%=branchParam.getDefaultCountry()%>">
                    <input type="button" name="country" class="FieldButton" value="..." tabindex="-1" onfocus="<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.focus();" onClick="openPopWin('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_COUNTRY%>')">
                    <input type="text" name="<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE+"_DESC"%>" tabindex="-1"  size="45" class="FieldTextRO" readOnly value="<%=address.getCountryCodeDesc()%>">
                </td>
                <td width="20%"><sup class='LegendText'>*</sup><fmt:message key="source.city"/></td>
                <td  width="20%">
                    <input name="<%=TransactionAreas.PROP_SOURCESTATE_CODE%>" class="FieldText" display="<fmt:message key= 'state.code' />" mandatory="yes" tabindex='<%=tabIdx++%>' maxlength='50' size="50" >
                    <%--<input type="button" name="state" class="FieldButton" value="..." tabindex="-1"  onfocus="<%=TransactionAreas.PROP_SOURCESTATE_CODE%>.focus();" onClick="openPopWin('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_STATE%>&countryCode='+this.form.<%=TransactionAreas.PROP_SOURCE_COUNTRY_CODE%>.value)">
                    <input type="text" name="<%=TransactionAreas.PROP_SOURCESTATE_CODE+"_DESC"%>" size="45" class="FieldTextRO" tabindex="-1"  readOnly>--%>
                </td>
                <td  width="20%"></td>
            </tr>
            <tr class="BodyTableRow" name="destination">
                <td width="20%"><sup class='LegendText'>*</sup><fmt:message key="destination.country"/></td>
                <td width="20%">
                    <input name="<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>" class="FieldText"  display="<fmt:message key= 'country.code' />" mandatory="yes" tabindex='<%=tabIdx++%>' maxlength='3' readonly value="<%=branchParam.getDefaultCountry()%>">
                    <input type="button" name="country" class="FieldButton" value="..." tabindex="-1" onfocus="<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.focus();" onClick="openPopWin('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_COUNTRY2%>')">
                    <input type="text" name="<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE+"_DESC"%>" tabindex="-1"  size="45" class="FieldTextRO" readOnly value="<%=address.getCountryCodeDesc()%>">
                </td>
                <td width="20%"><sup class='LegendText'>*</sup><fmt:message key="destination.city"/></td>
                <td width="20%">
                    <input name="<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>" class="FieldText" display="<fmt:message key= 'state.code' />" mandatory="yes" tabindex='<%=tabIdx++%>' maxlength='50' size="50" >
                    <%--<input type="button" name="state" class="FieldButton" value="..." tabindex="-1"  onfocus="<%=TransactionAreas.PROP_DESTINATION_STATE_CODE%>.focus();" onClick="openPopWin('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_STATE2%>&countryCode='+this.form.<%=TransactionAreas.PROP_DESTINATION_COUNTRY_CODE%>.value)">
                    <input type="text" name="<%=TransactionAreas.PROP_DESTINATION_STATE_CODE+"_DESC"%>" size="45" class="FieldTextRO" tabindex="-1"  readOnly>--%>
                </td>
                <td  width="20%"></td>
            </tr>
            <tr class="BodyTableRow">
                <td colspan="5" align="center">
                    <input name='btnAdd' type="button" class="FieldButton" value="<fmt:message key= "add" />" onClick="return saveTxnArea(this.form,'<%=IConstants.ADD%>')" tabindex="<%=tabIdx++%>">
                    <input name='btnModify' type="submit" class="FieldButton" value="<fmt:message key= "modify" />" onClick="return saveTxnArea(this.form,'<%=IConstants.MODIFY%>')" disabled tabindex="<%=tabIdx++%>">
                    <input name='btnDelete' type="submit" class="FieldButton" value="<fmt:message key= "delete" />" disabled tabindex="<%=tabIdx++%>" onClick="return removeAddress(this.form)">
<%--                    <input name='btnReset' type='reset' value='<fmt:message key= "reset" />' onClick="enableDisableButtonsForReset(this.form)" class="FieldButton" tabindex="<%=tabIdx++%>">--%>
<%--                    <input name="btnNext" type="submit" value='<fmt:message key= "next" />' class="FieldButton" tabindex="<%=tabIdx++%>" onClick="return goToNextUrl(this.form)" disabled>--%>
                </td>
            </tr>
        </table>
        <table class="InfoList" id="resultTbl">
            <tr class="InfoListHeader">
                <th width="20%">#</th>
                <th width="20%"><fmt:message key="source.country"/></th>
                <th width="20%"><fmt:message key="source.city"/></th>
                <th width="20%"><fmt:message key="destination.country"/></th>
                <th width="20%"><fmt:message key="destination.city"/></th>
            </tr>
            <%if (txnAreas!=null && txnAreas.length>0){%>
            <input type="hidden" name="totalRec" value=<%=txnAreas.length%>>
            <%for(int i=0;i<txnAreas.length;i++) {
                Country[] source = customerBiz.getDescStateAndDescCountry(txnAreas[i].getSourceStateCode(),txnAreas[i].getSourceCountryCode());
                Country[] destination = customerBiz.getDescStateAndDescCountry(txnAreas[i].getDestinationStateCode(),txnAreas[i].getDestinationCountryCode());
                if ( txnAreas[i].getActionFlag() != IConstants.DELETE ){
                    String rowClass = (((i%2) == 0) ? "InfoListOddRow" : "InfoListEvenRow");%>
            <tr class="<%=rowClass%>">
                <td align="center" width="20%">
                    <input type="radio" name="count" value="<%=i+1%>"
                           onClick="transferAddressDetails(this.form,this.value);enableDisableButtons(this.form)"
                           tabindex="<%=tabIdx++%>">
                </td>
                <td class="FieldTextRO" style="text-align: center" width="20%"><%=source!=null && source.length>0 ? source[0].getCountryDesc():txnAreas[i].getSourceCountryCode()%></td>
                <td class="FieldTextRO" style="text-align: center" width="20%"><%=source!=null && source.length>0 ? source[0].getStateDesc():txnAreas[i].getSourceStateCode()%></td>
                <td class="FieldTextRO" style="text-align: center" width="20%"><%=destination!=null && destination.length>0 ? destination[0].getCountryDesc():txnAreas[i].getDestinationCountryCode()%></td>
                <td class="FieldTextRO" style="text-align: center" width="20%"><%=destination!=null && destination.length>0 ? destination[0].getStateDesc():txnAreas[i].getDestinationStateCode()%></td>
            </tr>
            <%}%>
            <input type="hidden" name="txnAreaSrlNo" value="<%=txnAreas[i].getSrlNo()%>">

            <input type="hidden" name="existSourceCountryCode" value="<%=txnAreas[i].getSourceCountryCode()%>">
            <input type="hidden" name="existSourceStateCode" value="<%=txnAreas[i].getSourceStateCode()%>">
            <input type="hidden" name="existDestinationCountryCode" value='<%=txnAreas[i].getDestinationCountryCode()%>'>
            <input type="hidden" name="existDestinationStateCode" value='<%=txnAreas[i].getDestinationStateCode()%>'>
            <input type="hidden" name="isExistInDB" value="<%=txnAreas[i].isExistInDB()%>">
            <%}%>
            <%}%>
        </table>
        <tr></tr>

        <tr class="BodyTableRow" id="lastChild">
            <td colspan="2">
                <%if (!auth) {%>
                <input type="button" value="<fmt:message key='save'/>" class="FieldButton" name="btnSubmit"
                       onClick="return validation(document.caller)" tabindex="<%=tabIdx++%>">
                <input type="reset" value="<fmt:message key= 'reset'/>" class="FieldButton" name="btnReset"
                       tabindex="<%=tabIdx++%>">
                <input type="button" value="<fmt:message key='next'/>" class="FieldButton" name="btnNext"
                       onClick="return goToNextURL(document.caller)" tabindex="<%=tabIdx++%>">
                <%} else {%>
                <input type="button" value="<fmt:message key='next'/>" class="FieldButton" name="btnNext"
                       onClick="buttonAction(document.caller)" tabindex="<%=tabIdx++%>">
                <input type="button" value="<fmt:message key= 'cancel'/>" class="FieldButton" name="btnCancel"
                       onClick="goToHome()" tabindex="<%=tabIdx++%>">
                <%}%>
            </td>
            <td colspan="5"></td>
        </tr>
    </table>
    <% } %>
    <input type="hidden" name="processingStep">
    <input type="hidden" name="changeTxnArea">
    <script>
        check();
        <%if (!auth){%>
        init();
        //amountInWords(document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>_num
        //)
        //;putComma(document.caller, document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>, '<%=digitFormat%>'
        //)
        //;
        //amountInWords(document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>_num
        //)
        //;putComma(document.caller, document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>, '<%=digitFormat%>'
        //)
        //;
        //amountInWords(document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>_num
        //)
        //;putComma(document.caller, document.caller
        //.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>.
        //value, document.caller.<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>, '<%=digitFormat%>'
        //)
        //;
        <%} else {%>
        $('#<%=DomainOfService.PROP_MATURE%>1').attr('disabled', true);
        $('#<%=DomainOfService.PROP_MATURE_KIND%>').attr('disabled', true);
        $('#<%=DomainOfService.PROP_MATURE%>2').attr('disabled', true);
        $('#<%=DomainOfService.PROP_INCAPABLE_KIND%>').attr('disabled', true);
        //$('#<%=DomainOfService.PROP_EXPENDITURE_FORCAST_MONTHLY%>').attr('disabled', true);
        //$('#<%=DomainOfService.PROP_EXPENDITURE_FORCAST_QUARTERLY%>').attr('disabled', true);
        //$('#<%=DomainOfService.PROP_EXPENDITURE_FORCAST_YEARLY%>').attr('disabled', true);
            $('#<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_C%>').attr('disabled',true);
            $('#<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_Q%>').attr('disabled',true);
            $('#<%=DomainOfService.PROP_DEPOSIT_PREDICATION%>_<%=DomainOfService.CNS_DEPOSIT_PREDICTION_E%>').attr('disabled',true);
            debugger;
            var opOptns = $("input[id^='<%=DomainOfService.PROP_ACCOUNT_OPENNING_PURPOSE%>_']");
            for (var index = 0; index < opOptns.length; index++) {
                $(opOptns[index]).attr('disabled',true);
            }

            var opOptns2 = $("input[id^='<%=DomainOfService.PROP_DEPOSIT_REASON_PREDICATION%>_']");
            for (var index = 0; index < opOptns2.length; index++) {
                $(opOptns2[index]).attr('disabled',true);
            }
        <%}%>
    </script>
    <%}%>
</form>

<%@ include file="../common/footer.inc.jsp" %>
