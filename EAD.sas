libname d 'YOUR PATH';

data mortgage;
set d.mortgage2;
run;
/******************************************************Data preparation ********************************************************/

proc sort data=mortgage; by id; run;

data mortgage(drop=i count);
	set mortgage;
	by id;
	/* create lagged variables */
	array x(*) lag1-lag4;
	lag1=lag1(balance_time);
	lag2=lag2(balance_time);
	lag3=lag3(balance_time);
	lag4=lag4(balance_time);

	/* reset count at the start of each new by-group */
	if first.id then count=1;

	/* assign missing values to first observation of a by-group */
	do i=count to dim(x);
		x(i)=.;
	end;
	count+1;
run;

/*****************************************************************************************************************************/
/*1 period prior to the event of default*/

data mortgage1(where=(drawn ne . and limit ne . and exposure ne . and exposure ne 0));
	set mortgage;

	/*Definitions*/
	drawn=lag1;
	limit=balance_orig_time;
	exposure=balance_time;

	/*Caps for exposure and draw*/
	if exposure>limit then exposure=limit;
	if drawn>limit then drawn=limit;

	/*Conversion measures*/
	if drawn=limit then CCF=0;
	else CCF=(exposure-drawn)/(limit-drawn);
	
	if limit=0 then CEQ=0;
	else CEQ=(exposure-drawn)/limit;

	if limit=0 then LCF=0;
	else LCF=exposure/limit;

	if drawn=0 then UACF=0;
	else UACF=exposure/drawn;
run;

proc means  p1 p50 p99;
	var CCF CEQ LCF UACF;
run;

data mortgage2;
	set mortgage1;

	/* Floors*/
	if CCF<=-2.0375447 then CCF=-2.0375447;
	if CEQ<=-0.0236966 then CEQ=-0.0236966;
	if LCF<=0.4036357 then LCF=0.4036357;
	if UACF<=0.9487103 then UACF=0.9487103;

	/*Caps*/
	if CCF>=0 then CCF=0;
	if CEQ>=0 then CEQ=0;
	if LCF>=0.9999999 then LCF=0.9999999;
	if UACF>=1 then UACF=1;

	/*Transformations */
	CCF_t=-log(1-CCF);
	CEQ_t=log((1+CEQ)/(1-CEQ));
	LCF_t=log(LCF/(1-LCF));
	UACF_t=log(UACF);

run;

proc means data=mortgage2(where=(default_time=1));
	var CCF CEQ LCF UACF CCF_t CEQ_t LCF_t UACF_t;
run; 

/*find time to maturity*/
data mortgage2;
	set mortgage2;
	time_to_maturity= mat_time -time;
run;

/* Creates training and testing samples */

proc surveyselect data=mortgage2 samprate=0.8 outall seed=12345 out=mortgage3;
samplingunit id;
run;

/*train*/
data train_1period;
set mortgage3;
where selected=1;
run;
/*test*/
data test_1period;
set mortgage3;
where selected=0;
run;

/*****************************************************************************************************************************/
/*2 period prior to the event of default*/

data mortgage1(where=(drawn ne . and limit ne . and exposure ne . and exposure ne 0));
	set mortgage;

	/*Definitions*/
	drawn=lag2;
	limit=balance_orig_time;
	exposure=balance_time;

	/*Caps for exposure and draw*/
	if exposure>limit then exposure=limit;
	if drawn>limit then drawn=limit;

	/*Conversion measures*/
	if drawn=limit then CCF=0;
	else CCF=(exposure-drawn)/(limit-drawn);
	
	if limit=0 then CEQ=0;
	else CEQ=(exposure-drawn)/limit;

	if limit=0 then LCF=0;
	else LCF=exposure/limit;

	if drawn=0 then UACF=0;
	else UACF=exposure/drawn;
run;

proc means  p1 p99;
	var CCF CEQ LCF UACF;
run;

