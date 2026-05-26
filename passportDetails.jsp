<%@page import="dm.web.utils.RequestReader,java.sql.Date, dm.web.cust.CustomerBiz, dm.persist.mmaint.PlaceCode,java.util.HashMap"
		errorPage="../common/error.jsp"%>
<%@ page import="dm.persist.cust.*" %>
<%@ page import="dm.persist.common.*" %>
<%@ page import="dm.web.common.*" %>
<%@ page import="java.util.Locale" %>
<%@ page import="dm.common.*" %>
<%@ page import="dm.common.suspectModel.SuspectActionsEnum" %>
<%@ page import="dm.utils.CommonUtils" %>
<%@include file="../common/top.inc.jsp"%>

<%
	PAGE_TITLE = TextUtil.getLocalizedLabel("passport.details");
	BODY_ONLOAD = "";
	String processingStep = request.getParameter("processingStep");
	String bank 		 = USER_SESSION.getCommonSess().getBank();
	String userCode 	= USER_SESSION.getCommonSess().getUserCode().toUpperCase();
	Date currDate   	= USER_SESSION.getCommonSess().getCurrentDate();
    CreateCustomerInfo customerInfo = USER_SESSION.getCustSess().getCreateCustomerInfo();
	Customer customer = customerInfo.getCustomer();
	int tabIdx=1;
	dateFormat = USER_SESSION.getCommonSess().getBankDefaultDateFormat();
	//Added By Lalesh w.r.t issue #466 rel ver 4.0.4 on 22-July-2013
	String currentDt    =DateUtil.formatDate(USER_SESSION.getCommonSess().getCurrentDate(), dateFormat);
	PassportDetails passportDetails = new PassportDetails();
	//Added by AmolB,On 23-July-2013 , w.r.t Bug#532
	int txnType	= customerInfo.getTxnType();
  	HashMap hashmap=null;
	PAGE_TITLE = ((txnType == IConstants.MODIFY)?TextUtil.getLocalizedLabel("customer.modification"):PAGE_TITLE);
    boolean mandatory = false;


	RangeConstraints[] residentDocuments =(new SearchBiz())
			.fetchRangeConstraintsListSortedByReason(PassportDetails.PROP_RESIDENTDOC.toUpperCase()
					,PassportDetails.TABLE_NAME.toUpperCase());
	RangeConstraints[] residentCardTypes =(new SearchBiz())
			.fetchRangeConstraintsListSortedByReason(PassportDetails.PROP_RESIDENT_CARD_TYPE.toUpperCase()
					,PassportDetails.TABLE_NAME.toUpperCase());
	RangeConstraints[] visaRightTypes =(new SearchBiz())
			.fetchRangeConstraintsListSortedByReason(PassportDetails.PROP_VISA_RIGHT_TYPE.toUpperCase()
					,PassportDetails.TABLE_NAME.toUpperCase());
	RangeConstraints[] residentType =(new SearchBiz())
			.fetchRangeConstraintsListSortedByReason(PassportDetails.PROP_RESIDENT_TYPE.toUpperCase()
					,PassportDetails.TABLE_NAME.toUpperCase());
	RangeConstraints[] visaTypes =(new SearchBiz())
			.fetchRangeConstraintsListSortedByReason(PassportDetails.PROP_VISA_TYPE.toUpperCase()
					,PassportDetails.TABLE_NAME.toUpperCase());
	String residentNo = "";
	if (customerInfo.getPassportDetails() != null ) {
		passportDetails = customerInfo.getPassportDetails();
		passportDetails.setCustomerId(customerInfo.getCustomer().getCustId());
		residentNo = passportDetails.getResidentNo();
	}

	PopInfo popPlaceCodeInfo = new PopInfo();
	PlaceCode placeCode  = new PlaceCode();
	popPlaceCodeInfo.setCodeFieldHeader(TextUtil.getLocalizedLabel("issue.place.code"));
	popPlaceCodeInfo.setDescFieldHeader(TextUtil.getLocalizedLabel("issue.place.desc"));
	popPlaceCodeInfo.setCodeFieldName(PassportDetails.PROP_ISSUED_PLACE);
	popPlaceCodeInfo.setDescFieldName(PassportDetails.PROP_ISSUED_PLACE+"Desc");
	placeCode.setBank(bank);
	popPlaceCodeInfo.setPO(placeCode);
	USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_PLACE_CODE, popPlaceCodeInfo);


	PopInfo popCountryBornMis = new PopInfo();
	popCountryBornMis.setCodeFieldHeader(TextUtil.getLocalizedLabel("born.county.code"));
	popCountryBornMis.setDescFieldHeader(TextUtil.getLocalizedLabel("born.county"));
//	popCountryBornMis.setCodeFieldName(PassportDetails.PROP_BORN_COUNTRY);
//	popCountryBornMis.setDescFieldName(PassportDetails.PROP_BORN_COUNTRY+"Desc");
	MisSubCode misSubCodeCountry = new MisSubCode();
	misSubCodeCountry.setBank(bank);
	popCountryBornMis.setPO(misSubCodeCountry);
	USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_COUNTRY_MIS, popCountryBornMis);

	PopInfo popVisaCancellationCountry = new PopInfo();
	popVisaCancellationCountry.setCodeFieldHeader(TextUtil.getLocalizedLabel("county.code"));
	popVisaCancellationCountry.setDescFieldHeader(TextUtil.getLocalizedLabel("visa.cancellation.country"));
	MisSubCode misSubCodeVisaCountry = new MisSubCode();
	misSubCodeVisaCountry.setBank(bank);
	popVisaCancellationCountry.setPO(misSubCodeVisaCountry);
	USER_SESSION.getCommonSess().setPopInfo(PopBiz.POP_TYPE_COUNTRY_MIS, popVisaCancellationCountry);

	activeTab 	= TextUtil.getLocalizedLabel("passport.details");