data mortgage2;
	set mortgage1;

	/* Floors*/
	if CCF<=-5.6048293 then CCF=-5.6048293;
	if CEQ<=-0.0520319 then CEQ=-0.0520319;
	if LCF<=0.3935552 then LCF=0.3935552;
	if UACF<=0.8834769 then UACF=0.8834769;

	/*Caps*/
	if CCF>=0.3523449 then CCF=0.3523449;
	if CEQ>=0.0016596 then CEQ=0.0016596;
	if LCF>=0.9999999 then LCF=0.9999999;
	if UACF>=1.0016738 then UACF=1.0016738;

	/*Transformations */
	CCF_t=-log(1-CCF);
	CEQ_t=log((1+CEQ)/(1-CEQ));
	LCF_t=log(LCF/(1-LCF));
	UACF_t=log(UACF);

run;

proc means data=mortgage2(where=(default_time=1));
	var CCF CEQ LCF UACF CCF_t CEQ_t LCF_t UACF_t;
run; 

/*find time to maturity*/
data mortgage2;
	set mortgage2;
	time_to_maturity= mat_time -time;
run;

/* Creates training and testing samples */

proc surveyselect data=mortgage2 samprate=0.8 outall seed=12345 out=mortgage3;
samplingunit id;
run;

/*train*/
data train_2period;
set mortgage3;
where selected=1;
run;
/*test*/
data test_2period;
set mortgage3;
where selected=0;
run;

/*************************************************************************************************************************/
/*3 period prior to the event of default*/

data mortgage1(where=(drawn ne . and limit ne . and exposure ne . and exposure ne 0));
	set mortgage;

	/*Definitions*/
	drawn=lag3;
	limit=balance_orig_time;
	exposure=balance_time;

	/*Caps for exposure and draw*/
	if exposure>limit then exposure=limit;
	if drawn>limit then drawn=limit;

	/*Conversion measures*/
	if drawn=limit then CCF=0;
	else CCF=(exposure-drawn)/(limit-drawn);
	
	if limit=0 then CEQ=0;
	else CEQ=(exposure-drawn)/limit;

	if limit=0 then LCF=0;
	else LCF=exposure/limit;

	if drawn=0 then UACF=0;
	else UACF=exposure/drawn;
run;

proc means  p1 p99;
	var CCF CEQ LCF UACF;
run;

data mortgage2;
	set mortgage1;

	/* Floors*/
	if CCF<=-9.3146552 then CCF=-9.3146552;
	if CEQ<=-0.0877468 then CEQ=-0.0877468;
	if LCF<=0.3836919 then LCF=0.3836919;
	if UACF<=0.8143665 then UACF=0.8143665;

	/*Caps*/
	if CCF>=0.9999999 then CCF=0.9999999;
	if CEQ>=0.0069572 then CEQ=0.0069572;
	if LCF>=0.9999999 then LCF=0.9999999;
	if UACF>=1.0070687 then UACF=1.0070687;

	/*Transformations */
	CCF_t=-log(1-CCF);
	CEQ_t=log((1+CEQ)/(1-CEQ));
	LCF_t=log(LCF/(1-LCF));
	UACF_t=log(UACF);

run;

proc means data=mortgage2(where=(default_time=1));
	var CCF CEQ LCF UACF CCF_t CEQ_t LCF_t UACF_t;
run; 

/*find time to maturity*/
data mortgage2;
	set mortgage2;
	time_to_maturity= mat_time -time;
run;

/* Creates training and testing samples */

proc surveyselect data=mortgage2 samprate=0.8 outall seed=12345 out=mortgage3;
samplingunit id;
run;

/*train*/
data train_3period;
set mortgage3;
where selected=1;
run;
/*test*/
data test_3period;
set mortgage3;
where selected=0;
run;

/********************************************************************************************************************************/
/*4 period prior to the event of default*/

data mortgage1(where=(drawn ne . and limit ne . and exposure ne . and exposure ne 0));
	set mortgage;

	/*Definitions*/
	drawn=lag4;
	limit=balance_orig_time;
	exposure=balance_time;

	/*Caps for exposure and draw*/
	if exposure>limit then exposure=limit;
	if drawn>limit then drawn=limit;

	/*Conversion measures*/
	if drawn=limit then CCF=0;
	else CCF=(exposure-drawn)/(limit-drawn);
	
	if limit=0 then CEQ=0;
	else CEQ=(exposure-drawn)/limit;

	if limit=0 then LCF=0;
	else LCF=exposure/limit;

	if drawn=0 then UACF=0;
	else UACF=exposure/drawn;
run;

proc means  p1 p99;
	var CCF CEQ LCF UACF;
run;

data mortgage2;
	set mortgage1;

	/* Floors*/
	if CCF<=-14.5106798 then CCF=-14.5106798;
	if CEQ<=-0.1291147 then CEQ=-0.1291147;
	if LCF<=0.3726841 then LCF=0.3726841;
	if UACF<=0.7500004 then UACF=0.7500004;

	/*Caps*/
	if CCF>=0.9999999 then CCF=0.9999999;
	if CEQ>=0.0102815 then CEQ=0.0102815;
	if LCF>=0.9999999 then LCF=0.9999999;
	if UACF>=1.0105158 then UACF=1.0105158;

	/*Transformations */
	CCF_t=-log(1-CCF);
	CEQ_t=log((1+CEQ)/(1-CEQ));
	LCF_t=log(LCF/(1-LCF));
	UACF_t=log(UACF);

run;

proc means data=mortgage2(where=(default_time=1));
	var CCF CEQ LCF UACF CCF_t CEQ_t LCF_t UACF_t;
run; 

/*find time to maturity*/
data mortgage2;
	set mortgage2;
	time_to_maturity= mat_time -time;
run;

/* Creates training and testing samples */

proc surveyselect data=mortgage2 samprate=0.8 outall seed=12345 out=mortgage3;
samplingunit id;
run;

/*train*/
data train_4period;
set mortgage3;
where selected=1;
run;
/*test*/
data test_4period;
set mortgage3;
where selected=0;
run;




/**************************************** TRAINING ********************************************************************/
/*Linear regression*/
%macro linear_reg(mytrain , myy);
	/* linear regression model */
	proc reg  data=&mytrain(where=(default_time=1))plots(maxpoints=20000 stats=all)=diagnostics;
	model &myy = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3 time_to_maturity/
	selection=stepwise slentry=0.05 slstay=0.01;
	store out=model_linear_&myy;
	run;
%mend;

%linear_reg(mytrain=train_1period , myy=CCF ); 
%linear_reg(mytrain=train_2period , myy=CCF );	
%linear_reg(mytrain=train_3period , myy=CCF ); 
%linear_reg(mytrain=train_4period , myy=CCF ); 
%linear_reg(mytrain=train_1period , myy=CEQ ); 
%linear_reg(mytrain=train_2period , myy=CEQ ); 
%linear_reg(mytrain=train_3period , myy=CEQ ); 
%linear_reg(mytrain=train_4period , myy=CEQ );
%linear_reg(mytrain=train_1period , myy=LCF );
%linear_reg(mytrain=train_2period , myy=LCF );
%linear_reg(mytrain=train_3period , myy=LCF );
%linear_reg(mytrain=train_4period , myy=LCF );
%linear_reg(mytrain=train_1period , myy=UACF );
%linear_reg(mytrain=train_2period , myy=UACF );
%linear_reg(mytrain=train_3period , myy=UACF );
%linear_reg(mytrain=train_4period , myy=UACF );
%linear_reg(mytrain=train_1period , myy=CCF_t);
%linear_reg(mytrain=train_2period , myy=CCF_t );
%linear_reg(mytrain=train_3period , myy=CCF_t );
%linear_reg(mytrain=train_4period , myy=CCF_t );
%linear_reg(mytrain=train_1period , myy=CEQ_t );
%linear_reg(mytrain=train_2period , myy=CEQ_t );
%linear_reg(mytrain=train_3period , myy=CEQ_t );
%linear_reg(mytrain=train_4period , myy=CEQ_t );
%linear_reg(mytrain=train_1period , myy=LCF_t );
%linear_reg(mytrain=train_2period , myy=LCF_t );
%linear_reg(mytrain=train_3period , myy=LCF_t );
%linear_reg(mytrain=train_4period , myy=LCF_t );
%linear_reg(mytrain=train_1period , myy=UACF_t );
%linear_reg(mytrain=train_2period , myy=UACF_t );
%linear_reg(mytrain=train_3period , myy=UACF_t );
%linear_reg(mytrain=train_4period , myy=UACF_t);