//    Modified by Maryam on Aug-2015 ver. 5.5.3 issue #12001
	if (request.getParameter(PassportDetails.PROP_RESIDENT_NO)==null && customerInfo.getCustomer().getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) &&
            customerInfo.getCustomer().getCustType().equals(Customer.CUSTOMER_TYPE_IND))
    {
         mandatory = true;
    }
    // manage disable create or edit passport information on national customer
    boolean disableEditPassportInfo = false;
    if (customerInfo.getCustomer().getCustCategory().equals(Customer.CUSTOMER_CATEGORY_NATIONAL)) {
	    disableEditPassportInfo = true;
	}
	if (processingStep == null ) {
		BODY_ONLOAD = "document.caller." + PassportDetails.PROP_PASSPORT_NO + ".focus()";
	} else if (processingStep.equalsIgnoreCase("SAVE_PASSPORT_DETAILS") == true) {
		//Added by Rushikesh w.r.t. Issue #11568 on 14-Jul-2015 for Rel Ver 5.5.1.
		CommonBizValidator.validateInputs(USER_SESSION,request,CommonBizValidator.CREATE_CUST_SAVE_PASSPORT_DETAILS,hashmap);
		//Added By Vinayak on 18.Jun.2013 w.r.t. Issue# 145 for the release 4.0.1
		if(customerInfo.getTxnType() == IConstants.MODIFY) {
			boolean [] recordModified = customerInfo.IsRecordModified();
			recordModified[14] = true;
			customerInfo.setIsRecordModified(recordModified);
		}

		String oldResidentDoc = "";
		if (passportDetails!=null)
		{
			oldResidentDoc  = passportDetails.getResidentDoc();
		}
		passportDetails  =(PassportDetails )RequestReader.populateTxnInfo(request, passportDetails, null, dateFormat);
		passportDetails.setBank(bank);

        /*  Modified by mostafa Issue #15867 on 4/20/2019 ver rel 7.0.18  */
		String residentExpiryDate = "";
		if (!CommonUtils.IsNullOrEmpty(request.getParameter("ResidentryExpiryDate"))) {
			residentExpiryDate = request.getParameter("ResidentryExpiryDate");
			java.sql.Date residentryExpiryDate = DateUtil.parseSqlDate(residentExpiryDate, dateFormat);
			passportDetails.setResidentryExpiryDate(residentryExpiryDate);
		}

		CustomerBiz customerBiz = new CustomerBiz();

		//if (!CommonUtils.IsNullOrEmpty(passportDetails.getIssuedPlace()) && passportDetails.getIssuedPlace().equals("") == false ) {
			try {
			    if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)) {
					customerBiz.foreginCodeValidate(bank, passportDetails.getResidentNo(), !residentNo.equals(passportDetails.getResidentNo())?true:false);
				}
				if (!CommonUtils.IsNullOrEmpty(passportDetails.getIssuedPlace()) && passportDetails.getIssuedPlace().equals("") == false )
					customerBiz.validatePlaceCode(passportDetails.getBank(), passportDetails.getIssuedPlace());

			} catch (Exception e) {
				passportDetails.setResidentNo(residentNo);
				USER_SESSION.setException(e);
				processingStep = null;
			}
		//}
		if (!CommonUtils.IsNullOrEmpty(passportDetails.getBornCountry()) && passportDetails.getBornCountry().equals("") == false)
		{
			try {
				customerBiz.validateCountryMis( bank, passportDetails.getBornCountry());
			} catch (Exception e) {
				passportDetails.setResidentNo(residentNo);
				USER_SESSION.setException(e);
				processingStep = null;
			}
		}

		if (!CommonUtils.IsNullOrEmpty(passportDetails.getResidentDocFromCountry()) && passportDetails.getResidentDocFromCountry().equals("") == false)
		{
			try {
				customerBiz.validateCountryMis(bank, passportDetails.getResidentDocFromCountry());
			} catch (Exception e) {
				passportDetails.setResidentNo(residentNo);
				USER_SESSION.setException(e);
				processingStep = null;
			}
		}

		dm.persist.cust.CustomerMisCode passportCustomerMisCode = new CustomerMisCode();
		passportCustomerMisCode.setMainCode(MisCode.MIS_CODE_027);
//		passportCustomerMisCode.setSubCode(requ);

		if (USER_SESSION.hasExceptions() == false ) {
			customerInfo.setCustomer(customer);
			customerInfo.setPassportDetails(passportDetails);
			USER_SESSION.getCustSess().setCreateCustomerInfo(customerInfo);
			response.sendRedirect("domainOfService.jsp");
		}
	}
%>