/*Tobit regression  */
%macro tobit_reg(mytrain , myy);
	proc qlim data=&mytrain;
	model &myy=mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3 time_to_maturity;
	endogenous &myy~censored(lb=0.00001);
	output out= model_tobit_&myy expected conditional prob residual xbeta;
	run;
%mend;

%tobit_reg(mytrain=train_1period , myy=CCF ); 
%tobit_reg(mytrain=train_2period , myy=CCF );	
%tobit_reg(mytrain=train_3period , myy=CCF ); 
%tobit_reg(mytrain=train_4period , myy=CCF ); 
%tobit_regg(mytrain=train_1period , myy=CEQ); 
%tobit_reg(mytrain=train_2period , myy=CEQ); 
%tobit_reg(mytrain=train_3period , myy=CEQ ); 
%tobit_reg(mytrain=train_4period , myy=CEQ);
%tobit_reg(mytrain=train_1period , myy=LCF);
%tobit_reg(mytrain=train_2period , myy=LCF);
%tobit_reg(mytrain=train_3period , myy=LCF );
%tobit_reg(mytrain=train_4period , myy=LCF);
%tobit_reg(mytrain=train_1period , myy=UACF);
%tobit_reg(mytrain=train_2period , myy=UACF);
%tobit_reg(mytrain=train_3period , myy=UACF);
%tobit_reg(mytrain=train_4period , myy=UACF);
%tobit_reg(mytrain=train_1period , myy=CCF_t);
%tobit_reg(mytrain=train_2period , myy=CCF_t);
%tobit_reg(mytrain=train_3period , myy=CCF_t);
%tobit_reg(mytrain=train_4period , myy=CCF_t);
%tobit_reg(mytrain=train_1period , myy=CEQ_t);
%tobit_reg(mytrain=train_2period , myy=CEQ_t);
%tobit_reg(mytrain=train_3period , myy=CEQ_t);
%tobit_reg(mytrain=train_4period , myy=CEQ_t);
%tobit_reg(mytrain=train_1period , myy=LCF_t);
%tobit_reg(mytrain=train_2period , myy=LCF_t);
%tobit_reg(mytrain=train_3period , myy=LCF_t);
%tobit_reg(mytrain=train_4period , myy=LCF_t);
%tobit_reg(mytrain=train_1period , myy=UACF_t);
%tobit_reg(mytrain=train_2period , myy=UACF_t);
%tobit_reg(mytrain=train_3period , myy=UACF_t);
%tobit_reg(mytrain=train_4period , myy=UACF_t);


/*** VALIDATION ***/
%macro valid_linear(mytest , myy  );
	proc plm source=model_linear_&myy;
		score data=&mytest out=test_linear_&myy;
	run;
	data test_linear_&myy;
	set test_linear_&myy;
	sqerror=(predicted-&myy)**2;
	run;
	proc means data=test_linear_&myy;
	var predicted &myy sqerror;
	run;
%mend ;


%valid_linear(mytest=test_4period , myy=LCF );

proc sort data=testlinear_CCF;
by time;
run;

proc means data=testlinear_CCF;
by time;
output out=meanslinear_CCF mean(CCF predicted)=CCF predicted;
run;

proc sort data=meanslinear_CCF; by time; run;