<%-- Added by AmolB ver-4.0.4 , on 22-July-2013 w.r.t Bug #462 --%>
<script language="javascript" src="../common/ajax.js"></script>
<script language="javascript" src="../../jscripts/suspect.js"></script>
<script language="javascript" src="../../jscripts/jquery.js"></script>
<script language="javascript">
	function alphaOnly(event) {
		var key = event.keyCode;
		var aKey = event.key;
		if ( '<%=TextUtil.getLocalizedLabel("persian.chars")%>'.indexOf(aKey)>-1)
		{
			return true;
		}
		if ( !((key >= 65 && key <= 90) || key == 8 || key == 37 || key == 39
				|| key == 46 || key == 35 || key == 36 || key == 32
				|| key == 16 || key == 17 || key == 221 || key == 220
				|| key == 222 || key == 45 || key == 219 || key==186 || key==187 || key==188
		))
		{
			event.preventDefault();
			event.stopPropagation();
			return false;
		}
		if ('"\';:/\\.,][{}|<>+-='.indexOf(aKey)>-1)
		{
			event.preventDefault();
			event.stopPropagation();
			return false;
		}
		return true;
	};

	function checkSpecialCharsN(elem){
		if (elem == null || elem == undefined || elem.disabled == true){
			return true;
		}
		var chars = "{}=`./~'\\!#@%$%^*()_-+|:><?,;'[]\"";
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

	function validation(frm) {
		<%if (customer.getCustCategory().equalsIgnoreCase(Customer.CUSTOMER_CATEGORY_NATIONAL)){%>
			javascript:location.replace('domainOfService.jsp');
			return false;
		<%}%>
		<%if(customer.getCustCategory().equalsIgnoreCase(Customer.CUSTOMER_CATEGORY_FOREIGN)){ %>
		if (frm.<%=PassportDetails.PROP_RESIDENT_NO%>) {
			//Issue CBDEV-5502
			if (checkIsSuspect('','','',
					'','',frm.<%=PassportDetails.PROP_RESIDENT_NO%>.value,'<%=SuspectActionsEnum.Customer_Definition.getActionCode()%>',
					'<%=strHeaderBranch%>','<%=userName%>')){
				alert('<fmt:message key="the.customer.is.on.the.suspect.list.and.can.not.get.basic.services"/>');
				return false;
			}
		}
		<%}%>
		//modified by rohit w.r.t bug #573 on 24-July-2013 for rel. ver. 4.0.4
		frm.<%=PassportDetails.PROP_RESIDENT_NO%>.mandatory="no";
        frm.<%=PassportDetails.PROP_RESIDENT_NO%>.data = "alphaNum";
		//frm.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory="no";

		/*if (frm.<%=PassportDetails.PROP_PASSPORT_NO%>.value == ""){
			frm.<%=PassportDetails.PROP_RESIDENT_NO%>.mandatory="yes";
		}*/
		frm.<%=PassportDetails.PROP_RESIDENT_NO%>.display="<fmt:message key='resident.no' />";

		/*if (frm.<%=PassportDetails.PROP_RESIDENT_NO%>.value == "" ){
			frm.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory="yes";
		}*/
        if (frm.<%=PassportDetails.PROP_RESIDENT_NO%>.value != "" && frm.<%=PassportDetails.PROP_RESIDENT_NO%>.value.length < 7)
        {
            alert("<fmt:message key='corporate.resident.no.isnotvalid' />");
            return false;
        }
//        Modified by Maryam on Aug-2015 ver. 5.5.3 issue #12001
        if (<%=mandatory%>)
        {
            frm.<%=PassportDetails.PROP_RESIDENT_NO%>.mandatory="yes";
            frm.<%=PassportDetails.PROP_RESIDENT_NO%>.display="<fmt:message key='resident.no' />";
        }
		frm.<%=PassportDetails.PROP_PASSPORT_NO%>.display="<fmt:message key='passport.no' />";
		//end #573


		frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.mandatory="yes";
		frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.display="<fmt:message key='expiry.date.passportdtl' />";
		frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.data="date";

        <%-- Modified by mostafa Issue #15867 on 4/20/2019 ver rel 7.0.18 --%>

		<%--
        frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory="yes";
        frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.display="<fmt:message key='residentry.expiry.date' />";
        frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data="date";

		--%>

		if (frm.<%=PassportDetails.PROP_ISSUED_BY%>!=null && frm.<%=PassportDetails.PROP_ISSUED_BY%>!= undefined){
		frm.<%=PassportDetails.PROP_ISSUED_BY%>.mandatory="yes";
		frm.<%=PassportDetails.PROP_ISSUED_BY%>.display="<fmt:message key='issued.by' />";
		}

		if (frm.<%=PassportDetails.PROP_ISSUED_PLACE%>!=null && frm.<%=PassportDetails.PROP_ISSUED_PLACE%>!=undefined){
		frm.<%=PassportDetails.PROP_ISSUED_PLACE%>.mandatory="yes";
		frm.<%=PassportDetails.PROP_ISSUED_PLACE%>.display="<fmt:message key='issued.place' />";
		}




		<%--Added By Lalesh w.r.t issue #466 rel ver 4.0.4 on 22-July-2013 --%>
   		var currentDate = getFormatDate('<%=currentDt %>', '<%=dateFormat %>');
   		<%--Added By Lalesh w.r.t issue #466 rel ver 4.0.4 on 26-July-2013 --%>

		var currentExpiryDate = null;


        <%-- Modified by mostafa Issue #15867 on 4/20/2019 ver rel 7.0.18 --%>
        <%--if (frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.value != null && frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.value != "") {--%>
            <%--var residentExpiryDate = getFormatDate(frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.value, '<%=dateFormat %>');--%>
            <%--if (residentExpiryDate <= issueDate || residentExpiryDate <= expiryDate || residentExpiryDate <= currentDate) {--%>
                <%--alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.RESIDENTRY_EXPIRY_DATE_SHOULD_BE_GREATER_THAN_EXPIRY_DATE_AND_CURRENT_DAY)%>");--%>
                <%--frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.focus();--%>
                <%--return false;--%>
            <%--}--%>
        <%--}--%>

		<%--#18092 Ehsan{--%>
		<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true ){ %>

		<%--Validate amayesh--%>

		var avalue = frm.AmayeshCardNo.value;
		if (avalue) {
			var notcontain = " +-*/)(&^%$#@!?؟.,;:[]{}|~`";
			for (var i = 0; i < notcontain.length; i++) {
				if (avalue.indexOf(notcontain.charAt(i)) > -1) {
					alert('<%=TextUtil.getLocalizedLabel("amayesh.entry")%>');
					frm.AmayeshCardNo.focus();
					return false;
				}
			}
			var i = 0;
			var found = false;
			while (!found) {

				if (avalue.indexOf(i.toString()) > -1)
					found = true;
				i++;
				if (i == 10) break;
			}

			if (!found) {
				alert('<%=TextUtil.getLocalizedLabel("amayesh.entry")%>');
				frm.AmayeshCardNo.focus();
				return false;
			}
		}


		if (frm.<%=PassportDetails.PROP_RESIDENTDOC%>.value.trim() == "")
		{
			alert('<%=TextUtil.getLocalizedLabel("type.of.identification.document")%> can not be null');
			frm.<%=PassportDetails.PROP_RESIDENTDOC%>.focus();
			return false;
		}
		if (frm.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>!=null && frm.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>!=undefined){
		if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.value.trim() == "")
		{
			alert('<%=TextUtil.getLocalizedLabel("resident.document.country")%> can not be null');
			frm.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.focus();
			return false;
		}
		}
		if (frm.<%=PassportDetails.PROP_BORN_COUNTRY%>!=null && frm.<%=PassportDetails.PROP_BORN_COUNTRY%>!=undefined){
		frm.<%=PassportDetails.PROP_BORN_COUNTRY%>.mandatory="yes";
		frm.<%=PassportDetails.PROP_BORN_COUNTRY%>.display="<fmt:message key='birth.country' />";
		}


		if (frm.<%=PassportDetails.PROP_BORN_CITY%>!=null && frm.<%=PassportDetails.PROP_BORN_CITY%>!=undefined){
		frm.<%=PassportDetails.PROP_BORN_CITY%>.mandatory="yes";
		frm.<%=PassportDetails.PROP_BORN_CITY%>.display="<fmt:message key='birth.city' />";
		}
		if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != '' && '02,03,04,05,06'.indexOf( document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value) >=0)
		{
			if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>!=null && document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>!=undefined
					&& document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.value != '105')
			{
				alert('<%=TextUtil.getLocalizedLabel("only.iran.can.selected.with.selected.identity.type")%>');
				return false;
			}
		}