ods graphics on;
axis1 order=(0 to 60 by 5) label=('time');
axis2 order=(0 to 0.06 by 0.01) label=('predcited');
symbol1 interpol=spline width=2 value=triangle c=blue;
symbol2 interpol=spline width=2 value=circle c=red;
symbol3 interpol=spline width=2 value=square c=black;
symbol4 interpol=spline width=2 value= star c=green;
symbol5 interpol=spline width=2 value=oval c=yellow;

legend1 label=none shape=symbol(4,2) position=(bottom outside);

proc gplot data=meanslinear_CCF;
plot (CCF predicted1)*time/overlay haxis=axis1 vaxis=axis2 legend=legend1;
run;
ods graphics off;


/* Validation Tobit model */
data validation_set;
set mortgage3;
Actual = LCF;
if Selected = 0 then LCF = .;
run;



proc qlim data=validation_set;
model LCF=mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3 time_to_maturity;
endogenous LCF~censored(lb=0.00001);
output out= model_tobit_LCF_1myperiod expected conditional prob residual xbeta predicted;
run;

data tobit_valid;
set model_tobit_LCF_1myperiod;
where (selected = 0);
sqerror = (Actual-P_LCF)**2;
run;

ods rtf;
proc means data=tobit_valid;
var P_LCF Actual sqerror;
run;
ods rtf close;

/* Use for the complete data for linear */

proc reg data=mortgage3(where=(default_time=1))plots(maxpoints=20000 stats=all)=diagnostics;
model LCF = mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3 time_to_maturity/
selection=stepwise slentry=0.05 slstay=0.01;
store out=model_linear_LCF_best;
run;

proc plm source=model_linear_LCF_best;
	score data=mortgage3 out=for_by_time;
run;

proc means data=for_by_time;
var predicted LCF;
run;

proc sort data=for_by_time;
by time;
run;

proc means data=for_by_time;
by time;
output out=meansLCF_bytime mean(LCF predicted)=LCF predicted;
run;

libname out 'YOUR PATH';
data out.meansLCF_bytime;
	set meansLCF_bytime;
run;

/* Use for the complete data for Tobit*/
proc qlim data=mortgage3;
model LCF=mat_time balance_time LTV_time interest_rate_time hpi_time gdp_time uer_time REtype_CO_orig_time REtype_PU_orig_time REtype_SF_orig_time investor_orig_time FICO_orig_time LTV_orig_time Interest_Rate_orig_time hpi_orig_time spx_index spx_index_lag1 spx_index_lag2 spx_index_lag3 vix_index vix_index_lag1 vix_index_lag2 vix_index_lag3 cpi_index cpi_index_lag1 cpi_index_lag2 cpi_index_lag3 fed_funds_rate fed_funds_rate_lag1 fed_funds_rate_lag2 fed_funds_rate_lag3 ism ism_lag1 ism_lag2 ism_lag3 cpr cpr_lag1 cpr_lag2 cpr_lag3 time_to_maturity;
endogenous LCF~censored(lb=0.00001);
output out= model_tobit_LCF_complete expected conditional prob residual xbeta predicted;
run;

ods rtf;
proc means data=model_tobit_LCF_complete;
var P_LCF LCF;
run;
ods rtf close;

proc sort data=model_tobit_LCF_complete;
by time;
run;

proc means data=model_tobit_LCF_complete;
by time;
output out=meansLCF_bytime mean(LCF P_LCF)=LCF P_LCF;
run;

** plot the LCF by time;
ods graphics on;
axis1 order=(0 to 60 by 5) label=('time');
axis2 order=(0.75 to 1 by 0.05) label=('LCF and Predicted_LCF');
symbol1 interpol=spline width=2 value=triangle c=blue;
symbol2 interpol=spline width=2 value=circle c=red;

legend1 label='Plot of LCF and predicted LCF' shape=symbol(4,2) position=(top);

proc gplot data=meansLCF_bytime;
plot (LCF P_LCF)*time/overlay haxis=axis1 vaxis=axis2 legend=legend1;
run;
ods graphics off;