/*		if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != '' && '0506'.indexOf( document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value) >=0)
		{
			frm.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.value = frm.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.value.trim();
			frm.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.mandatory="yes";
			frm.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.display="<fmt:message key='identity.card.number' />";
		}
		else
		{
			frm.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.mandatory="no";
		}*/
		//if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != '' &&
		//('05'.indexOf( document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value) >=0
		//	|| '06'.indexOf( document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value) >=0
		//))
		//{
			//frm.<%=PassportDetails.PROP_ISSUE_DATE%>.mandatory="no";
			//frm.<%=PassportDetails.PROP_ISSUE_DATE%>.data=undefined;

		//}
		//else
		//{
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.mandatory="yes";
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.display="<fmt:message key='issue.date' />";
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.data="date";
			var issueDate = getFormatDate(frm.<%=PassportDetails.PROP_ISSUE_DATE %>.value, '<%=dateFormat %>');

			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.mandatory="yes";
			if( issueDate>currentDate){
				alert("<fmt:message key='msg.passport.issue.date.can.not.be.greater.than.today' />")
				return false;
			}
			var expiryDate = getFormatDate(frm.<%=PassportDetails.PROP_EXPIRY_DATE %>.value, '<%=dateFormat %>');
			<%if (customerInfo!= null &&  customerInfo.getPassportDetails() != null && customerInfo.getPassportDetails().getExpiryDate()!= null){%>
			try {
				currentExpiryDate = getFormatDate(' <%=DateUtil.formatDate(customerInfo.getPassportDetails().getExpiryDate(),dateFormat)%>', '<%=dateFormat%>');
			}catch (Ex)
			{
				currentExpiryDate = null;
			}
			<%}%>
			<%if (customer.getCustId() == null || customer.getCustId().equals("")){%>
			if ((expiryDate <= issueDate || expiryDate <= currentDate)) {
				alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.EXPIRY_DATE_SHOULD_BE_GREATER_THAN_ISSUE_DATE_AND_CURRENT_DAY)%>");
				frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.focus();
				return false;
			}
			<%} else {%>
			if ((currentExpiryDate== null || expiryDate.getTime() !== currentExpiryDate.getTime()) && (expiryDate <= issueDate || expiryDate <= currentDate)) {
				alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.EXPIRY_DATE_SHOULD_BE_GREATER_THAN_ISSUE_DATE_AND_CURRENT_DAY)%>");
				frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.focus();
				return false;
			}
			<%}%>
		//}
		if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != '' && '08'.indexOf( document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value) >=0)
		{
			frm.<%=PassportDetails.PROP_ENTER_DATE%>.mandatory="yes";
			document.getElementById("starDt").style.display  = "";
			frm.<%=PassportDetails.PROP_ENTER_DATE%>.display="<fmt:message key='enter.date.to.country' />";
			frm.<%=PassportDetails.PROP_ENTER_DATE%>.data="date";
			if (frm.<%=PassportDetails.PROP_ENTER_DATE%>.value.trim()!=='')
			{
				var enterDate = getFormatDate(frm.<%=PassportDetails.PROP_ENTER_DATE%>.value, '<%=dateFormat %>');
				if (enterDate>currentDate)
				{
					alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.ENTER_DATE_SHOULD_BE_LESSER_THAN_ISSUE_DATE_AND_CURRENT_DAY)%>");
					frm.<%=PassportDetails.PROP_ENTER_DATE%>.focus();
					return false;
				}
			}
		}
		else
		{
			frm.<%=PassportDetails.PROP_ENTER_DATE%>.mandatory="no";
			document.getElementById("starDt").style.display  = "none";
			if (frm.<%=PassportDetails.PROP_ENTER_DATE%>.value.trim()=='')
			{
				frm.<%=PassportDetails.PROP_ENTER_DATE%>.data = undefined;
			}
			else
			{
				var enterDate = getFormatDate(frm.<%=PassportDetails.PROP_ENTER_DATE%>.value, '<%=dateFormat %>');
				if (enterDate>currentDate)
				{
					alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.ENTER_DATE_SHOULD_BE_LESSER_THAN_ISSUE_DATE_AND_CURRENT_DAY)%>");
					frm.<%=PassportDetails.PROP_ENTER_DATE%>.focus();
					return false;
				}
				frm.<%=PassportDetails.PROP_ENTER_DATE%>.data = "date";
			}
		}
		<%} else {%>
			<%--OLD CODE FOR NON FOREIGN CUSTOMERS--%>
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.mandatory="yes";
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.display="<fmt:message key='issue.date' />";
			frm.<%=PassportDetails.PROP_ISSUE_DATE%>.data="date";
			<%--Added By Lalesh w.r.t issue #466 rel ver 4.0.4 on 22-July-2013 --%>
			if (frm.<%=PassportDetails.PROP_ISSUE_DATE %>.value.trim().length != 0 && frm.<%=PassportDetails.PROP_EXPIRY_DATE %>.value.trim().length !=0){
			var issueDate = getFormatDate(frm.<%=PassportDetails.PROP_ISSUE_DATE %>.value, '<%=dateFormat %>');
			var expiryDate = getFormatDate(frm.<%=PassportDetails.PROP_EXPIRY_DATE %>.value, '<%=dateFormat %>');
			var currentDate = getFormatDate('<%=currentDt %>', '<%=dateFormat %>');
			<%--Added By Lalesh w.r.t issue #466 rel ver 4.0.4 on 26-July-2013 --%>
			if( issueDate>currentDate){
				alert("<fmt:message key='msg.passport.issue.date.can.not.be.greater.than.today' />")
				return false;
			}
			if (expiryDate <= issueDate || expiryDate <= currentDate) {
				alert("<%=TextUtil.getLocalizedMessage(ExCode.TradefinEx.EXPIRY_DATE_SHOULD_BE_GREATER_THAN_ISSUE_DATE_AND_CURRENT_DAY)%>");
				frm.<%=PassportDetails.PROP_EXPIRY_DATE%>.focus();
				return false;
			}
			}
		<%}%>
		<%--#18092 Ehsan}--%>

		if (validate(frm) == true) {
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0]) == false)
				return false;
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1]) == false)
				return false;
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2]) == false)
				return false;
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>) == false)
				return false;
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_LICENSE_NO%>) == false)
				return false;
			if (checkSpecialCharsN(document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>) == false)
				return false;

			if (checkLength(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0],12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1],12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2],12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>,12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_LICENSE_NO%>,12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>,12) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>,15) == false)
				return false;
			if (checkLength(document.caller.<%=PassportDetails.PROP_RESIDENT_NO%>,13) == false)
				return false;
			if (document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != "05" && document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value != "09"){
				if (frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE %>.value!=null && frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE %>.value.trim().length>0){
					var currentDate = getFormatDate('<%=currentDt %>', '<%=dateFormat %>');
					var expiryDate = getFormatDate(frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE %>.value, '<%=dateFormat %>');
					if( expiryDate < currentDate){
						alert("<fmt:message key='msg.expire.date.can.not.be.less.than.equal.today' />");
						frm.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE %>.focus();
						return false;
					}
				}
			}
			frm.processingStep.value = "SAVE_PASSPORT_DETAILS";
			frm.btnSubmit.disabled = true;
			frm.submit();
		} else {
			frm.btnSubmit.disabled = false;
		}
	}
	function goToNextURL(frm) {

		if(confirm("<%=TextUtil.getLocalizedMessage(ExCode.CustEx.CONTINUE_WITHOUT_SAVE)%>")) {
			javascript:location.replace('domainOfService.jsp');
		} else {
			return false;
		}
	}
    function goToNextURLForeign(frm) {
        if(<%=mandatory%>)
        {
            frm.<%=PassportDetails.PROP_RESIDENT_NO%>.mandatory="yes";
            frm.<%=PassportDetails.PROP_RESIDENT_NO%>.display="<fmt:message key='resident.no' />";
        }
        if (validate(frm) == true) {
            javascript:location.replace('domainOfService.jsp');
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

	function showFields(isChanged){
		var selectedValue = document.caller.<%=PassportDetails.PROP_RESIDENTDOC%>.value;

		document.getElementById("residentnote_no").style.display = 'none';
		document.getElementById("investment_license_no").style.display = 'none';
		document.getElementById("investment_transaction_code").style.display = 'none';
		document.getElementById("identification_number").style.display = 'none';
		document.getElementById("identity_card_number").style.display = 'none';
		document.getElementById("expiry_date_passportdtl").style.display = 'none';
		document.getElementById("license_no_in_note").style.display = 'none';
		document.getElementById("visa_right_type").style.display = 'none';
		document.getElementById("resident_card_type").style.display = 'none';
		document.getElementById("license_expire_date").style.display = 'none';
		document.getElementById("enter_date_to_country").style.display = 'none';
		document.getElementById("visa_type").style.display = 'none';
		document.getElementById("passport_no").style.display = 'none';
		document.getElementById("resident-type").style.display = 'none';
		document.getElementById("visa_cancellation_country").style.display = 'none';

		document.getElementById("issue_date").style.display = 'none';
		document.caller.<%=PassportDetails.PROP_ISSUE_DATE%>.data = "date";
		document.caller.<%=PassportDetails.PROP_ISSUE_DATE%>.mandatory = "yes";
		document.caller.<%=PassportDetails.PROP_ISSUE_DATE%>.display = "<fmt:message key='issue.date' />";

		document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.display = '<fmt:message key="identity.card.number"/>';

		document.getElementById("expiry_date_passportdtl").style.display = 'none';
		document.caller.<%=PassportDetails.PROP_EXPIRY_DATE%>.data = "date";
		document.caller.<%=PassportDetails.PROP_EXPIRY_DATE%>.mandatory = "yes";
		document.caller.<%=PassportDetails.PROP_EXPIRY_DATE%>.display = "<fmt:message key='expiry.date.passportdtl' />";

		document.getElementById("enter_date_to_country").style.display = 'none';
		document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.mandatory = "no";
		document.getElementById("starDt").style.display  = "none";
		document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.display = "<fmt:message key='enter.date.to.country' />";
		document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.data = "nullabledate";

		document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.mandatory = "no";
		document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.display = "<fmt:message key='license.no.in.note' />";
		document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.data = "num";

		document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>.mandatory = "no";
		document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>.display = "<fmt:message key='note.no' />";
		document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>.data = "num";

		document.caller.<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>.mandatory = "no";
		document.caller.<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>.mandatory = "no";

		document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "no";
		document.getElementById("star").style.display = "none";
		document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.display = "<fmt:message key='license.expire.date'/>";
		document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "nullabledate";

		document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory = "no";
		document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.display = "<fmt:message key='passport.no' />";

		document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>.mandatory = "no";
		document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>.display = "<fmt:message key='investment.transaction.code'/>";

		if (isChanged){
			if (selectedValue != '02' && selectedValue !='03' && selectedValue != '04'){
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].mandatory = "no";
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].disabled = true;
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].value = '';

				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].mandatory = "no";
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].disabled = true;
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].value = '';

				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].disabled = true;
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].mandatory = "no";
				document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].value = '';
			}
		}
		if(selectedValue == '02' || selectedValue == '03' || selectedValue == '04'){ // دفترچه اقامت - دفترچه اقامت ویژه - دفترچه پناهندگی
			document.getElementById("residentnote_no").style.display = '';
			document.getElementById("issue_date").style.display = '';
			document.getElementById("expiry_date_passportdtl").style.display = '';
			document.getElementById("license_no_in_note").style.display = '';
			document.getElementById("license_expire_date").style.display = '';
			document.getElementById("enter_date_to_country").style.display = '';
			document.getElementById("expiry_date_passportdtl").style.display = '';

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].mandatory = "yes";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].disabled = false;
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].display = "<fmt:message key='note.no'/>";

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].mandatory = "no";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].disabled = true;

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].disabled = true;
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].mandatory = "no";

			document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.mandatory = "no";
			document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.display = "<fmt:message key='visa.type' />";

			if (selectedValue == '02'){
				document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "nullabledate";
				document.getElementById("star").style.display = "none";
			}else{
				document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "yes";
				document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "date";
				document.getElementById("star").style.display = "";
			}
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.value = ''; // شماره کارت آمایش ندارد
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.display = '<fmt:message key="identity.card.number"/>'; // شماره کارت آمایش ندارد
			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.value = ''; // شماره گذرنامه ندارد
		}else if(selectedValue == '01' || selectedValue == '06' || selectedValue == '07' || selectedValue == '08' || selectedValue == '10' || selectedValue == '11' ){
			//گذرنامه و پروانه اقامت سرمایه گذاری یا کار
			// گذرنامه با روادید عبور، ورود، جهانگردی، سیاسی، تحصیلی، خدمت، درمانی، زیارتی، مطبوعاتی
			// گذرنامه و کارت اقامت دیپلماتیک، کارت اقامت کنسولی یا کارت اقامت خدمت
			// گذرنامه مبتنی بر سیاست لغو روادید
			// گذرنامه با روادید از نوع خانواده، سرمایه گذاری، حق کار
			// گذرنامه با پروانه اقامت از نوع خانواده یا تحصیلی

			document.getElementById("license_no_in_note").style.display = '';
			document.getElementById("license_expire_date").style.display = '';
			document.getElementById("passport_no").style.display = '';
			document.getElementById("issue_date").style.display = '';
			document.getElementById("expiry_date_passportdtl").style.display = '';
			document.getElementById("enter_date_to_country").style.display = '';

			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory = "yes";

			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "yes";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "date";
			document.getElementById("star").style.display = "";


			if (selectedValue == '07'){
				document.getElementById("resident_card_type").style.display = '';
				document.caller.<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>.display = "<fmt:message key='resident.card.type'/>";
			}
			if (selectedValue == '10'){
				document.getElementById("visa_right_type").style.display = '';
				document.caller.<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>.display = "<fmt:message key='visa.right.type'/>";
			}
			if (selectedValue == '11'){
				document.getElementById("resident-type").style.display = '';
				document.caller.<%=PassportDetails.PROP_RESIDENT_TYPE%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_RESIDENT_TYPE%>.display = "<fmt:message key='resident.type'/>";
			}
			if (selectedValue == '06'){
				document.getElementById("visa_type").style.display = '';
				document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.display = "<fmt:message key='visa.type'/>";
			}
			if (selectedValue == '08'){
				document.getElementById("visa_cancellation_country").style.display = '';
				document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.mandatory = "no";
				document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.display = "<fmt:message key='visa.cancellation.country'/>";

				document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.mandatory = "yes";
				document.getElementById("starDt").style.display  = "";
			}
			if (selectedValue != '08'){
				document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.value = '';
				document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.mandatory = 'no';
			}
			if (selectedValue != '10'){
				document.caller.<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>.value = '';
				document.caller.<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>.mandatory = '';
			}
			if (selectedValue != '07'){
				document.caller.<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>.value = '';
				document.caller.<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>.mandatory = 'no';
			}
			if (selectedValue != '06'){
				document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.value = '';
				document.caller.<%=PassportDetails.PROP_VISA_TYPE%>.mandatory = "no";
			}
			if (selectedValue != '11'){
				document.caller.<%=PassportDetails.PROP_RESIDENT_TYPE%>.value = '';
				document.caller.<%=PassportDetails.PROP_RESIDENT_TYPE%>.mandatory = "no";
			}
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.value = '';
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.display = '<fmt:message key="identity.card.number"/>';
		}else if (selectedValue == '09'){ // مجوز سرمایه گذاری
			document.getElementById("investment_license_no").style.display = '';
			document.getElementById("investment_transaction_code").style.display = '';
			document.getElementById("issue_date").style.display = '';
			document.getElementById("expiry_date_passportdtl").style.display = '';


			document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>.mandatory = "yes";
			document.caller.<%=PassportDetails.PROP_TRANSACTION_CODE%>.display = "<fmt:message key='investment.transaction.code'/>";

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].mandatory = "no";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].disabled = true;

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].mandatory = "yes";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].disabled = false;
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].display = "<fmt:message key='investment.license.no'/>";

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].mandatory = "no";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].disabled = true;

			document.getElementById("enter_date_to_country").style.display = 'none'; // تاریخ ورود به کشور ندارد
			document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.value = ''; // تاریخ ورود به کشور ندارد
			document.caller.<%=PassportDetails.PROP_ENTER_DATE%>.mandatory = "no";
			document.getElementById("starDt").style.display  = "none";

			document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.value = ''; // شماره پروانه ندارد
			document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.mandatory = "no";

			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.value = ''; // تاریخ پروانه روادید ندارد
			document.getElementById("star").style.display = "none";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "no";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "nullabledate";

			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.value = ''; // شماره آمایش ندارد
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.mandatory = "no";
			document.caller.<%=PassportDetails.PROP_AMAYESH_CARD_NO%>.display = '<fmt:message key="identity.card.number"/>';

			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.value = ''; // شماره گذرنامه ندارد
			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory = "no";
			// کد معاملاتی
		}else if(selectedValue == '05'){ // مدرک آمایش
			document.getElementById("identification_number").style.display = '';
			document.getElementById("identity_card_number").style.display = '';
			document.getElementById("issue_date").style.display = '';
			document.getElementById("expiry_date_passportdtl").style.display = '';
			document.getElementById("enter_date_to_country").style.display = '';

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].mandatory = "no";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[0].disabled = true;

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].mandatory = "no";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[1].disabled = true;

			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].mandatory = "yes";
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].disabled = false;
			document.caller.<%=PassportDetails.PROP_DOCUMENT_NO%>[2].display = "<fmt:message key='identification.number'/>";

			document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.value = ''; // شماره پروانه ندارد
			document.caller.<%=PassportDetails.PROP_LICENSE_NO%>.mandatory = "no";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.value = ''; // تاریخ پروانه روادید ندارد
			document.getElementById("star").style.display = "none";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.mandatory = "no";
			document.caller.<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>.data = "nullabledate";
			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.value = ''; // شماره گذرنامه ندارد
			document.caller.<%=PassportDetails.PROP_PASSPORT_NO%>.mandatory = "no";
		}
	}
</script>

<%@ include file="../common/header.inc.jsp" %>
<table class="PageHeaderTable">
		<tr><th class="PageHeaderCell"><%=PAGE_TITLE%></th></tr>
	</table>
	<%@include file="customerDetail.inc.jsp"%>
<form name="caller" method="post">
	<%@include file="createCustomerTabs.inc.jsp"%>
	<%@include file="../common/displayMessages.inc.jsp"%>
<% if (processingStep == null   ) { %>
	<input type="hidden" name="<%=PassportDetails.PROP_CUSTOMER_ID%>" value="<%=passportDetails.getCustomerId()%>" />
	<table class="BodyTable">
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='resident.no'/></td>
			<td>
				<%--Modified by Yuwraj wrt Issue #2470 on 13 Nov 2013 for version 4.0.14 --%>
				<input type="text" name="<%=PassportDetails.PROP_RESIDENT_NO%>" value="<%=passportDetails.getResidentNo()!=null?passportDetails.getResidentNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %> maxlength="13" size='17' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='type.of.identification.document'/></td>
			<td>
				<select name="<%=PassportDetails.PROP_RESIDENTDOC%>" <%=!customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)?"disabled":""%> onchange="showFields(true)">
					<option value=""><fmt:message key="not.selected" /> </option>
					<%
						if (residentDocuments.length > 0) {
							String reasonCode = "";
							for (int i = 0; i < residentDocuments.length; i++) {
					%>
					<option value="<%=residentDocuments[i].getShortDesc()%>" <%=(residentDocuments[i].getShortDesc().equals(passportDetails.getResidentDoc()))?"selected='selected'":""%>>
						<%=TextUtil.getLocalizedLabel("passport." + residentDocuments[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
					</option>
					<%
							}
						}
					%>
				</select>

			</td>
		</tr>
		<tr class="BodyTableRow" id="passport_no" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='passport.no'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_PASSPORT_NO%>" value="<%=passportDetails.getPassportNo()!=null?passportDetails.getPassportNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>

		<%-- these fields are required --%>
		<tr class="BodyTableRow" id="residentnote_no" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='note.no'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_DOCUMENT_NO%>" value="<%=passportDetails.getDocumentNo()!=null?passportDetails.getDocumentNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" id="investment_license_no" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='investment.license.no'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_DOCUMENT_NO%>" value="<%=passportDetails.getDocumentNo()!=null?passportDetails.getDocumentNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" id="identification_number" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='identification.number'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_DOCUMENT_NO%>" value="<%=passportDetails.getDocumentNo()!=null?passportDetails.getDocumentNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" id="identity_card_number" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='identity.card.number'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_AMAYESH_CARD_NO%>" value="<%=passportDetails.getAmayeshCardNo()!=null?passportDetails.getAmayeshCardNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %> maxlength="15" size='18' class="FieldText" tabindex="<%=tabIdx++%>">
			</td>
		</tr>

		<tr class="BodyTableRow" id="issue_date" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='issue.date'/></td>
			<%-- Modified by Shagufta w.r.t. Issue #15497 on 28-Jan-2019 ver rel 7.0.6 --%>
			<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true && customer.getCustType().equals(Customer.CUSTOMER_TYPE_IND) == true){ %>
			<td>
				<dm:calendar dualCalendar = 'true' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_ISSUE_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getIssueDate()!=null?DateUtil.formatDate(passportDetails.getIssueDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}else{%>
			<td>
				<dm:calendar dualCalendar = 'false' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_ISSUE_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getIssueDate()!=null?DateUtil.formatDate(passportDetails.getIssueDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}%>
		</tr>

		<tr class="BodyTableRow" id="expiry_date_passportdtl" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='expiry.date.passportdtl'/></td>
			<%-- Modified by Shagufta w.r.t. Issue #15497 on 28-Jan-2019 ver rel 7.0.6 --%>
			<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true && customer.getCustType().equals(Customer.CUSTOMER_TYPE_IND) == true){ %>
			<td>
				<dm:calendar dualCalendar = 'true' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_EXPIRY_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getExpiryDate()!=null?DateUtil.formatDate(passportDetails.getExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}else{%>
			<td>
				<dm:calendar dualCalendar = 'false' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_EXPIRY_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getExpiryDate()!=null?DateUtil.formatDate(passportDetails.getExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}%>
		</tr>
		<tr class="BodyTableRow" id="investment_transaction_code" style="display: none">
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='investment.transaction.code'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_TRANSACTION_CODE%>" value="<%=passportDetails.getTransactionCode()!=null?passportDetails.getTransactionCode():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<%-- these fields are required --%>
		<%-- these fields are optional --%>
		<tr class="BodyTableRow" id="license_no_in_note" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='license.no.in.note'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_LICENSE_NO%>" value="<%=passportDetails.getLicenseNo()!=null?passportDetails.getLicenseNo():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>   maxlength="12" size='11' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" id="visa_cancellation_country" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='visa.cancellation.country'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>" maxlength="4" size='5' class="FieldText" value="<%=passportDetails.getVisaCancellationCountry()!=null?passportDetails.getVisaCancellationCountry():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>  tabindex="<%=tabIdx++%>"
					   onBlur="getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.value,'<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY+"Desc"%>');">
				<input type="button" class="FieldButton" value="..." <%= disableEditPassportInfo ? "disabled" : ""  %>  onclick="window.open('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_COUNTRY_MIS%>&fillcallback=countryCallBack&fillcallbackId=3', 'pop','<%=WIN_ATTRIBS%>');" onfocus="<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.focus();" tabindex="-1">
				<input type="text" class="FieldTextRO" name="<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY+"Desc"%>" size="50" readonly="readonly" tabindex="-1">
			</td>
		</tr>
		<tr class="BodyTableRow" id="resident-type" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='resident.type'/></td>
			<td>
				<select name="<%=PassportDetails.PROP_RESIDENT_TYPE%>" <%=!customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)?"disabled":""%>>
					<option value=""><fmt:message key="not.selected" /> </option>
					<%
						if (residentType.length > 0) {
							for (int i = 0; i < residentType.length; i++) {
					%>
					<option value="<%=residentType[i].getShortDesc()%>" <%=(residentType[i].getShortDesc().equals(passportDetails.getResidentType()))?"selected='selected'":""%>>
						<%=TextUtil.getLocalizedLabel(residentType[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
					</option>
					<%

							}
						}
					%>
				</select>
			</td>
		</tr>

		<tr class="BodyTableRow" id="visa_right_type" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='visa.right.type'/></td>
			<td>
				<select name="<%=PassportDetails.PROP_VISA_RIGHT_TYPE%>" <%=!customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)?"disabled":""%>>
					<option value=""><fmt:message key="not.selected" /> </option>
					<%
						if (visaRightTypes.length > 0) {
							for (int i = 0; i < visaRightTypes.length; i++) {
					%>
					<option value="<%=visaRightTypes[i].getShortDesc()%>" <%=(visaRightTypes[i].getShortDesc().equals(passportDetails.getVisaRightType()))?"selected='selected'":""%>>
						<%=TextUtil.getLocalizedLabel(visaRightTypes[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
					</option>
					<%

							}
						}
					%>
				</select>
			</td>
		</tr>
		<tr class="BodyTableRow" id="resident_card_type" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='resident.card.type'/></td>
			<td>
				<select name="<%=PassportDetails.PROP_RESIDENT_CARD_TYPE%>" <%=!customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)?"disabled":""%>>
					<option value=""><fmt:message key="not.selected" /> </option>
					<%
						if (residentCardTypes.length > 0) {
							String reasonCode = "";
							for (int i = 0; i < residentCardTypes.length; i++) {
								if (reasonCode.equals("")) {
									reasonCode = residentCardTypes[i].getReasonCode();
								} else if (!reasonCode.equals(residentCardTypes[i].getReasonCode())) {
									reasonCode = residentCardTypes[i].getReasonCode();
					%>
					<option style="font-size: 0pt;border: 1px inset black;" disabled>&nbsp;</option>
					<%
						}
					%>
					<option value="<%=residentCardTypes[i].getShortDesc()%>" <%=(residentCardTypes[i].getShortDesc().equals(passportDetails.getResidentCardType()))?"selected='selected'":""%>>
						<%=TextUtil.getLocalizedLabel(residentCardTypes[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>
					</option>
					<%

							}
						}
					%>
				</select>

			</td>
		</tr>
		<tr class="BodyTableRow" id="license_expire_date" style="display: none">
			<td class="FieldLabel" width="20%"><sup id="star" class='LegendText'>*</sup><fmt:message key='license.expire.date'/></td>
			<%-- Modified by Shagufta w.r.t. Issue #15497 on 28-Jan-2019 ver rel 7.0.6 --%>
			<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true && customer.getCustType().equals(Customer.CUSTOMER_TYPE_IND) == true){ %>
			<td>
				<dm:calendar dualCalendar = 'true' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getResidentryExpiryDate()!=null?DateUtil.formatDate(passportDetails.getResidentryExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}else{%>
			<td>
				<dm:calendar dualCalendar = 'false' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getResidentryExpiryDate()!=null?DateUtil.formatDate(passportDetails.getResidentryExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}%>
		</tr>
		<tr class="BodyTableRow" id="enter_date_to_country" style="display: none">
			<td class="FieldLabel" width="20%"><sup id="starDt" class='LegendText'>*</sup><fmt:message key='enter.date.to.country'/></td>
			<%-- Modified by Shagufta w.r.t. Issue #15497 on 28-Jan-2019 ver rel 7.0.6 --%>
			<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true && customer.getCustType().equals(Customer.CUSTOMER_TYPE_IND) == true){ %>
			<td>
				<dm:calendar dualCalendar = 'true' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_ENTER_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getEnterDate()!=null?DateUtil.formatDate(passportDetails.getEnterDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}else{%>
			<td>
				<dm:calendar dualCalendar = 'false' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_ENTER_DATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getEnterDate()!=null?DateUtil.formatDate(passportDetails.getEnterDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}%>
		</tr>
		<%-- these fields are optional --%>

		<tr class="BodyTableRow" id="visa_type" style="display: none">
			<td class="FieldLabel" width="20%"><fmt:message key='visa.type'/></td>
			<td>
				<select name="<%=PassportDetails.PROP_VISA_TYPE%>" <%=!customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN)?"disabled":""%>>
					<option value=""><fmt:message key="not.selected" /> </option>
					<%
						if (visaTypes.length > 0) {
							String reasonCode = "";
							for (int i = 0; i < visaTypes.length; i++) {
								if (reasonCode.equals("")) {
									reasonCode = visaTypes[i].getReasonCode();
								} else if (!reasonCode.equals(visaTypes[i].getReasonCode())) {
									reasonCode = visaTypes[i].getReasonCode();
					%>
					<option style="font-size: 0pt;border: 1px inset black;" disabled>&nbsp;</option>
					<%
						}
					%>
					<option value="<%=visaTypes[i].getShortDesc()%>" <%=(visaTypes[i].getShortDesc().equals(passportDetails.getVisaType()))?"selected='selected'":""%>>
						<%=TextUtil.getLocalizedLabel(visaTypes[i].getLongDesc(),USER_SESSION.getCommonSess().getLocale()) %>

					</option>
					<%

							}
						}
					%>
				</select>

			</td>
		</tr>
		<%boolean show = !CommonUtils.IsNullOrEmpty(passportDetails.getIssuedBy()) && !CommonUtils.IsNullOrEmpty(passportDetails.getIssuedPlace())
				&& !CommonUtils.IsNullOrEmpty(passportDetails.getBornCountry()) && !CommonUtils.IsNullOrEmpty(passportDetails.getBornCity())
				&& !CommonUtils.IsNullOrEmpty(passportDetails.getResidentDocFromCountry());%>
		<%if (txnType == IConstants.MODIFY && show){%>
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='issued.by'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_ISSUED_BY%>" maxlength="45" size='46' class="FieldText" value="<%=passportDetails.getIssuedBy()!=null?passportDetails.getIssuedBy():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>  tabindex="<%=tabIdx++%>">
			</td>
		</tr>

		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='issued.place'/></td>
			<%--onBlur Added by AmolB wrt bug #462 Ver.4.0.4 on 22 July 2013 --%>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_ISSUED_PLACE%>" maxlength="4" size='5' class="FieldText" value="<%=passportDetails.getIssuedPlace()!=null?passportDetails.getIssuedPlace():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>  tabindex="<%=tabIdx++%>"
							onBlur="getDescription(document.caller,'IssuePlaceCode',document.caller.<%=PassportDetails.PROP_ISSUED_PLACE%>.value,'<%=PassportDetails.PROP_ISSUED_PLACE+"Desc"%>');">
				<%--Added by Rushikesh w.r.t. Issue#11583 on 20-May-2015 for Rel Ver 5.4.2.--%>
				<input type="button" class="FieldButton" value="..." <%= disableEditPassportInfo ? "disabled" : ""  %>  onclick="window.open('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_PLACE_CODE%>', 'pop','<%=WIN_ATTRIBS%>');" onfocus="<%=PassportDetails.PROP_ISSUED_PLACE%>.focus();" tabindex="-1">
				<input type="text" class="FieldTextRO" name="<%=PassportDetails.PROP_ISSUED_PLACE+"Desc"%>" size="50" readonly="readonly" tabindex="-1">
			</td>
		</tr>
		<%-- Modified by mostafa Issue #15867 on 4/18/2019 ver rel 7.0.18 --%>
<%--		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='residentry.expiry.date'/></td>
			<%if(customer.getCustCategory().equals(Customer.CUSTOMER_CATEGORY_FOREIGN) == true && customer.getCustType().equals(Customer.CUSTOMER_TYPE_IND) == true){ %>
			<td>
				<dm:calendar dualCalendar = 'true' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getResidentryExpiryDate()!=null?DateUtil.formatDate(passportDetails.getResidentryExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}else{%>
			<td>
				<dm:calendar dualCalendar = 'false' dateFormat="<%=dateFormat%>" name="<%=PassportDetails.PROP_RESIDENTRY_EXPIRYDATE%>" currentDate="<%= DateUtil.formatDate(currDate,dateFormat) %>" selectedDate="<%=passportDetails.getResidentryExpiryDate()!=null?DateUtil.formatDate(passportDetails.getResidentryExpiryDate(),dateFormat):""%>" readOnly="<%=disableEditPassportInfo%>" tabIndex="<%=new Integer(tabIdx++).toString()%>" />
			</td>
			<%}%>
		</tr>--%>
		<%}%>
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><sup class='LegendText'>*</sup><fmt:message key='birth.country'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_BORN_COUNTRY%>" maxlength="4" size='5' class="FieldText" value="<%=passportDetails.getBornCountry()!=null?passportDetails.getBornCountry():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %>  tabindex="<%=tabIdx++%>"
					   onBlur="getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_BORN_COUNTRY%>.value,'<%=PassportDetails.PROP_BORN_COUNTRY+"Desc"%>');">
				<input type="button" class="FieldButton" value="..." <%= disableEditPassportInfo ? "disabled" : ""  %>  onclick="window.open('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_COUNTRY_MIS%>&fillcallback=countryCallBack&fillcallbackId=1', 'pop','<%=WIN_ATTRIBS%>');" onfocus="<%=PassportDetails.PROP_BORN_COUNTRY%>.focus();" tabindex="-1">
				<input type="text" class="FieldTextRO" name="<%=PassportDetails.PROP_BORN_COUNTRY+"Desc"%>" size="50" readonly="readonly" tabindex="-1">
			</td>
		</tr>
		<%if (txnType == IConstants.MODIFY && show){%>
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='birth.city'/></td>
			<td>
				<input type="text" onkeydown="return alphaOnly(event)"  name="<%=PassportDetails.PROP_BORN_CITY%>" value="<%=passportDetails.getBornCity()!=null?passportDetails.getBornCity():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %> maxlength="120" size='25' class="FieldText"  tabindex="<%=tabIdx++%>">
			</td>
		</tr>
		<tr class="BodyTableRow" >
			<td class="FieldLabel" width="20%"><fmt:message key='resident.document.country'/></td>
			<td>
				<input type="text" name="<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>" maxlength="4" size='5' class="FieldText" value="<%=passportDetails.getResidentDocFromCountry()!=null?passportDetails.getResidentDocFromCountry():""%>" <%= disableEditPassportInfo ? "disabled" : ""  %> tabindex="<%=tabIdx++%>"
					   onBlur="getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.value,'<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY+"Desc"%>');">
				<input type="button" class="FieldButton" value="..." <%= disableEditPassportInfo ? "disabled" : ""  %>  onclick="window.open('../common/popGeneric.jsp?popType=<%=PopBiz.POP_TYPE_COUNTRY_MIS%>&fillcallback=countryCallBack&fillcallbackId=2', 'pop','<%=WIN_ATTRIBS%>');" onfocus="<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.focus();" tabindex="-1">
				<input type="text" class="FieldTextRO" name="<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY+"Desc"%>" size="50" readonly="readonly" tabindex="-1">
			</td>
		</tr>
		<%}%>
	<%-- Following Reset button functionality has been changed by Bayanna wrt #bug 392 on 26 July 2013 Rel Ver 4.0.4 --%>
		<tr class="BodyTableRow">
			<td align="center" colspan="2" align="center">
				<input type="button" value="<fmt:message key='save'/>" class="FieldButton" name="btnSubmit" onClick= "return validation(document.caller)" tabindex="<%=tabIdx++%>" >
				<input type="reset" value="<fmt:message key= 'reset'/>" class="FieldButton" name="btnReset" tabindex="<%=tabIdx++%>">
                <% if (mandatory){ %>
                <input type="button" value="<fmt:message key='next'/>" class="FieldButton" name="btnNext" onClick= "return goToNextURLForeign(document.caller)" tabindex="<%=tabIdx++%>" >
                <% } else {%>
				<input type="button" value="<fmt:message key='next'/>" class="FieldButton" name="btnNext" onClick= "return goToNextURL(document.caller)" tabindex="<%=tabIdx++%>" >
			    <%}%>
            </td>
		</tr>
	</table>
<% } %>
	<input type="hidden" name="processingStep">
	<script>

		getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_BORN_COUNTRY%>.value,'<%=PassportDetails.PROP_BORN_COUNTRY+"Desc"%>');
		//setTimeout(function(){
		//	getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY%>.value,'<%=PassportDetails.PROP_RESIDENTDOC_FROM_COUNTRY+"Desc"%>');
		//},1000);
		setTimeout(function(){
			getDescription(document.caller,'countryBornCode',document.caller.<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY%>.value,'<%=PassportDetails.PROP_VISA_CANCELLATION_COUNTRY+"Desc"%>');
		},1000);
		showFields(false);
	</script>
</form>
<%@ include file="../common/footer.inc.jsp"%>
